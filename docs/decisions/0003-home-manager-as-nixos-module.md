# 0003. Run Home Manager as a NixOS module, not standalone

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06
- **Recorded:** 2026-10-04
- **Discussion:** #22, #40; see also the comment above the `nrs` alias in
  `terminal/shell.nix`

## Summary

In the context of a single-user NixOS laptop whose user environment is
declared with Home Manager, facing a choice between applying system and
user configuration together or separately, the decision was for Home
Manager as a NixOS module and against the standalone `home-manager`
command, to achieve one command that applies, and rolls back, the whole
machine at once, accepting that user-level changes need a full system
rebuild with `sudo`.

## Context

Home Manager declares the user environment: shell, prompt, editor, Git,
terminal and desktop settings. It can run in two ways:

- **standalone**, with its own `home-manager switch` command, its own
  generations, and no root access needed
- **as a NixOS module**, where `nixos-rebuild switch` builds and activates
  the user configuration alongside the system

Each laptop has one user, the same person who administers it.

## Options considered

### NixOS module (chosen)

The flake imports `home-manager.nixosModules.home-manager`, with
`useGlobalPkgs` and `useUserPackages`. One `nixos-rebuild switch`, or
`just apply`, applies everything. System and user configuration share
one nixpkgs and one generation, so a rollback restores both together.

### Standalone Home Manager

A separate `homeConfigurations` output, applied with `home-manager
switch`. User changes apply faster and without root, and the same
configuration could manage a non-NixOS machine. The cost is two commands
and two sets of generations that can fall out of step, and a second
nixpkgs evaluation unless carefully shared.

### No Home Manager

Keep user configuration in a dotfiles repository, as before. Rejected in
[0001](0001-why-this-project.md): it leaves the user environment outside
the declared state.

## Decision

Home Manager runs as a NixOS module for both hosts, with the user
configuration in `home/huw/` and `terminal/`. `just apply`, or the `nrs`
shell alias, applies system and user configuration in one step.

The one deliberate exception is Neovim: `~/.config/nvim` is linked
straight into the repository with `mkOutOfStoreSymlink` (#33), so plugin
and configuration changes take effect on the next start without a
rebuild.

## Consequences

- One command and one generation history for the whole machine.
- Every user-level tweak, even a shell alias, needs a full rebuild with
  `sudo`.
- The configuration can't manage a non-NixOS machine, such as a work
  laptop, without restructuring.
- #22 removed a leftover `hms` alias for the standalone command.
  {@TODO: the `apply-home` recipe in the justfile still runs `home-manager
  switch --flake .#<host>`, but the flake has no `homeConfigurations`
  output, so it can't work. Remove it in a follow-up?}
