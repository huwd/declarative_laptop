# declarative-laptop

A reproducible NixOS configuration for x86_64 laptops, managed as a Nix flake. Shared behaviour lives in reusable modules; each machine gets its own host directory with hardware-specific config.

## Supported machines

| Host | Hardware |
|------|----------|
| `framework-13` | Framework Laptop 13 (AMD Ryzen AI 300 / Strix Point) |
| `dell-xps-13-9343` | Dell XPS 13 9343 (Intel Broadwell) |

## Repository structure

```
hosts/          per-machine configuration and hardware-configuration.nix
modules/        shared NixOS modules (desktop, apps, development, security, services)
home/           Home Manager user configuration
terminal/       terminal environment (shell, prompt, editor, multiplexer)
secrets/        agenix secret declarations
docs/           guides and reference
```

## Personalising this config

This repo is designed to be forked. The username `huw` is used throughout — replace it with your own before use:

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

Hostnames (`framework-13`, `dell-xps-13-9343`) are set per-host in `hosts/<host>/configuration.nix`.

## Installation

See [docs/install.md](docs/install.md) for a full walkthrough: building a bootable USB, full-disk encryption setup, and running the installer.

## Day-to-day usage

Rebuild and switch to the current config on the running machine:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

Or use the justfile shortcuts (default host is `framework-13`; override with `just build HOST=<host>`):

```
just check       lint, evaluate, and check secrets
just build       build the system closure without applying
just apply       nixos-rebuild switch
just diff        compare built closure against running system
just update      update all flake inputs
just fix         auto-format and lint-fix .nix files
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
2. Create `hosts/<name>/hardware-configuration.nix` — use the placeholder from an existing host; it is replaced by `nixos-generate-config` on install day
3. Add a `nixosConfigurations.<name>` entry in `flake.nix`
4. Add the host to the matrix in `.github/workflows/build.yml`

See [docs/install.md](docs/install.md) for how `hardware-configuration.nix` is generated on the target machine.

## CI

Every pull request builds all host closures, runs a CVE scan with vulnix, and posts a package diff with nvd as PR comments.
