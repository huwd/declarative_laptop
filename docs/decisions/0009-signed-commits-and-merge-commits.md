# 0009. Approve local signing through Bitwarden and preserve signed commits when merging

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** SSH signing 2026-09-22 ([#29](https://github.com/huwd/declarative_laptop/pull/29)); merge-commit policy 2026-10 (approximate); signed-commit rule in place by 2026-10-04 ([#62](https://github.com/huwd/declarative_laptop/pull/62))
- **Recorded:** 2026-10-04
- **Discussion:** [#29](https://github.com/huwd/declarative_laptop/pull/29), [#33](https://github.com/huwd/declarative_laptop/pull/33), [#54](https://github.com/huwd/declarative_laptop/issues/54), [#62](https://github.com/huwd/declarative_laptop/pull/62)

## Summary

AI coding agents share the same user account as the maintainer, so local signing should require explicit approval rather than silent access to a key file.
Git uses an SSH key held in Bitwarden, with approval for each use, to sign local commits and tags.
The repository requires signed commits on `main` and merge commits for pull requests, preserving the commits and signatures in each branch.
This adds approval prompts, a dependency on the desktop agent and a longer commit history.

## Context

Applying the system configuration involves root privileges, making control over changes to `main` important.
AI coding agents run as the same user as the maintainer, so they can use credentials available to that account.
A readable private-key file gives a process access to the key; signing alone does not create a separate approval step.

Per-use approval was a deliberate choice in [#29](https://github.com/huwd/declarative_laptop/pull/29).
The goal is to keep the private key in the vault and require a desktop interaction when a local process requests its use.
A valid signature identifies the signing key, but does not prove that the maintainer reviewed the contents of the change.

## Options considered

### Signing local commits and tags

#### SSH signing through the Bitwarden agent (chosen)

The private key lives in the Bitwarden vault.
The desktop app acts as the SSH agent, replacing GNOME's agent.
The intended authorisation setting requires approval for every key use, including local signing and SSH authentication to GitHub.
The [Bitwarden SSH agent documentation](https://bitwarden.com/help/ssh-agent/) explains its authorisation settings and Git integration.

Git signs local commits and tags with this key.
The declared `~/.ssh/allowed_signers` file lets Git verify signatures locally without opening the vault.
The Nix configuration selects the agent socket, but the desktop app's authorisation setting needs separate configuration.

#### Unsigned commits

Avoid signing prompts, but leave commit authorship as a claim in Git metadata without a signing key to verify it.
This would not meet the goal of requiring explicit approval to sign local changes.

#### SSH or GPG key files on disk

Signing identifies a key, but readable key files do not enforce per-use approval.
An encrypted key or an agent could provide other controls, but this project chose the existing Bitwarden vault and desktop approval workflow.
[#33](https://github.com/huwd/declarative_laptop/pull/33) fixed signing after removal of the local key files by embedding the public key in the configuration.

#### A hardware signing key

A separate hardware key could offer another way to control signing and reduce reliance on a software-held private key.
The decision deferred this option because it would add a physical device to keep track of.
It remains a possible hardening measure if that benefit later justifies the extra device and recovery arrangements.
Any evaluation needs to check that the chosen key and signing mode provide the desired per-use approval.

### Merging pull requests

#### Merge commits (chosen)

A merge commit keeps the original branch commits as ancestors, preserving their identities and signatures.
This makes the history longer but keeps each signed change available for inspection.

#### Squash, or rebase and merge

Squash merging creates one new commit in place of the branch's individual commits, losing their original identities and signatures from the merged history.
GitHub's rebase-and-merge method creates modified commits and does not preserve their original signatures.
The [GitHub signature documentation](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification) explains the rebase behaviour.

## Decision

- Sign every locally created commit and tag with the SSH key held in Bitwarden, requiring approval for each key use.
  [terminal/git.nix](../../terminal/git.nix) declares the public signing key and local verification configuration.
- The `main` ruleset requires signed commits, blocks force-pushes, and requires a pull request with passing checks ([#54](https://github.com/huwd/declarative_laptop/issues/54)).
- Merge pull requests with merge commits to preserve the branch commits and their signatures.

## Consequences

- Local signing and SSH authentication require the maintainer to approve key use at the desktop.
  Agents can prepare changes, but this workflow deliberately requires interaction before signing them.
- Bitwarden's desktop app must run, with vault access available, for this signing and authentication route.
  Changing its authorisation setting could remove the per-use prompt without changing the Nix configuration.
- The signed-commit rule also accepts GitHub-signed commits, including bot and web-created commits.
  A passing signature check does not show that the maintainer approved signing through Bitwarden ([0008](0008-ci-without-write-access.md)).
- Merge commits keep the commits from each branch and signatures, making the history longer while preserving individual changes.
- Signing does not replace review or CI checks, and it does not isolate agents from the same user account as the maintainer.
