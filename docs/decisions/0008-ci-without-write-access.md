# 0008. Keep repository-content write access out of CI and pin its tools

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06 ([#7](https://github.com/huwd/declarative_laptop/pull/7)); extended 2026-10-04 ([#62](https://github.com/huwd/declarative_laptop/pull/62), [#63](https://github.com/huwd/declarative_laptop/pull/63))
- **Recorded:** 2026-10-04
- **Discussion:** [#1](https://github.com/huwd/declarative_laptop/pull/1), [#7](https://github.com/huwd/declarative_laptop/pull/7), [#54](https://github.com/huwd/declarative_laptop/issues/54), [#62](https://github.com/huwd/declarative_laptop/pull/62), [#63](https://github.com/huwd/declarative_laptop/pull/63)

## Summary

Applying this repository's system configuration changes the laptops with root privileges.
Repository workflows run third-party tools, so CI tokens must not be able to commit or push configuration changes.
CI uses tokens without repository-content write permission, pinned actions and Nix tools from the committed flake inputs.
Repository workflows cannot create update commits; Dependabot handles that work separately.

## Context

The laptops build their configuration locally rather than deploying closures published by CI ([0005](0005-build-full-closure-on-every-pr.md)).
That removes one route by which compromised CI output could reach a laptop, but CI still interacts with the repository.

The review in [#62](https://github.com/huwd/declarative_laptop/pull/62) identified a more direct route.
The weekly update workflow held a token with `contents: write`, and its API-created commits carried GitHub signatures that met the signed-commit rule.
At that point, the review found that the ruleset did not require pull requests or status checks.
A compromised tool with access to that token could have modified `main`, affecting the next application of the configuration.

The scheduled update workflow was the only job with repository-content write permission.
Removing it ([0007](0007-dependabot-for-flake-inputs.md)) removed that permission from the repository workflows.

## Options considered

The policy controls both what workflow tokens can change and which tool versions CI runs.

### Token permissions

#### No content-write permission (chosen)

Remove `contents: write` from every job:

- every workflow defaults to `contents: read` ([#7](https://github.com/huwd/declarative_laptop/pull/7))
- every checkout uses `persist-credentials: false`, so it does not keep the token in `.git/config`

These limits apply even if an attacker takes control of a workflow tool.

#### Split the update workflow

[#62](https://github.com/huwd/declarative_laptop/pull/62) first separated the read-only Nix job from a job that opened the pull request with a write token.
That reduced exposure but kept a content-write credential in CI.
[#63](https://github.com/huwd/declarative_laptop/pull/63) removed the redundant workflow altogether.

#### Rely on the ruleset alone

Require pull requests and status checks on `main`, while keeping a write token.
This adds an important gate, but relying on it alone leaves protection dependent on the ruleset settings and token permissions.
The chosen approach limits token permissions as well as requiring checks.

### Tool versions

#### Pin tools to reviewed versions (chosen)

Make the tool sources explicit so their versions are reviewable:

- action references use full commit SHAs ([#1](https://github.com/huwd/declarative_laptop/pull/1))
- the pinned `cachix/install-nix-action` selects a versioned upstream Nix installer instead of a mutable vendor channel
- calls to `nix run nixpkgs#…` use `--inputs-from .`, so those tools come from the Nixpkgs revision in `flake.lock`

Pinning identifies the chosen code; it does not establish that the code is trustworthy or that every downstream download is immutable.

## Decision

No repository workflow grants `contents: write`.
The build job requests `pull-requests: write` for vulnix and nvd comments, alongside `contents: read`.
That permission lets CI update pull request metadata, including comments.

Workflow action references use commit SHAs, the pinned installer action selects a versioned Nix release, and Nixpkgs tools use the revision in `flake.lock`.
Dependabot proposes updates to the action references.

## Consequences

- A workflow token without content-write permission cannot directly push or commit changes to repository contents.
  Compromised tools could still disrupt builds or manipulate reports within the permissions available to their job.
- Repository workflows cannot commit updates.
  Dependabot creates its update branches and pull requests through GitHub's separate updater service ([0007](0007-dependabot-for-flake-inputs.md)).
- CI and the corresponding `just` recipes select Nixpkgs tools from the same `flake.lock` revision.
  This does not require the runner and laptop to use the same Nix installation.
- Future workflows that need content-write permission must justify the credential and document a change to this policy.
