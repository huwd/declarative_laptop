# 0001. Build the laptops declaratively with NixOS, in public, as a way to learn

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06
- **Recorded:** 2026-10-04
- **Discussion:** no separate discussion; the original rationale is in [OS.md](https://github.com/huwd/declarative_laptop/blob/eda4907a0533899ebb033fcd5b49d802f60214dc/OS.md) and [LEARNING_PLAN.md](https://github.com/huwd/declarative_laptop/blob/eda4907a0533899ebb033fcd5b49d802f60214dc/LEARNING_PLAN.md).
  [#50](https://github.com/huwd/declarative_laptop/issues/50) proposed recording these decisions.

## Summary

Ordering a new Framework laptop prompted a move from Ubuntu to NixOS.
The aim is to explore how a declarative system feels in everyday use and how far its explicit configuration can support static analysis.
The earlier [dotfiles](https://github.com/huwd/dotfiles) project aimed to make the user environment quick to provision and restore to a baseline.
NixOS extends that goal to the operating system and provides a practical way to learn Nix.
Publishing the configuration invites scrutiny and feedback, and lets others reuse it.
The project accepts a steep learning curve and a publicly visible software inventory.

## Context

The new Framework laptop was the immediate trigger: a new machine needed provisioning anyway.
The broader motivation was to explore the ergonomics of working from a declarative configuration and the opportunities it creates for static analysis.
The goal is a primary operating system for everyday laptop use, with development support as part of that environment.

Ubuntu's pace of adopting major GNOME releases was another source of frustration.
Arch Linux was an alternative for access to newer software, but the desire to try declarative system configuration favoured NixOS.

The existing [huwd/dotfiles](https://github.com/huwd/dotfiles) repository aimed to make the user environment easy to provision and reproduce.
This project extends that goal to the operating system: a configuration that can bootstrap a laptop with less manual setup.
Faster provisioning is a secondary benefit alongside the exploration and learning goals.

## What this set out to teach

The project was as much about learning as about the result.
Goals, gathered from the original planning documents:

- **The Nix language**: reading and writing `.nix` files fluently, including attribute sets, functions and laziness
- **Flakes**: pinned inputs, `flake.lock`, and how outputs fit together
- **The NixOS module system**: options, `mkIf`, `mkMerge`, and writing modules
- **Home Manager**: a whole user environment declared in Nix
- **Per-project development environments**: `nix develop`, devenv and direnv in place of rbenv, pyenv and nvm
- **Secrets in a public repository**: agenix
- **Debugging Nix**: `nix repl`, `nix why-depends`, reading build failures
- **Running infrastructure like software**: CI that builds the whole system, CVE scanning of the closure, and reviewing every change through a pull request
- **Stretch goals**: Secure Boot with lanzaboote, overlays, VM tests, impermanence

Changes are deliberately made by hand where the point is to build fluency, and handed to AI coding agents where the value is in the decision rather than the typing.

## Options considered

### NixOS with flakes, built in public (chosen)

One repository declares the system configuration and the user environment that Home Manager manages.
Git records configuration changes, and earlier system generations provide a way to roll back configuration updates.
The committed `flake.lock` pins flake inputs so earlier configurations can use the same dependency revisions.
Building it in public adds a reason to document it well and lets others reuse it.

Costs: an unfamiliar language and ecosystem, software that assumes a conventional Linux filesystem layout needs workarounds, and the published configuration exposes the declared software inventory.

### Ubuntu with dotfiles

Continue with Ubuntu and the existing dotfiles repository.
This would keep a familiar environment, but would not address the frustration with Ubuntu's pace of adopting major GNOME releases or provide the desired experience of declarative operating-system configuration.

### Arch Linux

Move to Arch Linux for access to newer software.
This would address the desire for more recent releases, but would not meet the goal of exploring a declarative operating-system configuration.

## Decision

NixOS is the operating system chosen for the laptops.
It serves as the primary operating system for everyday use.
A single public flake in this repository declares their system configuration, and Home Manager manages the user environment.
Others can fork the repository and adapt the user, host and hardware configuration for their machines.

Scope limits:

- dual-booting: maintaining a second operating system adds complexity without serving the goal of a primary laptop operating system
- more than one user on a machine: the configuration only needs to support one user
- container tooling: Docker or Podman may support future development work, but they are not core goals of this project

## Consequences

- Every later decision builds on this one: the update channel ([0002](0002-track-nixos-unstable.md)), Home Manager's role ([0003](0003-home-manager-as-nixos-module.md)), and CI that builds the whole system ([0005](0005-build-full-closure-on-every-pr.md)).
- Booting an earlier generation restores its system configuration; it does not undo changes to personal files or application data.
- The repository is the documentation of the machines, so it has to stay accurate.
  [#50](https://github.com/huwd/declarative_laptop/issues/50) proposed separating lasting decisions from reference documentation.
- The published software inventory is a deliberate, accepted risk.
  [OPSEC.md](../../OPSEC.md) holds the threat model.
- Learning happens in the open, including mistakes, in commit history and issues.
