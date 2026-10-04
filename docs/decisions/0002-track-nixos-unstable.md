# 0002. Track nixos-unstable, and move versions only through flake.lock

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06
- **Recorded:** 2026-10-04
- **Discussion:** none; the reasoning lived in `OS.md` (retired in #50)

## Summary

In the context of a laptop with brand-new AMD hardware, facing
stable NixOS releases whose kernel and graphics stack lag months behind,
the decision was for the `nixos-unstable` branch, pinned in `flake.lock`,
and against a stable release, to achieve working support for Strix Point
hardware and current software, accepting more frequent breakage and
renamed options on updates.

## Context

The Framework Laptop 13 uses an AMD Ryzen AI 300 processor (Strix
Point). Support for it in the kernel, firmware and graphics stack was
still arriving in mid-2026. A stable NixOS release fixes package
versions for six months, so it would have lagged behind the fixes this
hardware needed.

A flake's `flake.lock` pins every input to an exact revision, whichever
branch is followed. Following a fast-moving branch doesn't mean the
machine changes unexpectedly: nothing changes until `flake.lock` does.

## Options considered

### nixos-unstable, pinned by flake.lock (chosen)

Recent kernels, Mesa and firmware, and new packages as soon as they land.
Updates are rolling rather than twice a year, so each one is smaller.
Unstable is tested by Hydra before it advances, so it is less fragile
than the name suggests.

Costs: options get renamed or removed between updates, and an update
occasionally breaks something until upstream fixes it.

### A stable release (25.05 at the time)

Fewer surprises and security backports, but packages that are months
old. For this hardware, the kernel alone would have needed overriding,
undoing much of the benefit.

### Stable, with selected packages from unstable

Run a stable release and pull individual packages from unstable through
an overlay. Keeps most of the system stable, but mixes two package sets,
which makes problems harder to diagnose and doubles what has to be
evaluated.

## Decision

The `nixpkgs` flake input follows `nixos-unstable`. Package versions
change only when `flake.lock` changes, never through ad hoc channel
switching. Updates arrive as pull requests
([0007](0007-dependabot-for-flake-inputs.md)) and are built and scanned
before merging ([0005](0005-build-full-closure-on-every-pr.md),
[0006](0006-enforce-vulnix-in-ci.md)).

The Framework uses `linuxPackages_latest` for the newest stable kernel.
The older Dell XPS uses the default kernel.

If an update regresses a package, the fallback is to pin that one
package to an earlier revision or to a stable release through an
overlay, rather than holding back the whole system. No such pin exists
yet.

## Consequences

- New hardware support and fixes arrive within days of landing upstream.
- Updates sometimes need small fixes for renamed options, as in #16.
- New packages bring new CVE findings to triage, which can block an
  update until it's assessed.
- `system.stateVersion` stays at the release the machine was installed
  with, independent of the branch followed.
- Because CI builds every update before it merges, a broken update is
  found in a pull request rather than on the laptop.
