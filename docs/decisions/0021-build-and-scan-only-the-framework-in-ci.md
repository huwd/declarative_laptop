# 0021. Build and scan only the Framework in CI, and check the Dell on demand

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-17
- **Recorded:** 2026-11-17
- **Discussion:** [#131](https://github.com/huwd/declarative_laptop/issues/131), [#132](https://github.com/huwd/declarative_laptop/pull/132)
- **Changes:** which hosts [0005](0005-build-full-closure-on-every-pr.md), [0006](0006-enforce-vulnix-in-ci.md), [0015](0015-scan-main-for-new-vulnerabilities-on-a-schedule.md) and [0019](0019-add-advisory-grype-scan.md) apply to; the rest of those decisions stands

## Summary

The repository configures two laptops, but only the Framework is in daily use.
CI built and scanned the Dell XPS 13 on most pull requests, which roughly doubled build time and the number of scan comments for a machine that is rarely booted.
Routine CI now builds and scans only the Framework.
The Dell stays in the flake and still receives every update, and it is built and scanned on demand before it is next used.
The repository is no longer actively maintained for the Dell between those checks.

## Context

[0001](0001-why-this-project.md) describes the project as one configuration for several laptops, and the flake defines two hosts: `framework-13` and `dell-xps-13-9343`.
[0005](0005-build-full-closure-on-every-pr.md) builds every host a pull request could affect, and pushes to `main` build every host.
[0006](0006-enforce-vulnix-in-ci.md), [0015](0015-scan-main-for-new-vulnerabilities-on-a-schedule.md) and [0019](0019-add-advisory-grype-scan.md) scan each built host.

In [#131](https://github.com/huwd/declarative_laptop/issues/131), the maintainer recorded that the Framework is now the laptop in use and the Dell is rarely booted.
For the Dell, the maintainer plans to check the configuration from this repository before using it, then pull and apply on the Dell.

The cost of keeping the Dell in CI on 17 November 2026:

- Its closure build took about 12 minutes on each pull request, alongside the Framework's 13.
- It added a vulnix comment, a grype comment and a package diff to every pull request.
- Its grype scan reported 459 findings, 195 of them in its older kernel line, none of which would be acted on while the laptop is unused.

## Options considered

### Routine CI for the Framework only, and a manual run for any host (chosen)

Pull requests and pushes to `main` build and scan the Framework.
The build workflow can also be run by hand for a chosen host, which builds it, runs vulnix and grype, and writes the results to the run summary.
The nightly scan covers the Framework only.

This halves the build work on most pull requests and removes the Dell's comments.
The Dell's configuration can break without notice, through a shared module, an option removed upstream or a package that stops building.
The manual run before using the Dell is where that shows up, and fixing it then is accepted as part of using the Dell.

### Keep the Dell in CI

This catches breakage straight away, at the cost of the build time and comments for a machine that is not in use.

### Build the Dell only when its own files change

A pull request that changes `hosts/dell-xps-13-9343/` would still build it.
This was not chosen because it keeps a partial commitment to maintaining the Dell, which the maintainer chose to give up.

### Scan the Dell on a monthly schedule

A scheduled run would report breakage and new vulnerabilities between uses.
This was not chosen because nobody would act on those reports while the Dell is unused.

### Remove the Dell from the flake

This would remove the configuration the maintainer still wants to apply when the Dell is next used.

## Decision

Routine CI builds and scans only the hosts listed in `CI_HOSTS` in the build workflow, which is `framework-13`.
The nightly vulnix scan runs for the same hosts.
The `Evaluate flake` check and `just check` run `ci/evaluate.sh`, which evaluates the flake's packages, dev shells and the Framework's system, but not the Dell's.
It replaces `nix flake check --no-build`, which evaluates every host.
The build workflow has a manual trigger with a host input, so `gh workflow run build.yml -f host=dell-xps-13-9343` builds and scans the Dell on demand.
Every run, manual or not, writes its vulnix and grype results to the run summary.

The Dell stays in the flake, and flake updates apply to it.
Before using the Dell, the maintainer checks it with the manual run, then pulls and applies on the Dell, as [docs/operations.md](../operations.md#bring-the-dell-up-to-date-before-using-it) describes.

## Consequences

- Most pull requests build one host instead of two, and carry one set of scan comments.
- Nothing in routine CI or `just check` evaluates the Dell, so no change to the repository can fail a check because of it.
  The manual run evaluates and builds the Dell, and is the only check on it.
- `ci/evaluate.sh` lists the flake's outputs itself, so it skips the checks `nix flake check` makes on the structure of the flake's outputs.
- The Dell's vulnerabilities go unreported between manual runs.
  [OPSEC.md](../../OPSEC.md) records this gap.
- `vulnix.toml` entries that only the Dell needed become dormant, and can be removed in a later tidy-up.
- To bring a host back into routine CI, add it to `CI_HOSTS` in `build.yml`, to the matrix in `vulnix-scheduled.yml` and to the default hosts in `ci/evaluate.sh`.
