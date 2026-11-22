# 0025. Keep accepted risks visible in the grype scan, and compile its OpenVEX from the triage graph

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-22
- **Recorded:** 2026-11-22
- **Discussion:** [#143](https://github.com/huwd/declarative_laptop/pull/143)
- **Changes:** [0019](0019-add-advisory-grype-scan.md), whose hand-written `openvex.json` this retires

## Summary

[0024](0024-keep-vulnerability-triage-in-one-rdf-graph.md) moved triage into one RDF graph, but grype still read only an empty, hand-written `openvex.json`.
The graph now compiles to the OpenVEX document grype reads, and `openvex.json` is gone.
grype drops findings that the triage marks `not_affected` or `fixed`, but keeps reporting accepted risks, and its pull request comment labels each one with its expiry.

## Context

The vulnix gate hides an accepted risk until its `triage:until` date, so it doesn't fail every pull request.
The grype scan is advisory ([0019](0019-add-advisory-grype-scan.md)): it never fails the build, so hiding a finding there only removes information.

OpenVEX has no expiry date.
A document that included accepted risks would have to drop expired ones when the scan runs, because Nix evaluation cannot read the date.

On the updated framework-13 closure on 22 November 2026, the compiled document removed 11 of grype's 441 findings.
25 more were CVEs that the triage accepts as real risks.

## Options considered

### Permanent statements only, with accepted risks labelled (chosen)

The OpenVEX document holds only `not_affected` and `fixed` statements, which the shapes make permanent, so it needs no expiry handling.
Accepted risks stay in grype's findings, and the comment lists them in their own table with their expiry, marking any that have expired.
A reviewer sees which real risks are open, and for how long they are accepted.

### Include accepted risks, and drop expired ones at scan time

grype would hide accepted risks until they expire, as vulnix does.
This needs a date filter in `ci/grype-scan.sh`, outside the reproducible build, and the advisory scan would no longer show open, real vulnerabilities.

### Keep a hand-written `openvex.json` for grype-only triage

Some CVEs reach only grype, such as old CVEs whose NVD record matches every version of a package.
A second file for those would bring back the two-places problem that 0024 removed; a statement in the graph covers them.

## Decision

`nix build .#vuln-triage` also writes `openvex.json`, holding the permanent statements, and `accepted.json`, listing the accepted risks.
`ci/grype-scan.sh` passes the OpenVEX document to grype and labels accepted risks in the comment.
The hand-written `openvex.json` is removed, and the KEV check reads only the compiled triage.

## Consequences

- grype and vulnix agree on every permanent decision, and a CVE that only grype reports is triaged in the same graph.
- The grype comment shows accepted risks separately, so the findings that nobody has triaged yet are easier to see.
- An accepted risk is still counted in grype's total until it is fixed.
- grype matches a purl without a version against every version of a package, which was checked against the 22 November SBOM.
