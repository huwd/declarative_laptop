# 0015. Scan main for new vulnerabilities on a schedule, and check locally before pushing

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-10-30
- **Recorded:** 2026-10-30
- **Discussion:** [#105](https://github.com/huwd/declarative_laptop/pull/105), [#104](https://github.com/huwd/declarative_laptop/pull/104), [#103](https://github.com/huwd/declarative_laptop/pull/103)

## Summary

The vulnix gate from [0006](0006-enforce-vulnix-in-ci.md) depends on the date as well as the code.
A new CVE can fail a pull request that did not cause it.
A nightly scan of `main` now reports new findings in an issue, and a pre-push hook runs the same checks as CI before you push.
The gate on pull requests does not change.

## Context

In October 2026 [#103](https://github.com/huwd/declarative_laptop/pull/103), a bump of one GitHub Action, failed CI because of findings in `cups` and `libsoup`.
The fix in [#104](https://github.com/huwd/declarative_laptop/pull/104) then failed on two more findings, in `brotli` and `glib`, published in the days between runs.
Each round meant waiting for a build of about five minutes to learn what to triage next.

Three gaps made this slower than it needed to be:

- `just scan` omitted the NVD mirror that CI uses ([0006](0006-enforce-vulnix-in-ci.md)), so it did not match CI.
- The build matrix cancelled the other host when one host failed, which hid that host's result.
- Nothing ran the checks before a push, and nothing reported new CVEs unless a pull request happened to be open.

## Options considered

### Report on a schedule and check before pushing (chosen)

A nightly workflow builds each host from `main`, runs vulnix and keeps one issue per host open while findings remain.
It closes the issue when a scan comes back clean.
The workflow has `issues: write` and `contents: read`, so it meets [0008](0008-ci-without-write-access.md).
A tracked `pre-push` hook, installed with `just hooks`, runs `just check` and, when Nix files, `flake.lock` or `vulnix.toml` change, `just scan`.
`just scan` now uses the mirror, and the build matrix lets every host finish.

This finds new CVEs without waiting for a pull request and gives the same result locally as in CI.
It cannot make the gate deterministic: a CVE published after the scan can still fail a later pull request.

### Stop failing pull requests on findings that they did not introduce

Gate a pull request only on findings absent from the `main` baseline.
This removes the unrelated failures, but it needs a stored baseline per host and a rule for what counts as new.
It also weakens the "findings block merge" rule from [0006](0006-enforce-vulnix-in-ci.md), so it needs its own decision.

### Move the scan into a pre-commit hook

A scan needs a built closure, which takes minutes, so a commit-time hook would be slow enough that people would skip it.
A pre-push hook runs less often and only when a change can alter the closure.

## Decision

Scan `main` nightly and open or update an issue per host while findings remain.
Provide a `pre-push` hook through `just hooks` that runs `just check` and, for relevant changes, `just scan`.
Keep the pull request gate from [0006](0006-enforce-vulnix-in-ci.md) unchanged.

## Consequences

- New CVEs appear as an issue within a day, instead of as a surprise on the next pull request.
- The hook is opt-in: run `just hooks` once in each clone. `git push --no-verify` skips it.
- The hook scans only this machine's host, and only when its hostname matches a `nixosConfigurations` entry.
- A push that changes Nix files takes as long as a local build of the closure.
- Pull requests can still fail on a CVE that is new since the last scan. Revisit the baseline option if this keeps blocking unrelated updates.
- The scan still depends on the third-party NVD mirror ([0006](0006-enforce-vulnix-in-ci.md)).
