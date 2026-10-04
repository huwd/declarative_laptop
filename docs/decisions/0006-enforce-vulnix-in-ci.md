# 0006. Fail CI on unreviewed CVE findings, with a justified, expiring whitelist

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06 (#1); enforcement fixed 2026-09-21 (#16);
  whitelist rules 2026-09-22 (#17, #35)
- **Recorded:** 2026-10-04
- **Discussion:** #1, #2, #16, #17, #35, #45, #46, #49

## Summary

In the context of a public configuration whose full software inventory
anyone can read, facing a steady stream of CVE reports against packages
in the closure, many of them false positives, the decision was for
vulnix scanning every built closure and failing CI on any finding not in
a whitelist where every entry is justified, and real risks expire, and
against informational-only scanning or no scanning, to achieve no
known, unreviewed vulnerability reaching the laptop, accepting that
updates can be blocked until findings are triaged.

## Context

Publishing the configuration publishes exactly which packages and
versions run on the machine (see `OPSEC.md`). Keeping known
vulnerabilities out is the main mitigation, and `OS.md` set the goal:
CVE scanning on every dependency update, with findings blocking merge.

vulnix matches the packages in a Nix closure against the US National
Vulnerability Database (NVD). Its matching is by name and version, so
it produces false positives: CVEs for unrelated projects with the same
name, or CVEs that nixpkgs has already patched without changing the
version.

Three events shaped the current rules:

- #16 found that findings were silently ignored: the scan's exit code was
  swallowed with `|| true`.
- An update in September 2026 surfaced 33 findings at once. Five were
  triaged properly and about 27 were bulk-whitelisted with a short expiry
  to unblock the install (#17). #35 then triaged each of those.
- NVD retired the bulk data feeds vulnix relies on, which crashed it
  (#45). #46 pointed vulnix at a community mirror.

## Options considered

### Enforced, with a justified, expiring whitelist (chosen)

A finding fails the build unless `vulnix.toml` whitelists it, and every
whitelist entry must carry a specific justification. The scan runs on
every built closure ([0005](0005-build-full-closure-on-every-pr.md)) and
posts its findings as a pull request comment for each host.

### Informational only

The original build plan ran vulnix with `continue-on-error: true` until
the whitelist was tuned. Findings that don't fail anything get ignored,
as #16 showed.

### No CVE scanning

Rely on keeping nixpkgs up to date. Updates fix most vulnerabilities,
but without a scan, there's no way to know what the current closure is
exposed to, or to answer later whether a CVE ever affected the machine.

{@TODO: were other scanners considered for the closure, such as grype
on an SBOM from sbomnix? grype is already used for Flatpak (see
`OPSEC.md`). Add as an option if so.}

## Decision

vulnix scans each built closure on every pull request and on `main`,
using the NVD mirror from #46, and the build fails on any finding not
in `vulnix.toml`.

Whitelist rules, from #17 and #35 and documented at the top of
`vulnix.toml`:

- every entry has a specific justification, not a generic "accepted"
- false positives and already-patched CVEs are permanent
- real vulnerabilities accepted as low risk get an `until` date, after
  which the finding fails CI again and must be looked at afresh
- keys that include a version stop matching when the package is updated,
  forcing a fresh look; keys without a version are for findings about
  the wrong product, which never apply
- entries link the issue where they were triaged

## Consequences

- No known, unreviewed CVE reaches a merged closure.
- A nixpkgs update can be blocked until its new findings are triaged,
  which takes time.
- Expiry dates mean accepted risks come back for review rather than
  being forgotten.
- The scan depends on a third-party NVD mirror. If it goes stale or
  disappears, findings could be missed or CI could fail.
- vulnix only sees Nix packages. Flatpak apps, firmware, browser
  extensions and configuration mistakes are outside it; `OPSEC.md`
  covers those gaps.
- Because `flake.lock` is committed, any past configuration can be
  rebuilt and scanned to answer whether a CVE affected the machine, and
  when.
