# 0011. Run local inference on the Vulkan backend rather than ROCm

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-09-22
- **Recorded:** 2026-10-16
- **Discussion:** [#39](https://github.com/huwd/declarative_laptop/issues/39), [#47](https://github.com/huwd/declarative_laptop/pull/47), [#71](https://github.com/huwd/declarative_laptop/issues/71)

## Summary

Ollama runs language models on the Framework's integrated AMD GPU through either the Vulkan or the ROCm backend.
The configuration uses Vulkan because it works, and because ROCm brings a much larger software stack.
ROCm was not built or tested on this machine, so the choice rests on that trade-off and not on a comparison.
Either backend is open source, so licensing doesn't decide it.
The choice is open to challenge, and a measured trial of ROCm would be the strongest reason to revise it.

## Context

The `framework-13` host has an AMD Ryzen AI 9 HX 370 with a Radeon 890M integrated GPU.
The GPU is RDNA 3.5, identified as `gfx1150`, and shares system memory instead of having dedicated video memory.
Memory bandwidth is the main limit on generation speed, so the backend is unlikely to change generation speed much.

[#39](https://github.com/huwd/declarative_laptop/issues/39) set out to run models such as Qwen3-Coder offline, started on demand, from opencode and a browser interface.
It chose the backend at the start, as one of its agreed decisions, before any implementation.
It judged ROCm support for `gfx1150` to be partial, and excluded the processor's neural processing unit (XDNA 2) because the Linux support was immature.

## Options considered

### Vulkan (chosen)

Nixpkgs provides `ollama-vulkan`, and Ollama's Vulkan backend works with the integrated GPU.
[#47](https://github.com/huwd/declarative_laptop/pull/47) confirmed on the hardware that Ollama selected the integrated GPU and offloaded all layers.
`qwen3-coder:30b` generated about 31.9 tokens a second, inside the 20 to 35 tokens a second estimated before implementation.
[`docs/local-llm.md`](../local-llm.md) holds the measurements.

Vulkan needed two pieces of extra configuration:

- `OLLAMA_IGPU_ENABLE=1`, because Ollama 0.34.2 ignores integrated GPUs by default.
- Kernel parameters that raise the memory the GPU can use to 48 GiB, because the default limit was 31 GiB.

### ROCm

ROCm is AMD's compute platform, and the backend that AMD hardware is normally paired with.
[#39](https://github.com/huwd/declarative_laptop/issues/39) and [#47](https://github.com/huwd/declarative_laptop/pull/47) rejected it because support for `gfx1150` was partial.
Neither source records a ROCm build, a test or a benchmark, and @huwd doesn't remember whether one was attempted.
The record therefore cannot say how ROCm would have performed here.

ROCm is a much larger stack than the Vulkan driver, which is part of Mesa.
That makes it heavier to build and cache, and CI builds each affected host's full system closure ([0005](0005-build-full-closure-on-every-pr.md)).
This size is an expectation, not a measurement.

Both stacks are open source.
Ollama, ROCm's runtime and Mesa are all under the MIT licence in the pinned nixpkgs.
Both rely on the `amdgpu` kernel driver and AMD's firmware.

On 2026-10-16, Ollama's documentation lists `gfx1150` as a supported ROCm target, naming the Ryzen AI 9 HX 375.
The pinned nixpkgs includes `ollama-rocm` and builds it for `gfx1150`.
The reason given in September may therefore no longer hold.

### CPU only

Ollama can run on the processor alone.
The issue didn't consider this, because the GPU was the point of the work.
It remains the behaviour when the GPU isn't selected, so the logs must confirm that the GPU is in use.

## Decision

`modules/local-llm.nix` sets `services.ollama.package` to `pkgs.ollama-vulkan` on `framework-13`.
Ollama and Open WebUI are installed but not started at boot.

The basis is that Vulkan works, as measured, and that ROCm is a larger stack that nobody has shown to be worth its cost on this machine.
It isn't a finding that ROCm is worse.

## Consequences

- The configuration doesn't use ROCm, so a ROCm upgrade or incompatibility doesn't affect it.
- Each Ollama release that changes how it treats integrated GPUs may need configuration changes.
  Check the logs after upgrading, using the commands in [`docs/local-llm.md`](../local-llm.md).
- The 48 GiB GPU memory limit comes from kernel parameters, so changing it requires a reboot.
- The measurements apply to Vulkan on this hardware.
  They say nothing about how ROCm would compare.

### When to reconsider

Revise this record when someone has run ROCm on this laptop and compared it with Vulkan.
Use the same prompt as the measurements in [`docs/local-llm.md`](../local-llm.md), and compare generation speed, prompt processing, load time, stability and the size of the closure.
Reconsider the backend sooner if any of these happens:

- ROCm shows a clear gain on this laptop.
- Ollama's Vulkan backend regresses or stops receiving support.
- The laptop is replaced with one that has a discrete AMD GPU.

A switch would be a new record that supersedes this one.
