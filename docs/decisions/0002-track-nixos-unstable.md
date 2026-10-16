# 0002. Track nixos-unstable, and update pinned inputs through flake.lock

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06
- **Recorded:** 2026-10-04
- **Discussion:** no separate discussion; the original rationale is in [OS.md](https://github.com/huwd/declarative_laptop/blob/eda4907a0533899ebb033fcd5b49d802f60214dc/OS.md).
  [#50](https://github.com/huwd/declarative_laptop/issues/50) proposed recording these decisions.

## Summary

This project favours recent software, particularly GNOME, while exploring NixOS and declarative system configuration.
The `nixpkgs` flake input follows `nixos-unstable`, with its revision pinned in `flake.lock`.
This provides access to newer software, including GNOME, and hardware support updates without automatically changing the installed system.
The accepted cost is that updates may introduce regressions or require configuration changes.
A stable release remains a fallback if broader problems make unstable impractical for everyday use.

## Context

Access to newer software was one reason for moving away from Ubuntu, particularly its pace of adopting major GNOME releases.
The decision preceded delivery of the Framework laptop.
It reflected a preference for recent software and experimentation, rather than a hardware problem encountered on stable NixOS.

Stable NixOS releases favour conservative bug and security updates over major software upgrades between releases.
The rolling `nixos-unstable` branch provides more recent software after it passes the channel's required checks.
[The channel documentation](https://wiki.nixos.org/wiki/Channel_branches) explains this distinction.

The committed `flake.lock` pins flake inputs to specific revisions, whichever branch they follow.
Following a rolling branch does not automatically update those pins or apply a new system configuration.
Changes to the pinned inputs go through pull requests before the maintainer applies the new configuration to the laptop.

## Options considered

### nixos-unstable, pinned by flake.lock (chosen)

Access to recent kernels, Mesa, firmware and other software through a rolling channel.
Hydra runs the required build and test jobs before the channel advances.
These checks reduce the risk of regressions but do not establish that every configuration or device works.

The maintainer can review updates frequently rather than waiting for the next stable release.
Their size depends on how much has changed since the last pinned revision.
Upstream may rename or remove options, and updates may introduce regressions that need configuration changes or upstream fixes.

### A stable release

Use a stable NixOS release with conservative bug and security updates.
This reduces changes between releases, but does not meet the preference for access to newer major software releases as directly.
It remains a fallback if broader problems with unstable interfere with everyday laptop use.

## Decision

The `nixpkgs` flake input follows `nixos-unstable`, with its revision pinned in `flake.lock`.
Updates to pinned flake inputs go through changes to that file, rather than ad hoc channel switching.
Configuration changes can also alter the resulting system without changing the lock file.
Updates arrive as pull requests ([0007](0007-dependabot-for-flake-inputs.md)) and CI builds and scans the affected system closures before merging ([0005](0005-build-full-closure-on-every-pr.md), [0006](0006-enforce-vulnix-in-ci.md)).

If broader problems make unstable impractical for everyday laptop use, reconsider the choice and move to a stable NixOS release.
Record that change in a new decision record that supersedes this one.

## Consequences

- Updates may need configuration changes for renamed options, as in [#16](https://github.com/huwd/declarative_laptop/pull/16).
- New packages may bring CVE findings that need assessment before an update can merge.
- `system.stateVersion` remains independent of the branch followed; updating packages does not require changing it.
- CI checks whether each affected system closure builds and scans it for known vulnerabilities before merging.
  Runtime behaviour and hardware compatibility still need validation on the laptop.
