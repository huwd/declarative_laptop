# 0003. Apply Home Manager settings with the NixOS configuration

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06
- **Recorded:** 2026-10-04
- **Discussion:** [#22](https://github.com/huwd/declarative_laptop/pull/22), [#40](https://github.com/huwd/declarative_laptop/issues/40); see also the comment above the `nrs` alias in [terminal/shell.nix](../../terminal/shell.nix).

## Summary

Home Manager manages user settings such as the shell, Git and desktop preferences.
Run it as part of NixOS so `just apply` updates those settings and the operating system together.
This suits these laptops because the same person uses and administers each machine.
The trade-off is that even a shell alias needs `sudo` to apply.

## Context

The earlier dotfiles project managed the user environment separately from the operating system.
This project aims to bring both into the configuration used to provision a laptop ([0001](0001-why-this-project.md)).
Home Manager can run as part of a NixOS rebuild or independently through `home-manager switch`.
The choice is whether to apply system and user changes together or keep separate workflows.

## Options considered

### Include Home Manager in NixOS (chosen)

One command builds and applies both configurations.
Each saved NixOS generation includes the Home Manager configuration built with it, giving the maintainer one update and rollback workflow.
Applying user settings requires the same administrator access as applying system changes.

### Run Home Manager independently

Use `home-manager switch` to apply user settings without `sudo`.
This also supports machines that do not run NixOS.
The maintainer would manage separate commands and saved configurations for system and user changes.
That independence is useful when users do not administer the system, but adds a separate workflow for these laptops.

### Continue using the dotfiles repository

Keep managing user settings through the existing dotfiles setup.
This preserves a familiar way of working, but leaves a separate mechanism for setting up the user environment.
Home Manager brings those settings into the Nix configuration used to provision the laptop.

## Decision

Home Manager runs as a NixOS module for both hosts, with the user configuration in `home/huw/` and `terminal/`.
`just apply`, or the `nrs` shell alias, applies system and user configuration in one step.

The flake enables `useGlobalPkgs` to share the system's package set and `useUserPackages` to install user packages through the NixOS user profile.
The [Home Manager module documentation](https://github.com/nix-community/home-manager/blob/master/docs/manual/installation/nixos.md) explains both options.

Neovim settings are an exception: `~/.config/nvim` links directly to the repository's `home/huw/nvim/` directory ([#33](https://github.com/huwd/declarative_laptop/pull/33)).
Edits take effect when Neovim next starts, and its plugin manager can write to that directory.

## Consequences

- Applying changes managed by Home Manager, even a shell alias, requires a system rebuild with `sudo`.
  Nix reuses unchanged packages, so this does not mean compiling the whole system again.
- Returning to an earlier system generation restores the Home Manager configuration included in it.
  It does not restore personal files, application data or the contents of the live Neovim directory.
- Using this configuration on a non-NixOS machine would require a standalone Home Manager output and separation of any NixOS-specific settings.
