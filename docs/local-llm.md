# Local LLM inference (framework-13)

Ollama (Vulkan backend) and Open WebUI, running on demand — neither starts at
boot. See `modules/local-llm.nix` (framework-13 only; the Dell XPS is too old
for this).

## Start / stop

```bash
sudo systemctl start ollama
sudo systemctl start open-webui   # optional — only if you want the chat UI
```

```bash
sudo systemctl stop open-webui
sudo systemctl stop ollama
```

Check status / logs:

```bash
systemctl status ollama
journalctl -u ollama -f
```

Ollama's API listens on `127.0.0.1:11434`; Open WebUI on `127.0.0.1:8080`.
Both are localhost-only — nothing here is reachable from the network.

## GPU acceleration

`services.ollama.environmentVariables.OLLAMA_IGPU_ENABLE = "1"` is required —
Ollama 0.34.2 drops integrated GPUs by default. Confirm it's actually using
the GPU (not falling back to CPU) via:

```bash
journalctl -u ollama -n 30 | grep -i vulkan
```

Look for `type=iGPU` and a real VRAM total (`total="48.5 GiB"`), not a `cpu`
compute entry. If you see `"dropping integrated GPU; to enable, set
OLLAMA_IGPU_ENABLE=1"`, the env var isn't taking effect — check the service
picked up the latest generation (`sudo systemctl restart ollama` after
`nixos-rebuild switch`).

GPU-usable GTT memory is raised to 48 GiB via kernel params
(`ttm.pages_limit` / `ttm.page_pool_size`) — this needs a **reboot** to take
effect after changing it, unlike the rest of this module. Verify:

```bash
cat /sys/module/ttm/parameters/pages_limit   # expect 12582912 (48 GiB / 4 KiB pages)
cat /sys/class/drm/card1/device/mem_info_gtt_total   # expect 51539607552 (48 GiB)
```

## Pulling models

```bash
ollama pull qwen3-coder:30b
ollama pull granite4:small-h
ollama pull granite4:tiny-h
ollama list
```

`qwen3-coder:30b` (Qwen3-Coder-30B-A3B, ~18 GB at Q4, ~3B active params per
token) is the reference model for this hardware — check
[ollama.com/library](https://ollama.com/library) for anything newer in the
same MoE/~3-5B-active class before assuming it's still the best option.

The two Granite 4.0 hybrid (Mamba/transformer) MoE models are configured
alongside it for comparison (issue #58): `granite4:small-h` (32B total, ~9B
active) and `granite4:tiny-h` (7B total, ~1B active). Models are pulled by
hand, not declaratively — the opencode config below only lists them.

## Using it

**Open WebUI**: start the service, open `http://127.0.0.1:8080`, create an
account on first visit (local-only, no external auth), pick the model from
the chat picker.

**opencode**: the local provider is already configured — `modules/local-llm.nix`
sets `OPENCODE_CONFIG` to a generated JSON file with an `ollama` provider
pointing at `http://127.0.0.1:11434/v1` (via `@ai-sdk/openai-compatible`).
This is deliberately *not* done through `programs.opencode.settings`, which
would make home-manager own `~/.config/opencode/opencode.json` as a
read-only store symlink — `OPENCODE_CONFIG` merges in as an extra layer
instead, leaving opencode's own config file alone.

```bash
opencode run --model ollama/qwen3-coder:30b "your prompt"
```

or select `Ollama (local)` / `qwen3-coder:30b` from opencode's `/models` menu
in an interactive session.

**After changing the model list**, opencode won't see it in an existing
login session: NixOS sources `/etc/set-environment` once per login and sets
`__NIXOS_SET_ENVIRONMENT_DONE=1`, so new terminals inherit the old
`OPENCODE_CONFIG` store path. Either log out and back in, or:

```bash
source /etc/set-environment
```

**Known quirk**: tool-calling works (verified directly against Ollama's
`/v1/chat/completions` endpoint — it returns proper structured `tool_calls`),
but opencode's full multi-tool schema occasionally causes this model to emit
a tool call as literal text instead of actually invoking it, rather than
failing outright. Observed roughly 1 in 3 attempts in testing. If a task
seems to "describe" an action instead of doing it, re-running the same
prompt usually works.

## Measured performance

Comparison across all three models, same `/api/generate` prompt with
`num_predict: 756`, all layers offloaded to the GPU (Vulkan):

| Model | Active params | Generation | Cold load |
|---|---|---|---|
| `qwen3-coder:30b` | ~3B | ~31.9 tok/s | ~9.8s |
| `granite4:small-h` | ~9B | ~11.9 tok/s | ~4.2s |
| `granite4:tiny-h` | ~1B | ~50.6 tok/s | ~1.7s |

Generation speed tracks active params per token, since memory bandwidth is
the bottleneck — except `tiny-h`, where per-token fixed overhead dominates
and it's only ~1.6x faster than Qwen rather than ~3x. (`tiny-h` stopped
early at 435 tokens; tok/s is still comparable.)

`qwen3-coder:30b`, direct API test (`/api/generate`, 22-token prompt,
756-token response), post-warm-up:

- **~31.9 tok/s** generation
- ~9.8s model load time (first request after service start/restart)
- Falls within the ~20-35 tok/s estimate from the original hardware
  measurements (12C/24T Ryzen AI 9 HX 370, Radeon 890M/gfx1150,
  ~120 GB/s LPDDR5X — bandwidth is the limiting factor for this MoE model).
