# 0001. Build the laptops declaratively with NixOS, in public, as a way to learn

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06
- **Recorded:** 2026-10-04
- **Discussion:** none; the reasoning lived in `OS.md` and `LEARNING_PLAN.md`
  (retired in #50)

## Summary

In the context of moving off Ubuntu ahead of a new Framework laptop,
facing machines whose state drifted with every imperative `apt install`
and a dotfiles repository that only covered part of the setup, the
decision was for a NixOS configuration built as a public flake, learnt
by building it, and against staying on Ubuntu with dotfiles or using Nix
only as a package manager, to achieve a laptop whose whole state is
written down, reproducible and reviewable, accepting a steep learning
curve and a publicly visible software inventory.

## Context

Before this repository, the machines ran Ubuntu, set up by hand and by
[huwd/dotfiles](https://github.com/huwd/dotfiles), which managed shell,
Git and editor configuration but not the operating system. Two machines
set up a year apart were never quite the same, and nothing recorded why
a package was installed or a setting changed.

A Framework Laptop 13 with an AMD Ryzen AI 300 processor was on order,
which meant setting up a machine from scratch anyway. An older Dell XPS
13 was available to try things on first.

{@TODO: confirm or correct the context above — what actually prompted
the move, and whether anything else was in play (work, a specific
breakage, curiosity about Nix)?}

## What this set out to teach

The project was as much about learning as about the result. Goals,
gathered from the original planning documents:

- **The Nix language**: reading and writing `.nix` files fluently,
  including attribute sets, functions and laziness
- **Flakes**: pinned inputs, `flake.lock`, and how outputs fit together
- **The NixOS module system**: options, `mkIf`, `mkMerge`, and writing
  modules
- **Home Manager**: a whole user environment declared in Nix
- **Per-project development environments**: `nix develop`, devenv and
  direnv in place of rbenv, pyenv and nvm
- **Secrets in a public repository**: agenix
- **Debugging Nix**: `nix repl`, `nix why-depends`, reading build failures
- **Running infrastructure like software**: CI that builds the whole
  system, CVE scanning of the closure, and reviewing every change through
  a pull request
- **Stretch goals**: Secure Boot with lanzaboote, overlays, VM tests,
  impermanence

Changes are deliberately made by hand where the point is to build
fluency, and handed to AI coding agents where the value is in the
decision rather than the typing.

## In @huwd's own words

{@TODO: @huwd to write this section — why do this at all, what "done"
looks like, and what's been learnt so far.}

## Options considered

### NixOS with flakes, built in public (chosen)

The whole system, including the user environment through Home Manager,
is declared in one repository. Every change is a commit and can be rolled
back to an earlier generation. Flakes pin every input, so a past
configuration can be rebuilt exactly. Building it in public adds a
reason to document it well and lets others reuse it.

Costs: an unfamiliar language and ecosystem, software that assumes a
conventional Linux filesystem layout needs workarounds, and the published
configuration tells anyone exactly what runs on the machine.

### Ubuntu with dotfiles

Continue with Ubuntu, extending huwd/dotfiles or adopting a tool such as
chezmoi or Ansible. Familiar and well supported, but configuration tools
on top of a mutable system still drift: they describe what to change,
not the whole state. It would also teach nothing new.

### Nix and Home Manager on Ubuntu

Use Nix as a package manager and Home Manager for dotfiles, while
keeping Ubuntu underneath. A gentler start, but the operating system
itself would stay imperative, which was the main problem.

{@TODO: were other options actually weighed — for example Fedora
Silverblue or another immutable distribution, or Guix? Add or remove
options here so the list reflects what was really considered.}

## Decision

The laptops run NixOS, configured by a single public flake in this
repository. The Framework was installed in September 2026; the Dell XPS
host is configured, but its hardware configuration is still a
placeholder. {@TODO: confirm the Dell's status.} Home Manager manages the user environment. The configuration
is reusable by others: the username and hostnames are the only personal
details, as the README explains.

Out of scope, recorded in the original planning documents:

- dual-booting: one operating system, using the whole disk
- multiple users on one machine
- hosting NixOS containers
  {@TODO: still a non-goal? Docker, Podman and Docker Sandboxes are now
  installed for development — confirm this means hosting services in
  NixOS containers, which remains out of scope.}

## Consequences

- Every later decision builds on this one: the update channel
  ([0002](0002-track-nixos-unstable.md)), Home Manager's role
  ([0003](0003-home-manager-as-nixos-module.md)), and CI that builds the
  whole system ([0005](0005-build-full-closure-on-every-pr.md)).
- A broken change can be undone by booting the previous generation.
- The repository is the documentation of the machines, so it has to stay
  accurate. That's why #50 retired documents that had drifted.
- The published software inventory is a deliberate, accepted risk.
  `OPSEC.md` holds the threat model.
- Learning happens in the open, including mistakes, in commit history and
  issues.
