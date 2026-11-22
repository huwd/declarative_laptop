# 0022. Sign off and sign an agent's commits with one `git sign-off` command

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-21
- **Recorded:** 2026-11-21
- **Discussion:** first built in [huwd/solid-oidc#27](https://github.com/huwd/solid-oidc/pull/27); reviewed and merged in [#135](https://github.com/huwd/declarative_laptop/pull/135)

## Summary

Coding agents commit without a signature or a `Signed-off-by` line, push their branch, and open a draft pull request.
When the branch is ready, the maintainer runs `git sign-off`, which signs off and signs the commits that lack a sign-off, pushes, and marks the pull request ready.
That leaves one hand-off, at the point where the maintainer certifies the work, and works in any repository.

## Context

The maintainer accepts changes to their repositories only through pull requests, and signs every commit through the Bitwarden SSH agent, with a `Signed-off-by` line.
Both certify that the maintainer may contribute the change, so an agent must never add them.

Until November 2026, an agent prepared a message for each commit and a throwaway script, the maintainer ran the script with Claude Code's `!` prefix, then pushed and opened the pull request by hand.
A branch took several hand-offs to reach review, CI ran only after the last of them, and one broken step in a script stopped the whole series.
The same steps were being rewritten for each repository.

Claude Code's own settings file isn't managed here, because a copy in the Nix store would be read-only (see `terminal/ai-agents.nix`).

## Options considered

### Agents commit unsigned, and one installed command finishes the branch (chosen)

The agent commits as it works, with `git -c commit.gpgsign=false commit`, and pushes a draft pull request, so CI runs early.
`git sign-off` then:

- rewrites the branch from the oldest commit without a sign-off, with `git rebase --signoff`, leaving earlier commits and merges alone
- merges the default branch if the branch is behind it, unless given `--no-update`
- checks every commit on the branch is signed and signed off
- pushes with `--force-with-lease`, and marks the pull request ready

Each rewritten commit asks Bitwarden for one approval.
Packaging it with `writeShellApplication` puts it on every machine with the configuration, and runs ShellCheck over it at build time.

### A copy of the script in each repository

- It's versioned with the project that uses it.
- Copies drift, and only the maintainer runs it, so the project gains nothing from carrying it.

### Agents prepare commits for the maintainer to make

- Nothing reaches GitHub until the maintainer acts.
- It's the process that prompted this change.

## Decision

The configuration installs `git-sign-off` from `packages/git-sign-off.nix`, and Git runs it as `git sign-off`.
Repositories that use sign-off tell agents to commit unsigned and to leave the finishing step to the maintainer.

## Consequences

- Agents' commits reach GitHub unsigned until `git sign-off` runs. A ruleset that requires signed commits on the default branch keeps them from merging until then.
- `git sign-off` rewrites the branch and force-pushes it, so anyone else working on the branch must fetch again afterwards.
- Each repository still sets its own agent permissions, such as allowing pushes and draft pull requests while denying sign-offs, force-pushes and merges, in its `.claude/settings.json`.
- The agent skills that describe committing need to describe this flow. They live in the skills repository.
