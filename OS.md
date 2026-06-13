# OS: NixOS

## Why NixOS

Moving from Ubuntu to NixOS to gain:

- **Declarative system state** — the entire OS is described in version-controlled
  Nix files. No more imperative `apt install` history that diverges across
  machines. What's in the repo is what's on the machine.
- **Reproducible builds** — rebuild an identical environment on any hardware
  from a single `nixos-rebuild switch --flake github:you/nixos-config#hostname`.
- **Atomic upgrades with rollback** — every `nixos-rebuild switch` creates a
  new system generation. Boot the previous generation from GRUB if something
  breaks.
- **Per-project dev environments** — `nix develop` / `devenv` give project-
  isolated toolchains without polluting the system or needing containers.
- **Security observability** — `vulnix` scans the full package closure against
  NVD. Because `flake.lock` is committed to git, historic CVE exposure is
  reconstructible: check out a past `flake.lock`, scan it, and know whether a
  vulnerability affected you and when.

## Target Experience

- GNOME (latest stable) on Wayland as the desktop
- Terminal-first workflow with personal dotfiles fully managed via Home Manager
- No manual configuration steps after a fresh install — everything declared

## Configuration Structure

```
nixos-config/
├── flake.nix                    # entry point; pins nixpkgs and all inputs
├── flake.lock                   # committed; source of truth for package versions
├── hosts/
│   └── framework-13/
│       ├── configuration.nix    # host-specific system config
│       └── hardware-configuration.nix  # generated; committed per host
├── modules/
│   ├── desktop/
│   │   └── gnome.nix
│   ├── development/
│   │   ├── default.nix          # common dev tools
│   │   └── languages.nix        # per-language toolchains via nix shells
│   ├── security.nix             # hardening, firewall
│   └── services.nix             # system services
├── home/
│   └── huw/
│       ├── default.nix          # home-manager entry point
│       ├── shell.nix            # zsh/fish, aliases, prompt
│       ├── terminal.nix         # alacritty/kitty, tmux
│       ├── editor.nix           # neovim / VS Code / IDE config
│       └── git.nix              # git config, signing
└── secrets/
    ├── secrets.nix              # agenix: declares who can decrypt what
    └── *.age                    # encrypted secret blobs (committed)
```

## Key Tool Choices

| Concern | Tool |
|---------|------|
| System config | NixOS modules + flakes |
| User config / dotfiles | Home Manager |
| Secrets | agenix |
| Dev environments | devenv + direnv |
| CVE scanning | vulnix |
| Generation diffing | nvd |
| Firmware updates | fwupd |
| Desktop | GNOME (Wayland) |

## Nixpkgs Channel Strategy

- **System**: `nixos-unstable` — gives access to recent packages and kernel
  versions; required for bleeding-edge hardware like Strix Point
- **Stability fallback**: pin specific packages to `nixpkgs-stable` via overlay
  if unstable introduces regressions
- **Flake lock discipline**: `nix flake update` is the only way to move package
  versions; no ad-hoc channel switching

## Dotfiles and Personal Config

Home Manager manages the full user environment declaratively:

- Shell (zsh + starship or similar prompt)
- Terminal emulator config
- Neovim / IDE setup
- Git identity and signing config
- Language version managers replaced by per-project nix shells (no rbenv, pyenv, nvm)
- `direnv` integration: `cd` into a project and the correct toolchain activates

## Dev Environment Philosophy

System packages are intentionally minimal. Per-project toolchains live in
`devenv.nix` or `flake.nix` within each project:

```bash
cd my-ruby-project   # direnv activates the shell
ruby --version       # project's pinned Ruby, not a system install
exit the dir         # Ruby disappears from PATH
```

This replaces rbenv, pyenv, nvm, and similar version managers entirely.
Toolchains are pinned per project and reproducible for collaborators.

## Security Objectives

1. **CVE scanning on every dependency update** — `vulnix` runs in CI whenever
   `flake.lock` changes; findings block merge
2. **Historic exposure analysis** — `flake.lock` history in git enables
   point-in-time CVE queries: "was my system affected by CVE-YYYY-XXXXX in
   January?"
3. **Secrets never in plaintext** — agenix encrypts all secrets; private keys
   never committed
4. **Firmware kept current** — `fwupd` via LVFS; Framework releases BIOS and
   controller updates regularly
5. **Minimal attack surface** — no services enabled by default; firewall on;
   only what is declared exists

## Non-Goals

- Dual-booting — single OS, full disk
- Supporting multiple users on one machine — single-user config
- NixOS container hosting — dev sandboxing via `nix develop` is sufficient
