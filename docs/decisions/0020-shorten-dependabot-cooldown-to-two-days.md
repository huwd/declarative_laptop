# 0020. Shorten the Dependabot cooldown from seven days to two

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-17
- **Recorded:** 2026-11-17
- **Discussion:** [#127](https://github.com/huwd/declarative_laptop/pull/127)
- **Changes:** the cooldown in [0007](0007-dependabot-for-flake-inputs.md); the rest of that decision stands

## Summary

Dependabot waits for a cooldown period before it proposes a new version, and [0007](0007-dependabot-for-flake-inputs.md) set that period to seven days.
For flake inputs, this kept the pinned Nixpkgs at least a week behind `nixos-unstable`, which delays security fixes that are already available.
The cooldown is now two days, for flake inputs and GitHub Actions.

## Context

A Dependabot cooldown skips any new version that is younger than the cooldown period.
The [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) describes the setting.
Combined with the weekly schedule, a seven-day cooldown meant a flake update could arrive up to two weeks after Nixpkgs published a fix.

Two cases on 17 November 2026 showed the cost:

- The advisory grype scan proposed in [#125](https://github.com/huwd/declarative_laptop/pull/125) reported 57 findings in Google Chrome `157.0.8103.50`, all fixed in `157.0.8103.78`, which `nixos-unstable` already had.
- The `convco` build fix from [NixOS/nixpkgs#585314](https://github.com/NixOS/nixpkgs/pull/585314), which [#117](https://github.com/huwd/declarative_laptop/issues/117) waits for, merged on 14 November.

A cooldown also has a security purpose.
A compromised release of a dependency is often found and withdrawn within days, and a cooldown keeps such a release out of update proposals for that time.
This matters most for GitHub Actions, which run in CI with the job's permissions.

## Options considered

### Two days for both ecosystems (chosen)

Updates arrive within days of a fix, and the cooldown still skips releases in their first two days.
Actions references stay pinned by commit SHA ([0008](0008-ci-without-write-access.md)), and every update still needs review and passing checks before it merges.

### Two days for flake inputs only, seven for GitHub Actions

This keeps the longer protection where a compromised release is most dangerous.
It was not chosen because Actions updates go through the same review, but it remains the fallback if a compromised action release gets close to merging.

### No cooldown

Updates would arrive on the next weekly check, with no protection against a release that is withdrawn soon after publication.

### Keep seven days, and update by hand when a fix is urgent

[0007](0007-dependabot-for-flake-inputs.md) already allows a manual `just update` for urgent fixes.
This depends on noticing that a fix exists, which the scans do not report for packages whose fix has not reached the pin yet.

## Decision

Dependabot uses a two-day cooldown for flake inputs and for GitHub Actions.
The weekly schedule and grouping from [0007](0007-dependabot-for-flake-inputs.md) are unchanged.

## Consequences

- Flake updates arrive at most about nine days after a fix reaches `nixos-unstable`, instead of about fourteen.
- Update pull requests can contain releases that are only two days old, so review matters more, especially for GitHub Actions.
- The manual `just update` route from [0007](0007-dependabot-for-flake-inputs.md) still applies for fixes that cannot wait for the weekly check.
