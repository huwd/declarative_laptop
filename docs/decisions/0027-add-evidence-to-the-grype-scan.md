# 0027. Give grype the package identities it needs, and add evidence that settles findings with no fix information

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-22
- **Recorded:** 2026-11-22
- **Discussion:** [#147](https://github.com/huwd/declarative_laptop/pull/147)
- **Changes:** the grype scan from [0019](0019-add-advisory-grype-scan.md) and its fix status from [0026](0026-split-the-grype-comment-into-pinned-and-upstream.md); the scan stays advisory

## Summary

On 22 November 2026, 293 of grype's 408 findings on framework-13 had no fix information, and grype missed whole parts of the closure.
Both have the same cause: grype has no NixOS data, so it matches each package only by the CPE that sbomnix guesses from its Nix name.

The scan now does five things about that:

- **E. Package identity:** give renamed variants such as `ffmpeg-headless` the upstream CPE, and give Python packages PyPI purls, so grype can match them at all.
- **A. Accepted risks:** give findings that the triage already accepts their own fix status, instead of Unknown.
- **C. Fix commits:** when a CVE record links the commit that fixes it, check whether that commit is in the release we run.
- **D. Build configuration:** check whether the vulnerable ffmpeg code is compiled into our build.
- **B. Debian's security tracker:** show what Debian records for each remaining finding, and draft triage statements from it.

A proof settles a finding by itself and goes into the VEX that grype reads.
Other evidence only informs: it shows in the comment and produces draft statements, which the maintainer reviews before adding them to `triage/vulnerabilities.ttl`.

## Context

### Why the SBOM and grype miss this

An SBOM records what is in the closure: each package's name, version, CPE and purl.
Whether a package is vulnerable comes from the scanner's database.
For Debian, Alpine or Red Hat systems, grype matches against the security feed of the distribution, which records fixed versions, backported patches and "not affected" decisions.
NixOS has no such feed in grype's database.
Every one of the 408 findings came from grype's `nvd:cpe` namespace, which matches CPE ranges from NVD.
Those ranges often name no fixed version: 99 of the ffmpeg records say only "through 9.0.2", and 61 of the kernel records have no version range at all.

sbomnix adds one security fact to the SBOM: the patches Nixpkgs applies that name a CVE.
Only 32 of 2,143 components have any.
It doesn't record the source revision behind a version, or how a package was configured.

sbomnix also guesses each CPE from the Nix name, which hides packages from grype:

- 324 Python packages are named like `python3.14-nltk`, so their CPEs and `pkg:nix` purls match nothing.
  Given PyPI purls, grype matched 62 findings in 15 of them against GitHub's advisory database, 3 critical and 29 high, and 57 with a fixed version.
- Variants such as `ffmpeg-headless`, `git-minimal` and `systemd-minimal` get CPEs like `ffmpeg-headless:ffmpeg-headless`.
  ffmpeg-headless 7.1.5 and 8.1.3 were in the closure and never scanned.

### What the Unknown findings were

Checked by hand on 22 November:

| Evidence | Findings |
| --- | --- |
| already an accepted risk in the triage | 24 |
| kernel fix commit already in v7.3 | 19 |
| Debian records a fix upstream at or below our version | 63 |
| Debian records a fix only in a Debian revision | 31 |
| Debian marks it unimportant | 16 |
| still open in Debian, 91 of them ffmpeg | 106 |
| not in Debian's tracker | 56 |

ffmpeg had 125 of the 293.
The four sampled fixes landed on the FFmpeg master branch in November 2026, after 9.0.2 was tagged in September, and none had been backported to `release/9.0`.
Those findings are real, with no release that fixes them.

## Options considered

### Keep triaging Unknown findings by hand

Every finding stays a human decision, but 293 findings is more than anyone reviews.
In practice they went unread, and the missing Python packages wouldn't show up at all.

### Treat all evidence as a decision

Suppress a finding whenever Debian records it as fixed at or below our version.
This removes the most noise, but Debian's fixed version sometimes refers to Debian's own patch, which Nixpkgs may not carry.
A version comparison against the numbering of another distribution is evidence, not proof.

### Suppress only on proof, and draft from the rest (chosen)

Two checks prove a finding fixed or absent from facts about our own build:

- the fix commit is an ancestor of the release tag we build from
- the vulnerable file wraps an external library that our ffmpeg build disables

Each proof is reproducible from the repository and tag, or from the store path, so it can go straight into VEX with that reasoning as its note.
Debian's tracker, and anything else that relies on another party's judgement, stays as evidence.

## Decision

`ci/grype-scan.sh` rewrites the identities in the SBOM before grype reads it, and runs grype twice.
The first pass finds what the evidence checks should look at.
The proofs from C and D become two more VEX documents, `commits.openvex.json` and `ffmpeg-config.openvex.json`, and the second pass reads them with the other two.

The fix statuses from 0026 gain two more:

- **Accepted:** the triage accepts the finding as a risk, with an expiry
- **Fixed after this version:** the fix commit exists upstream, but isn't in the release we run

Unknown findings show Debian's evidence.
Where Debian records a fix upstream at or below our version, the scan writes a draft statement to `drafts.ttl` in the report.

Each check names its inputs in the comment: the GitHub repository and tag for C, and the date the Debian tracker was downloaded for B.
If a check can't run, the comment says so, and the scan carries on without it.

[docs/vulnerability-scans.md](../vulnerability-scans.md) explains each check and status.

## Consequences

- More findings, not fewer, at first: the Python packages and ffmpeg-headless variants appear for the first time.
- Triage statements can name `pkg:pypi` purls.
  vulnix doesn't read them, because vulnix doesn't match Python packages by PyPI name.
- vulnix still can't see renamed variants such as `ffmpeg-headless`, so the gate and the advisory scan cover different sets of packages.
- The scan calls GitHub's API for each fix commit, about 400 calls for framework-13 on a cold cache, and downloads Debian's tracker, about 90 MB.
  The answers never change, so they're cached, and CI gives the scan its `GITHUB_TOKEN` for the API rate limit.
- C proves only commits that landed before our release tag.
  A fix backported under a different commit, as libtpms did in 2026, isn't proved: it shows as Fixed after this version, which a person can correct in the triage.
- D proves absence only for wrappers around external libraries, because Nixpkgs compiles in nearly every internal ffmpeg codec.
- Draft statements save writing, not judgement: each one still needs checking before it goes into the triage.
