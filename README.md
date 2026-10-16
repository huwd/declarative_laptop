# declarative-laptop

A reproducible NixOS configuration for x86_64 laptops, managed as a Nix flake.
Shared behaviour lives in reusable modules; each machine gets its own host directory with hardware-specific config.

## Supported machines

| Host | Hardware |
|------|----------|
| `framework-13` | Framework Laptop 13 (AMD Ryzen AI 300 / Strix Point) |
| `dell-xps-13-9343` | Dell XPS 13 9343 (Intel Broadwell) |

## Repository structure

```text
hosts/          per-machine configuration and hardware-configuration.nix
modules/        shared NixOS modules (desktop, apps, gaming, development, security, services, local LLMs)
home/           Home Manager user configuration
terminal/       terminal environment (shell, prompt, editor, multiplexer)
packages/       packages built by this flake (the Vale prose linter)
scripts/        helper scripts used by the checks
secrets/        agenix secret declarations
docs/           guides, reference and decision records
```

## Personalising this config

Fork this repository to adapt it for your own machines.
Replace the username `huw` with your own before use:

```bash
# find every reference
grep -r "huw" hosts/ home/ flake.nix

# rename the Home Manager directory
mv home/huw home/<username>
```

Update `flake.nix` to point at the renamed directory:

```nix
users.huw = import ./home/huw;
# becomes
users.<username> = import ./home/<username>;
```

Set hostnames (`framework-13`, `dell-xps-13-9343`) in each host's `hosts/<host>/configuration.nix`.

## Installation

See [docs/install.md](docs/install.md) for a full walkthrough: building a bootable USB, full-disk encryption setup, and running the installer.
Then follow [docs/setup.md](docs/setup.md) for the checks to run after the first boot.

## Day-to-day usage

Rebuild and switch to the current config on the running machine:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

Or use the justfile shortcuts (host defaults to this machine's hostname; override with `just HOST=<host> build`):

```text
just check       check Nix formatting and lint, evaluate, check secrets, and lint Markdown
just build       build the system closure without applying
just scan        build, then scan the closure for known vulnerabilities (vulnix)
just apply       nixos-rebuild switch
just diff        compare built closure against running system
just update      update all flake inputs
just fix         auto-format and lint-fix .nix files
just docs-prose  check Markdown spelling and style (local only)
```

## Updating inputs

```bash
nix flake update
just build        # verify it evaluates and builds cleanly
just diff         # review what changed
just apply        # apply if happy
```

## Adding a new machine

1. Create `hosts/<name>/configuration.nix` — copy an existing host and adjust hostname, kernel, and CPU microcode
2. Create `hosts/<name>/hardware-configuration.nix` — use the placeholder from an existing host, then replace it with the output of `nixos-generate-config` on install day
3. Add a `nixosConfigurations.<name>` entry in `flake.nix`
4. Add the host to the `changes` job in `.github/workflows/build.yml`, which decides the hosts to build

See [docs/install.md](docs/install.md) for how to generate `hardware-configuration.nix` on the target machine.

## CI

Every pull request builds affected host closures and runs a CVE scan with vulnix.
CI also attempts an nvd package diff when it can fetch the baseline closure, with reports in PR comments when permissions allow.

## Guides

- [docs/install.md](docs/install.md): install a host from a USB drive
- [docs/setup.md](docs/setup.md): first-boot checklist
- [docs/operations.md](docs/operations.md): roll back, list generations, and check an earlier configuration for vulnerabilities
- [docs/local-llm.md](docs/local-llm.md): run local language models on `framework-13`

## Working with AI agents

[CLAUDE.md](CLAUDE.md) sets out how agents should work here: teach first, and follow the repository's workflow.

## Writing docs

Markdown follows [docs/style-guide.md](docs/style-guide.md): GOV.UK style, British English.
Record significant decisions in [docs/decisions/](docs/decisions/README.md).
Check with `just docs-lint` (also in CI) and `just docs-prose`.
