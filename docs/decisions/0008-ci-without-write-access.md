# 0008. Give CI no write access to the repository, and pin its tools

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06 (#7); extended 2026-10-04 (#62, #63)
- **Recorded:** 2026-10-04
- **Discussion:** #1, #7, #54, #62, #63

## Summary

In the context of a repository whose `main` branch is deployed as root
by `just apply`, facing CI jobs that ran third-party tools with a token
able to push GitHub-signed commits, the decision was for CI with no
write access to repository contents and tools pinned through
`flake.lock`, and against narrower fixes that kept a write token, to
achieve that no compromised tool in CI can change what gets deployed,
accepting that no automation can commit to the repository.

## Context

CI isn't in the deployment path: the laptops build from `flake.lock`
themselves ([0005](0005-build-full-closure-on-every-pr.md)), and the
repository holds no secrets. Most CI compromises would therefore be low impact.

The review in #62 found the exception. GitHub signs commits made through its API with
a workflow's token, and those signatures satisfy the `main` ruleset's
signed-commit rule. The ruleset didn't yet require pull requests or
status checks. A token with `contents: write`, exposed to any of the
third-party binaries CI runs, could have put code on `main` that the
next `just apply` would deploy as root.

At the time, the only job with that permission was the weekly update
workflow ([0007](0007-dependabot-for-flake-inputs.md)).

## Options considered

### No write access, and pinned tools (chosen)

Remove `contents: write` from every job, and reduce what CI trusts:

- every workflow defaults to `contents: read` (#7)
- checkouts don't keep the token in `.git/config`
  (`persist-credentials: false`)
- actions are pinned to full commit SHAs (#1)
- Nix is installed by `cachix/install-nix-action` from a versioned,
  hash-checked release, not the Determinate installer's mutable channel
- every `nix run nixpkgs#…` uses `--inputs-from .`, so CI tools come from
  the nixpkgs revision in `flake.lock`, not whatever was newest that
  minute

### Split the update workflow

As a first step, #62 split the update workflow so that the job running Nix had no
write token, and a separate job without Nix opened the pull request.
That reduced the risk but kept a write token in CI. #63 then removed the
workflow altogether.

### Rely on the ruleset alone

Require pull requests and status checks on `main` (done in #54), and
keep a write token. Rejected as the only defence: it depends on every
ruleset setting staying correct, and a token could still alter open
pull requests.

## Decision

No CI job can write repository contents. The build job's only extra
permission is `pull-requests: write`, to post its vulnix and nvd
comments. CI tools are pinned: actions by commit SHA, Nix by versioned
release, and Nix tools through `flake.lock`. Dependabot keeps the
action SHAs current.

## Consequences

- A compromised tool or action in CI can't change what `main` deploys.
- No automation can commit to the repository. Updates arrive through
  Dependabot ([0007](0007-dependabot-for-flake-inputs.md)), which GitHub
  runs outside the workflows.
- CI and `just` recipes run the same tool versions, because both take
  them from `flake.lock`.
- Any future workflow that needs to write has to justify a credential
  against this record.
