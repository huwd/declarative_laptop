# 0023. Check for Dependabot updates daily, not weekly

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-22
- **Recorded:** 2026-11-22
- **Discussion:** [#138](https://github.com/huwd/declarative_laptop/pull/138)
- **Changes:** the schedule in [0007](0007-dependabot-for-flake-inputs.md); the two-day cooldown from [0020](0020-shorten-dependabot-cooldown-to-two-days.md) and the rest of 0007 stand

## Summary

Dependabot proposes updates to the flake inputs and GitHub Actions, and [0007](0007-dependabot-for-flake-inputs.md) had it check once a week.
With the two-day cooldown, a fix could take about nine days to reach `flake.lock` after it reached `nixos-unstable`.
Dependabot now checks every day, for both ecosystems, which cuts that to about three days.
The cooldown stays at two days, because it defends against compromised releases.

## Context

Two pressures led to the change, both described by the maintainer in the commit that made it:

- Researchers are disclosing vulnerabilities faster in 2026, much of it with AI help, so a week-old pin falls behind sooner.
- The vulnix gate ([0006](0006-enforce-vulnix-in-ci.md)) fails every pull request when a new CVE affects a pinned package, or when an accepted-risk entry in `vulnix.toml` expires.
  Small, unrelated changes then wait for a triage.
  On 22 November 2026, six expired entries blocked [#135](https://github.com/huwd/declarative_laptop/pull/135) until [#137](https://github.com/huwd/declarative_laptop/pull/137) renewed them.

A shorter lag helps with the second pressure only when the fix has already reached Nixpkgs.
On 22 November, none of the six packages had a fix in Nixpkgs that the pin lacked, so a daily check would not have avoided that triage.
It does shorten the time a finding stays open once Nixpkgs has a fix.

Each update pull request runs the full CI, including a Framework build and scan ([0021](0021-build-and-scan-only-the-framework-in-ci.md)).
The repository is public, so GitHub-hosted runners don't charge for those minutes, and the maintainer judged the extra runs worth it.

[0020](0020-shorten-dependabot-cooldown-to-two-days.md) explains the security purpose of the cooldown: a compromised release is often found and withdrawn within days, and the cooldown keeps such a release out of update proposals for that time.

## Options considered

### Daily checks for both ecosystems, keeping the two-day cooldown (chosen)

Fixes reach a pull request within about three days of reaching `nixos-unstable`.
The cooldown still skips releases in their first two days, so the supply-chain protection from 0020 is unchanged.
The cost is more update pull requests to review, merge and apply.

### Keep weekly checks, and update by hand when a fix is urgent

[0007](0007-dependabot-for-flake-inputs.md) already allows a manual `just update`.
As 0020 found, this depends on noticing that a fix exists, which the scans don't report while the fix hasn't reached the pin.

### Daily checks and no cooldown

This would shorten the lag by another two days.
It would also remove the only protection against a compromised release that is withdrawn soon after publication, which matters most for GitHub Actions.
The maintainer left the cooldown for a separate decision.

## Decision

Dependabot checks flake inputs and GitHub Actions daily, with grouped pull requests and a two-day cooldown.

## Consequences

- Flake updates arrive at most about three days after a fix reaches `nixos-unstable`, instead of about nine.
- Update pull requests can arrive on any day, and each one needs a review, a merge and a `just apply`.
- The manual `just update` route from [0007](0007-dependabot-for-flake-inputs.md) still applies for fixes that cannot wait.
- The cooldown is open to review as a separate decision.
