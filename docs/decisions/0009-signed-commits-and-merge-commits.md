# 0009. Sign every commit through the Bitwarden SSH agent, and merge pull requests with merge commits

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-09-22 (#29)
  {@TODO: when were merge commits chosen over squash, and when did the
  ruleset start requiring signed commits? Add dates or links.}
- **Recorded:** 2026-10-04
- **Discussion:** #29, #33, #54, #62

## Summary

In the context of a repository whose `main` branch is deployed as root,
and where AI coding agents run as the same user, facing the risk of
commits made without the owner's knowledge, the decision was for signing
every commit and tag with an SSH key held in Bitwarden that needs
approval on each use, requiring signed commits on `main`, and merging
with merge commits, and against unsigned commits, key files on disk and
squash or rebase merging, to achieve a history where every commit is
verifiably approved by @huwd, accepting a prompt on every commit and
push.

## Context

Anything merged to `main` ends up running as root after `just apply`.
AI coding agents work in this repository as the same user, so anything
that user can do silently, an agent or a compromised tool could do too.
An SSH key file in `~/.ssh` can be read and used by any process running
as that user.

## Options considered

### SSH signing through the Bitwarden agent (chosen)

The private key lives in the Bitwarden vault. Bitwarden's desktop app
acts as the SSH agent, replacing GNOME's, and asks for approval in a
desktop prompt every time the key is used, whether to sign a commit or
to push. Git signs commits and tags with it, and `~/.ssh/allowed_signers`
lets signatures be checked locally.

### Unsigned commits

No friction, but no way to tell whether @huwd made a commit or something
else running as the user did.

### SSH or GPG key files on disk

Signing proves which key was used, but any process running as the user
can use a key file without anyone noticing. #33 removed the last key
files from `~/.ssh`.

{@TODO: was a hardware security key, such as a YubiKey, considered? It
would give similar per-use approval without depending on Bitwarden
running. Add as an option if so.}

### Squash, or rebase and merge

Squash merging turns each pull request into one new commit, losing the
individual commits and their signatures. GitHub's "rebase and merge"
re-creates each commit, which breaks the original signatures.

## Decision

- Every commit and tag is signed with the SSH key held in Bitwarden.
  The public key is in `terminal/git.nix`, so signatures can be checked
  without the vault.
- The `main` ruleset requires signed commits, blocks force-pushes, and
  requires a pull request with passing checks (#54).
- Pull requests merge with merge commits, keeping every signed commit.
  Branches are deleted automatically after merging.

## Consequences

- Every commit and push needs @huwd at the desktop to approve it. Agents
  can prepare changes but can't commit unattended. This is intended.
- Bitwarden's desktop app must be running and unlocked to commit or push.
- `main` keeps every commit from every pull request, with its signature,
  which makes the history longer but complete.
