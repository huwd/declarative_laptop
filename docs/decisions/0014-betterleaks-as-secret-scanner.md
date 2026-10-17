# 0014. Install Betterleaks as the laptop's secret scanner

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-10-17
- **Recorded:** 2026-10-17
- **Discussion:** [#96](https://github.com/huwd/declarative_laptop/issues/96), and the secrets plan in the `composer` repository (`docs/SECRETS_PLAN.md`), which asked for a scanner

## Summary

The laptop provides a secret scanner, so that each project can check its commits for plaintext secrets.
Betterleaks is the one installed, because it is the maintained successor to Gitleaks and reads the same configuration.
This repository installs the tool and doesn't enforce its use.
Each project decides what to scan, when, and what counts as a secret there.

## Context

[0013](0013-derive-age-key-from-ssh-agent.md) keeps dev secrets encrypted at rest.
Encryption doesn't stop a plaintext `.env` file, or a decrypted file, from being committed by mistake.
A scanner on staged changes catches that before it leaves the laptop.

Gitleaks was the usual choice for this.
Its original author lost control of its repository and name, and built Betterleaks as a drop-in successor (MIT licence, created February 2026, reads Gitleaks configuration).
The project is under a year old, and its recall claims come from its author.
The one outside comparison found was a vendor blog that didn't include it.

Which files hold secrets, which tools a project runs in its hooks and CI, and how they are compared are decisions about each project's data.
This repository holds none of that data.

## Options considered

### Betterleaks (chosen)

Scans git history and staged changes, and reads Gitleaks configuration, so a project's rules carry over if the tool changes.
It is maintained and packaged in nixpkgs.
The disadvantage is its age: it has little track record, and its results haven't been checked independently.

### Gitleaks

The established tool, also packaged in nixpkgs, and the fallback if Betterleaks disappoints.
The loss of control over the project's name and repository counts against building on it.

### TruffleHog

Scans git history, and can check credentials against providers, which is useful for triage after a real leak.
The AGPL-3.0 licence and the network calls make it a poor default for a pre-commit check.
A project that wants it can add it to its own CI.

### ripsecrets

Scans only the working tree, with no history scan, so it can't find a secret that was committed and later removed.
It is fast, and a project can use it where speed matters more than history.

### No scanner on the laptop

Each project would bring its own tool.
The laptop would then give no shared way to check a commit, and each repository would repeat the same packaging.

## Decision

- `betterleaks` is a system package in `modules/security.nix`, next to the secrets tools, and is on the `PATH`.
- Projects call `betterleaks` directly.
  No wrapper command is added, because there is one tool and one kind of caller, and a wrapper would hide differences between tools that matter.
  Add one if several repositories come to depend on a stable command name.
- This repository sets no global hook (`core.hooksPath`) and runs no scan in CI.
  A global hook is a policy for every repository, can clash with a repository's own hooks, and doesn't protect clones on other machines.
- Evaluating scanners against a project's own data belongs to that project.
  The `composer` repository's secrets plan owns the comparison with TruffleHog and ripsecrets.
- GitHub push protection is a free server-side gate that doesn't depend on any laptop.
  Enable it on the repositories that matter.

## Consequences

- `betterleaks` is available on the laptop after `just apply`, and a project's hook can rely on it.
- Swapping the scanner later means changing this package and the callers.
- The laptop gives no protection by itself: a project that doesn't call the scanner is unchecked.
- Betterleaks is new, so its behaviour and findings may change quickly.
  Pin it through `flake.lock` like any other package.

### When to reconsider

Write a new record that supersedes this one when any of these happens:

- A comparison on a project's real data shows another scanner finds clearly more, or flags clearly less noise.
- Betterleaks goes unmaintained, or changes its licence.
- Several repositories depend on the scanner, and a stable command name would save repeated changes.
- A real secret reaches a remote because the scanner missed it.
