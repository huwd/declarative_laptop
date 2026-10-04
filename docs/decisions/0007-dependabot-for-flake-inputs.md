# 0007. Use Dependabot for flake input updates, not a scheduled workflow

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06-13 ([#3](https://github.com/huwd/declarative_laptop/pull/3)); scheduled workflow removed 2026-10-04 ([#63](https://github.com/huwd/declarative_laptop/pull/63))
- **Recorded:** 2026-10-04
- **Discussion:** [#3](https://github.com/huwd/declarative_laptop/pull/3), [#62](https://github.com/huwd/declarative_laptop/pull/62), [#63](https://github.com/huwd/declarative_laptop/pull/63)
- **Replaces:** the weekly update workflow described as "Tier 5" in [PLAN.md](../../PLAN.md)

## Summary

Following `nixos-unstable` requires regular updates to the pinned flake inputs.
Dependabot opens grouped update pull requests, while the repository's existing CI checks the affected configurations.
On 4 October 2026, the repository removed a failing custom updater and kept the existing Dependabot setup.
This resolved the duplicate updater problem without adding a credential to repository workflows.
This gives the maintainer less control over update descriptions, and the schedule and cooldown delay automatic updates.

## Context

[0002](0002-track-nixos-unstable.md) keeps flake inputs at the revisions in `flake.lock` until an update changes those pins.
Something needs to propose those updates regularly.

The original plan was a weekly GitHub Actions workflow, `update.yml`: run `nix flake update`, build, scan and open a pull request with the package diff and CVE findings.
[#3](https://github.com/huwd/declarative_laptop/pull/3) also introduced Dependabot for flake inputs and GitHub Actions.

The review in [#63](https://github.com/huwd/declarative_laptop/pull/63) found that every checked run of the custom updater since 3 August 2026 had failed.
Earlier runs failed on FlakeHub login; the final test failed because GitHub Actions lacked permission to create pull requests.
These were failures of `update.yml`, not Dependabot.

Repairing the custom updater would also require deciding how its pull requests start CI.
Under the behaviour described in the [GitHub token documentation](https://docs.github.com/en/actions/concepts/security/github_token), pull requests created with `GITHUB_TOKEN` need manual approval before their workflows run.
Automatic runs require a GitHub App installation token or a personal access token instead.

The repository resolved this by removing `update.yml` in [#63](https://github.com/huwd/declarative_laptop/pull/63), merged on 4 October 2026.
Dependabot already proposed updates and triggered CI, so repairing a second updater offered no needed capability.

## Options considered

### Dependabot (chosen)

[The Dependabot configuration](../../.github/dependabot.yml) schedules weekly checks for flake inputs and GitHub Actions.
It groups updates by ecosystem and configures a seven-day cooldown.
The schedule determines when Dependabot checks; it does not promise a new pull request every week.
The [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) describes grouping, scheduling and the cooldown period.

Dependabot update pull requests enter the same CI process as other changes ([#13](https://github.com/huwd/declarative_laptop/pull/13) is an example).
CI builds and scans affected closures and attempts a package diff when a baseline is available.
GitHub operates the updater separately from the repository workflows, so those workflows do not need credentials to create update commits.

### Fix the scheduled workflow

Use a personal access token or a GitHub App credential so update pull requests can start CI without manual approval.
This introduces a credential and an updater workflow to maintain, duplicating the existing Dependabot setup.
It conflicts with the preference to keep repository-content write credentials out of CI ([0008](0008-ci-without-write-access.md)).

### Manual updates only

Run `just update` locally and open a pull request by hand.
This keeps the workflow simple but relies on the maintainer remembering to update, with no regular proposal from an updater.

## Future evaluation

Renovate was not part of the original comparison, but its [Nix manager](https://docs.renovatebot.com/modules/manager/nix/) makes it a candidate if Dependabot's grouping or scheduling becomes too restrictive.

## Decision

Dependabot checks flake inputs and GitHub Actions weekly, using grouped pull requests and a seven-day cooldown.
[#63](https://github.com/huwd/declarative_laptop/pull/63) removed the scheduled update workflow.

For an urgent flake-input update, run `just update` locally and open a pull request by hand, without waiting for Dependabot.
Update GitHub Actions references separately.
Review the resulting dependency changes before merging.

## Consequences

- Update pull requests use the same required checks as other changes.
- Repository workflows hold no token with permission to write repository contents ([0008](0008-ci-without-write-access.md)).
  Dependabot still needs GitHub's separate authority to create its update branches and pull requests.
- The weekly schedule and cooldown delay automatic version updates.
  They do not provide a guaranteed delivery time; urgent fixes need the manual route.
- Dependabot descriptions focus on changed inputs or action references.
  CI provides closure scans and package diffs when the baseline and comment permissions allow them.
