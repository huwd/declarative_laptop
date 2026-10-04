# 0007. Use Dependabot for flake input updates, not a scheduled workflow

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06-13 (#3); scheduled workflow removed 2026-10-04 (#63)
- **Recorded:** 2026-10-04
- **Discussion:** #3, #62, #63
- **Supersedes:** the weekly update workflow, "Tier 5" in `PLAN.md`
  (retired in #50)

## Summary

In the context of a configuration that tracks `nixos-unstable` and needs
regular `flake.lock` updates, facing a scheduled update workflow that
had never worked and could only be fixed with a long-lived write
credential, the decision was for Dependabot's Nix support and against
the custom workflow, to achieve weekly update pull requests that run the
full CI with no write access held by CI, accepting less control over
the update pull requests' content.

## Context

[0002](0002-track-nixos-unstable.md) means versions only move when
`flake.lock` does, so something has to update it regularly.

The original plan was a weekly GitHub Actions workflow, `update.yml`:
run `nix flake update`, build, scan, and open a pull request with the
package diff and CVE findings. Dependabot was also added on the first
day (#3), for flake inputs and for the GitHub Actions used by the
workflows, soon after GitHub added Nix support.

By October 2026 the scheduled workflow had failed on every run since at
least August, because GitHub Actions wasn't allowed to create pull
requests (#63). Allowing it wouldn't have been enough: pull requests
opened with the workflow's own token don't trigger other workflows, so
the required checks would never run.

## Options considered

### Dependabot (chosen)

`.github/dependabot.yml` opens one grouped pull request a week for all
flake inputs, and another for GitHub Actions, each with a seven-day
cooldown. Dependabot's pull requests trigger CI like any other, so each
update is built, scanned and diffed before it can merge (#60 is an
example). Nothing in the repository holds a credential to do this.

### Fix the scheduled workflow

Give it a personal access token or a GitHub App key so its pull requests
trigger CI. Rejected: it adds a long-lived write credential to a
repository whose CI otherwise has none
([0008](0008-ci-without-write-access.md)), to duplicate what Dependabot
already does.

### Manual updates only

Run `just update` locally whenever it seems time. Nothing would prompt
updates, so they would fall behind.

{@TODO: was Renovate considered? It supports Nix flakes and offers more
control over grouping and scheduling. Add as an option if so.}

## Decision

Dependabot updates flake inputs and GitHub Actions weekly, as grouped
pull requests with a seven-day cooldown. #63 removed the scheduled
update workflow.

For an urgent update, such as a critical CVE being exploited,
`just update` locally and open a pull request by hand, without waiting
for Dependabot.

## Consequences

- Every update goes through the same CI as any other change.
- CI holds no write access to the repository
  ([0008](0008-ci-without-write-access.md)).
- Weekly runs and the cooldown mean a fix can take one to two weeks to
  arrive by itself. Critical fixes need the manual route.
- Dependabot's pull request descriptions list changed inputs, not
  packages. The package diff and CVE findings come from CI comments
  instead.
- `OPSEC.md` describes the old weekly workflow and its manual trigger,
  and needs updating.
