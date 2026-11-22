# 0026. Split the grype comment into Pinned and Upstream sections, and classify each finding by where a fix exists

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-22
- **Recorded:** 2026-11-22
- **Discussion:** [#146](https://github.com/huwd/declarative_laptop/pull/146)
- **Changes:** the pull request comment from [0019](0019-add-advisory-grype-scan.md); the scan stays advisory

## Summary

grype's comment listed findings without saying whether anything could be done about them.
It now has two sections.
Pinned reports the closure pinned by the commit, as before.
Upstream evaluates the same host against the current `nixos-unstable` head and gives each finding a fix status: Actionable, Pending Nixpkgs, No fix upstream or Unknown.
Upstream depends on a moving input, so it names the revision it used.

## Context

On 22 November 2026, grype marked 75 findings on framework-13 as having a fixed version.
They mixed three different situations:

- fixes that Nixpkgs didn't have yet, such as OpenSSL 3.5.10
- version strings that grype ordered wrongly, such as `dnsmasq` `2.93` against a fix in `2.93test9`
- fixes already in Nixpkgs, which an update would pick up

Telling them apart meant evaluating Nixpkgs by hand.
Only the third needs `just update`, and the comment gave no way to see it.

The maintainer asked for that split, with the reproducible part of the comment kept apart from the part that depends on the date.
Neither part is fully fixed: grype's vulnerability database also changes daily.
Each section therefore names its inputs, rather than claiming to be reproducible.

## Options considered

### Evaluate against the nixos-unstable head in each scan (chosen)

`ci/grype-scan.sh` evaluates the host's system derivation with `--override-input nixpkgs` set to the head, without building it.
It takes a build-time SBOM of that derivation with sbomnix, the tool the Pinned section already uses, so package names match.
`ci/fix-status.nix` then compares the fixed version of each finding with the version at the head, using `builtins.compareVersions`.
On 22 November this took about ten seconds with a warm cache.

### Compare grype's fixed version with the pinned version only

This needs no extra evaluation, but it can't tell "Nixpkgs has the fix" from "Nixpkgs doesn't yet".
That's the distinction the maintainer asked for.

### Check Nixpkgs master instead of nixos-unstable

Master gets fixes first, but `just update` follows `nixos-unstable` ([0002](0002-track-nixos-unstable.md)).
A fix on master that hasn't passed Hydra can't be picked up yet, so calling it actionable would mislead.

## Decision

The grype comment has a Pinned section, naming the commit and the grype database date, and an Upstream section, naming the `nixos-unstable` revision and its date.
Upstream classifies every finding into one of four fix statuses.
[docs/vulnerability-scans.md](../vulnerability-scans.md) defines the sections and the statuses, and the comment links to it.
If the Upstream evaluation fails, the section says so and the scan continues.

## Consequences

- An Actionable count above zero means `just update` would fix something.
- The Upstream section can change between runs of the same commit, and the revision it names lets anyone reproduce it.
- CI fetches the `nixos-unstable` head for each scan, an input outside `flake.lock`.
  That is acceptable for an advisory section, and it doesn't affect the build, the vulnix gate or the Pinned section.
- Most findings are Unknown, because many CVE records name no fixed version.
- A version string that grype orders wrongly shows as Pending until the triage records it.
