# 0005. Build each affected host's full system closure on every pull request

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06 ([#1](https://github.com/huwd/declarative_laptop/pull/1)); refined 2026-09-21 ([#26](https://github.com/huwd/declarative_laptop/pull/26)); reaffirmed 2026-10-04 ([#54](https://github.com/huwd/declarative_laptop/issues/54))
- **Recorded:** 2026-10-04
- **Discussion:** [#1](https://github.com/huwd/declarative_laptop/pull/1), [#26](https://github.com/huwd/declarative_laptop/pull/26), [#54](https://github.com/huwd/declarative_laptop/issues/54), [#64](https://github.com/huwd/declarative_laptop/pull/64)

## Summary

Pull requests need to establish that the affected laptop configurations build before their changes merge.
CI builds each affected host's full system closure: the complete system and its dependencies.
Evaluation alone misses build failures, and building after merging discovers them too late.
Binary caches reduce the work needed for unchanged dependencies.
Each affected host adds CI time, and the cache and host-selection rules need maintenance.
Automated boot tests are outside the current CI scope to keep it fast and inexpensive.

## Context

[PLAN.md](https://github.com/huwd/declarative_laptop/blob/eda4907a0533899ebb033fcd5b49d802f60214dc/PLAN.md) set the CI goal in June 2026: check changes before applying them to the laptops.

A change in one file can affect dependencies elsewhere in a host's system closure.
Building the full system checks how those dependencies fit together.
Evaluating the flake catches type and option errors, but only a build catches a package that fails to compile, a broken patch, or a missing dependency.
Nix can reuse existing store paths or fetch them from a binary cache, avoiding a rebuild of dependencies whose outputs are already available.

Slow pull request builds prompted a cache investigation in [#54](https://github.com/huwd/declarative_laptop/issues/54).
The investigation identified authentication failures in the FlakeHub/Magic Nix Cache setup and throttling of the GitHub Actions cache.

## Options considered

### Full closure of affected hosts on every pull request (chosen)

A shared configuration change builds both hosts; a change confined to one host's configuration builds that host.
Documentation-only changes skip both builds.
The "Detect affected hosts" job in [build.yml](../../.github/workflows/build.yml) implements these rules ([#26](https://github.com/huwd/declarative_laptop/pull/26)).
Unknown shared paths trigger both hosts, so new configuration files receive build checks by default.
CI scans each built closure ([0006](0006-enforce-vulnix-in-ci.md)).
CI also attempts an nvd package diff against a cached `main` baseline when that baseline is available.
A single "Build result" check reports for whichever hosts ran, allowing the ruleset to require it even when the workflow skips hosts.

### Evaluation only

`nix flake check --no-build` on each pull request, with no builds.
Fast, but does not run the build steps that may fail when packages change.

### Build on main only ([#54](https://github.com/huwd/declarative_laptop/issues/54) Plan B)

Keep pull requests light and build after merging, with a status badge.
Rejected: CI would discover a broken closure only after it reached the branch that `just apply` deploys.
Successful pull request checks would provide no evidence that the new closure builds.

### Build every host on every pull request

The original setup.
Simple, but documentation-only and single-host changes paid for builds they couldn't affect.
Replaced by affected-host detection in [#26](https://github.com/huwd/declarative_laptop/pull/26).

### A self-hosted runner

Suggested in the original build plan for faster builds.
Not adopted: it would be a machine to maintain and secure, and caching made hosted runners fast enough.

## Decision

Every pull request builds the full system closure of each host it could affect.
Pushes to `main` always build every host, which keeps the nvd baseline current.

Keep pre-merge builds affordable by reusing packages from cache.nixos.org and caching selected slow packages built by CI.
[#64](https://github.com/huwd/declarative_laptop/pull/64) introduced this caching setup; [build.yml](../../.github/workflows/build.yml) defines the cached packages and how later runs reuse them.

CI is not in the deployment path.
The laptops build their configuration locally using the committed `flake.lock`.
The workflow does not publish system closures for the laptops to deploy.

## Consequences

- A successful host build provides evidence that its system closure built for the tested revision.
  It does not establish runtime behaviour or hardware compatibility.
- Each affected host adds CI time, which varies with the changes and available cached packages.
- Required checks include "Build result", not the per-host jobs, because the matrix skips unaffected hosts.
- The affected-host rules need updating when the repository gains new kinds of file that cannot affect a build, such as the documentation tooling from [#52](https://github.com/huwd/declarative_laptop/issues/52).
- Adding a host means adding it to the detection step in [build.yml](../../.github/workflows/build.yml).
- Automated VM boot tests were an early idea, but are not a current goal.
  The priority is fast, inexpensive CI that builds and scans affected closures.
