# 0005. Build each affected host's full system closure on every pull request

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06 (#1); refined 2026-09-21 (#26); reaffirmed
  2026-10-04 (#54)
- **Recorded:** 2026-10-04
- **Discussion:** #1, #26, #54, #64

## Summary

In the context of a configuration that is deployed as root with
`just apply`, facing CI builds that were slow because caching never
worked, the decision was for building the complete system closure of
every affected host on every pull request, with a fixed cache, and
against evaluation-only checks or building only after merging, to
achieve the guarantee that anything merged will build, accepting several
minutes of CI per pull request and the work of keeping caching effective.

## Context

`PLAN.md` set the CI objective in June 2026: changes that pass CI can be
applied with confidence, and changes that fail it are never shipped.

A NixOS system is a single closure, so the unit that can fail is the
whole system, not the changed file. Evaluating the flake catches type
and option errors, but only a build catches a package that fails to
compile, a broken patch, or a missing dependency. Nix's store means
unchanged packages come from the binary cache rather than being rebuilt,
so a full build is mostly downloading.

By September 2026, pull requests felt slow. #54 found two causes: the
cache layer (FlakeHub through Magic Nix Cache) had never authenticated,
and GitHub's Actions cache throttled it within a minute of most runs.

## Options considered

### Full closure of affected hosts on every pull request (chosen)

A "Detect affected hosts" job diffs the pull request (#26). A host is
skipped only when every change is documentation, tooling, or confined to
the other host's directory, and anything unknown builds both. Each
remaining host's full closure is built, then scanned
([0006](0006-enforce-vulnix-in-ci.md)) and diffed against `main` with
nvd. A single "Build result" check reports for whichever hosts ran, so
it can be required even when hosts are skipped.

### Evaluation only

`nix flake check --no-build` on each pull request, with no builds. Fast,
but misses every failure that happens at build time, which are the
failures that matter on update pull requests.

### Build on main only (#54 Plan B)

Keep pull requests light and build after merging, with a status badge.
Rejected: a broken closure would be found only once it was already what
`just apply` deploys, and the required checks would have nothing to
gate on.

### Build every host on every pull request

The original setup. Simple, but documentation-only and single-host
changes paid for builds they couldn't affect. Replaced by affected-host
detection in #26.

### A self-hosted runner

Suggested in the original build plan for faster builds. Not adopted: it
would be a machine to maintain and secure, and caching made hosted
runners fast enough.

## Decision

Every pull request builds the full system closure of each host it could
affect. Pushes to `main` always build every host, which keeps the nvd
baseline current.

Caching works as fixed by #64: Magic Nix Cache is removed; packages come
from cache.nixos.org; and the few slow, unfree packages that are never
on cache.nixos.org (currently Open WebUI) are exported from `main` as a
single Actions cache entry and imported by later runs.

CI is not in the deployment path. The laptops build from `flake.lock`
themselves and never fetch anything CI built.

## Consequences

- A merged change is known to build. An update that breaks a package is
  found in its pull request.
- Each affected host costs several minutes of CI per pull request.
- Required checks include "Build result", not the per-host jobs, because
  the matrix skips unaffected hosts.
- The affected-host rules need updating when new kinds of file are added
  that can't affect a build, such as the documentation tooling from #52.
- Adding a host means adding it to the detection step in `build.yml`.
- VM smoke tests (booting the built system in QEMU) were planned as a
  later addition and are not implemented.
  {@TODO: still wanted? If so, open an issue; if not, drop it.}
