# 0006. Fail CI on vulnerability findings unless a justified exception applies

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06 ([#1](https://github.com/huwd/declarative_laptop/pull/1)); enforcement fixed 2026-09-21 ([#16](https://github.com/huwd/declarative_laptop/pull/16)); whitelist rules 2026-09-22 ([#17](https://github.com/huwd/declarative_laptop/issues/17), [#35](https://github.com/huwd/declarative_laptop/pull/35))
- **Recorded:** 2026-10-04
- **Discussion:** [#1](https://github.com/huwd/declarative_laptop/pull/1), [#2](https://github.com/huwd/declarative_laptop/pull/2), [#16](https://github.com/huwd/declarative_laptop/pull/16), [#17](https://github.com/huwd/declarative_laptop/issues/17), [#35](https://github.com/huwd/declarative_laptop/pull/35), [#45](https://github.com/huwd/declarative_laptop/issues/45), [#46](https://github.com/huwd/declarative_laptop/pull/46), [#49](https://github.com/huwd/declarative_laptop/pull/49)

## Summary

CI checks the software built for the laptops for known vulnerabilities.
It scans each built system closure with vulnix and fails when findings remain outside a justified whitelist.
Accepted real vulnerabilities have expiry dates so they return for review.
Findings can block an update until the maintainer assesses their relevance and risk.

## Context

Publishing the configuration exposes the declared packages and dependency revisions (see [OPSEC.md](../../OPSEC.md)).
Scanning and reviewing findings help manage the associated risk.
The project adopted vulnix for its convenience in this Nix-based workflow, without comparing alternative scanners.
[OS.md](https://github.com/huwd/declarative_laptop/blob/eda4907a0533899ebb033fcd5b49d802f60214dc/OS.md) set the goal: CVE scanning on every dependency update, with findings blocking merge.

vulnix matches the packages in a Nix closure against the US National Vulnerability Database (NVD).
The [vulnix documentation](https://github.com/nix-community/vulnix) describes its name-and-version matching.
That matching can produce false positives: CVEs for unrelated projects with the same name, or CVEs that Nixpkgs has already patched without changing the version.

Three events shaped the current rules:

- [#16](https://github.com/huwd/declarative_laptop/pull/16) found that `|| true` suppressed the scan's exit code, allowing CI to pass despite findings.
- An update in September 2026 surfaced a batch of findings.
  Some initially received temporary exceptions to unblock installation ([#17](https://github.com/huwd/declarative_laptop/issues/17)); [#35](https://github.com/huwd/declarative_laptop/pull/35) then reviewed the findings individually.
- NVD retired the bulk data feeds vulnix relies on, which crashed it ([#45](https://github.com/huwd/declarative_laptop/issues/45)).
  [#46](https://github.com/huwd/declarative_laptop/pull/46) pointed vulnix at a community mirror.

## Options considered

### Fail CI unless a justified exception applies (chosen)

A reported finding fails the CI job unless [vulnix.toml](../../vulnix.toml) whitelists it.
Every whitelist entry must carry a specific justification.
The scan runs on every built closure ([0005](0005-build-full-closure-on-every-pr.md)) and posts its findings as a pull request comment for each host.

vulnix accepts Nix store paths directly, so CI can scan the closure it just built without introducing a separate inventory format.
Its whitelist supports package-specific exceptions and expiry dates, which suit the review process in this repository.
The [whitelist documentation](https://github.com/nix-community/vulnix/blob/master/doc/vulnix-whitelist.5.md) describes the supported fields.

The convenience comes with ongoing work: findings need assessment, and scan results depend on the vulnerability data and matching rules.
Nixpkgs patches may leave package version strings unchanged, so a reported match needs checking against the actual package definition.
This is a practical starting point for reviewing CVEs in Nix packages, with a reason to reconsider the tool if data availability or triage effort makes it impractical.

### Informational only

The original [build plan](https://github.com/huwd/declarative_laptop/blob/eda4907a0533899ebb033fcd5b49d802f60214dc/BUILD_PLAN.md) proposed `continue-on-error: true` while setting up the whitelist.
The failure in [#16](https://github.com/huwd/declarative_laptop/pull/16) showed that informational output alone did not ensure review.

### No CVE scanning

Rely on keeping Nixpkgs up to date.
Updates may include security fixes, but this approach would provide no automated report of known CVEs matched to the declared closure.

## Decision

vulnix scans each built closure on pull requests and on `main`, using the NVD mirror from [#46](https://github.com/huwd/declarative_laptop/pull/46).
The CI job fails when the scanner reports findings outside `vulnix.toml` or exits with an error.

Whitelist rules, from [#17](https://github.com/huwd/declarative_laptop/issues/17) and [#35](https://github.com/huwd/declarative_laptop/pull/35) and documented at the top of `vulnix.toml`:

- every entry has a specific justification, not a generic "accepted"
- false positives and already-patched CVEs do not need an expiry date
- real vulnerabilities accepted as low risk get an `until` date, after which the finding fails CI again and needs a fresh assessment
- keys that include a version stop matching after a package update, forcing a fresh assessment; keys without a version are for findings about the wrong product, which never apply
- entries link the issue or pull request containing the assessment

## Consequences

- A passing scan has no findings outside the whitelist for the data and matching rules used by vulnix.
  Findings require review, but this does not guarantee detection of every known vulnerability.
- New findings can block a Nixpkgs update until the maintainer assesses them, which takes time.
- Expiry dates bring accepted risks back for review.
- The scan depends on a third-party NVD mirror.
  If it goes stale or disappears, the scanner could miss findings or fail the CI job.
- Reconsider vulnix if unreliable data, excessive false positives or missed findings make it unsuitable.
  A replacement needs to justify its ongoing maintenance cost; document a change to the scanner or enforcement policy in a new decision record.
- vulnix only sees Nix packages.
  Flatpak apps, firmware, browser extensions and configuration mistakes are outside it; [OPSEC.md](../../OPSEC.md) covers those gaps.
