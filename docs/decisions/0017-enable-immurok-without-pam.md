# 0017. Use the immurok key through an external flake, and enable it on the Framework without any PAM rule first

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-13
- **Recorded:** 2026-11-13
- **Discussion:** [huwd/immurok-nix#11](https://github.com/huwd/immurok-nix/issues/11), the plan for pairing the key on real hardware

## Summary

The immurok key is a Bluetooth fingerprint reader that can approve `sudo`, polkit prompts and screen unlocks.
This repository now takes its package and NixOS module from a separate flake, [huwd/immurok-nix](https://github.com/huwd/immurok-nix), and turns the module on for the Framework only.
Turning it on adds the daemon and its plumbing, and changes nothing about how logins or `sudo` work.
Any rule that makes the key part of authentication is a later change, one service at a time, each with its own record.
A wrong authentication rule can lock the maintainer out of `sudo`, so using the device and trusting it are separate steps.

## Context

The key arrived on 2026-11-13.
Upstream ships `.deb`, `.rpm` and Arch packages and an installer that edits `/etc/pam.d`.
None of that works on NixOS, where `/etc/pam.d` is generated from the configuration.

This laptop already has a working authentication stack ([0013](0013-derive-age-key-from-ssh-agent.md) and [0009](0009-signed-commits-and-merge-commits.md) depend on parts of it):

- `sudo` and `polkit-1` try the laptop's fingerprint reader through `fprintd`, then the password.
- Logins use the password only.
- Commits are signed with an SSH key held in Bitwarden, and the Bitwarden agent already owns that job.

The package is useful to other NixOS users, so it lives in its own repository with its own decisions about packaging.
This record covers only how this machine uses it.

## Options considered

### An external flake input, enabled with no PAM rule (chosen)

`flake.nix` takes `immurok-nix` as an input, with its `nixpkgs` following this repository's.
`modules/immurok.nix` sets `services.immurok.enable = true`, and only `framework-13` imports it.
The flake lock pins the exact commit.

The advantage is that the change is small and reversible, and the generated PAM files for `sudo`, `polkit-1`, `login`, `gdm-password` and `su` come out byte-identical to `main`, which was checked before this record.
The cost is a second repository to keep in step.
The package builds from source on the laptop, because no binary cache has it.

### Package it in this repository

Fewer moving parts, and the build runs in this repository's CI.
It would mix a reusable package with one machine's choices, and nobody else could use it without this configuration.

### Enable the key for `sudo` straight away

The quickest way to see it work.
Pairing and enrolment haven't been tried on real hardware yet, and a rule that fails closed would block the command needed to fix it.
This isn't worth the risk before the plan in [immurok-nix#11](https://github.com/huwd/immurok-nix/issues/11) has passed.

### Let the module add the PAM rules, off by default

Convenient, and the module would own the ordering.
The ordering against `fprintd` is this machine's policy, and the module can't know it.
`immurok-nix` documents how to write the rule in a machine's own configuration instead.

### Not use the key

Nothing to maintain.
It was bought to try, and the package was written to learn how NixOS packaging and modules work ([0001](0001-why-this-project.md)).

## Decision

- `flake.nix` has an `immurok` input from `github:huwd/immurok-nix`, and the `framework-13` configuration includes `immurok.nixosModules.default`.
- `modules/immurok.nix` enables `services.immurok` and nothing else.
  Only `framework-13` imports it.
- No PAM rule is added in this change.
  Each later rule, starting with `sudo`, gets its own change and its own record, once pairing and enrolment have passed the plan in [immurok-nix#11](https://github.com/huwd/immurok-nix/issues/11).
- SSH signing stays with the Bitwarden agent.
  The key's SSH signing isn't planned.

## Consequences

- The daemon, the `immurok` system user, the D-Bus policy and the session agent now exist on the Framework.
  Bluetooth was already on there.
- The first `just apply` builds the package, which takes several minutes and runs the tests that come with the source.
  `immurok-nix` skips two of them that fail in the build sandbox, and records why in [immurok-nix#10](https://github.com/huwd/immurok-nix/issues/10).
- `immurok-nix` is a dependency to watch.
  Updating the input means rebuilding, and a new upstream release can change the licence, as one did in July, so check the licence on each bump.
- Dependabot's Nix updates will propose new `immurok-nix` commits.
- If the key is dropped, remove the input, the import and `modules/immurok.nix`, and the `immurok` user and state directory go with the next apply.
- Revisit the order of the key and `fprintd` in the `sudo` rule when the first PAM change is written.
