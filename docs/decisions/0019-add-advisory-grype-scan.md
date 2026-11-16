# 0019. Add an advisory grype scan alongside vulnix, to cover packages vulnix cannot match

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-11-16
- **Recorded:** 2026-11-16
- **Discussion:** to be linked when the pull request opens

## Summary

The vulnix gate from [0006](0006-enforce-vulnix-in-ci.md) cannot see the Linux kernel or Google Chrome.
vulnix matches packages to vulnerability records by name, and the Nix names `linux` and `google-chrome` differ from the names the US National Vulnerability Database (NVD) uses, so no record ever matches them.
A second scanner, grype, finds them, but misses other real findings that vulnix catches.
CI now runs grype on every built closure as an advisory check: it reports findings on the pull request but never fails it.
Once its findings for the packages vulnix misses are triaged, grype becomes a gate for those packages.

## Context

[0006](0006-enforce-vulnix-in-ci.md) adopted vulnix without comparing alternative scanners, and named "missed findings" as a reason to reconsider it.
It covers every Nix package in the closure, so the kernel and Chrome have always been in scope.

On 16 November 2026 a spike compared vulnix 1.12.5 with grype 0.120.0 on the running `framework-13` system.
grype read a software bill of materials (SBOM) that sbomnix 1.9.0 generated from the closure, listing 2,127 packages.
Both tools match packages against NVD records by their CPE identifier, a vendor, product and version string.
They differ in how they work out each package's CPE:

- vulnix compares the Nix package name with the CPE product name and ignores the vendor.
- sbomnix guesses a full CPE, usually with the vendor equal to the product, plus a few built-in mappings.

Before whitelisting, the two tools reported these package and CVE pairs:

| Finding | vulnix | grype |
| --- | --- | --- |
| Pairs reported | 86 | 320 |
| Reported by both | 46 | 46 |
| Reported only by this tool | 40 | 274 |

The differences fall into three groups:

- **vulnix cannot see some packages.**
  sbomnix maps `linux` to `linux:linux_kernel` and `google-chrome` to `google:chrome`, so grype reported 68 kernel and 55 Chrome matches that vulnix cannot produce.
  Many kernel matches are old CVEs with loose version ranges in NVD, so the number overstates the real exposure, but none of them have been assessed.
- **grype misses some real findings.**
  sbomnix guesses `cups:cups` for CUPS, while NVD records its vulnerabilities under `openprinting:cups`.
  grype's database contains the nine CUPS findings that `vulnix.toml` accepts as real, but grype did not match any of them.
- **grype avoids some false positives.**
  Because it checks the vendor, grype did not report the Jenkins git plugin against `git`, the PHP knp-snappy library against `snappy` or the Ruby `zlib` gem against `zlib`.
  `vulnix.toml` whitelists all of these by hand.

The spike also found that sbomnix records the security patches Nixpkgs applies.
Its CycloneDX output lists, for each package, the CVEs its patches fix: 68 CVEs across 31 packages.
Converting that list into an OpenVEX document, a standard format for statements such as "this package is not affected by this CVE", removed 72 of grype's matches, including all 14 for `unzip`.
The same list covers 15 of vulnix's findings that `vulnix.toml` currently whitelists by hand as already patched.

## Options considered

### Run grype as an advisory check, then gate the packages vulnix misses (chosen)

CI generates an SBOM, generates OpenVEX statements from its patch list, runs grype and posts the findings as a pull request comment for each host.
The check never fails, so findings that nobody has assessed yet do not block merges.
The vulnix gate is unchanged.

This makes the kernel and Chrome findings visible straight away, and gives time to triage them before they can block anything.
The risk is the one [0006](0006-enforce-vulnix-in-ci.md) records from [#16](https://github.com/huwd/declarative_laptop/pull/16): findings that cannot fail CI tend not to be reviewed.
A review date limits that risk: by 2027-01-16, either grype becomes a gate for the packages vulnix cannot see, or a new record explains why not.

### Gate grype only for the packages vulnix cannot see

grype fails CI on findings in the kernel, Chrome and any other package vulnix cannot match.
This closes the gap with no advisory period, but the 123 kernel and Chrome matches would block every pull request until they were triaged.
It remains the intended next step.

### Gate grype on every finding

grype fails CI on any finding without a VEX statement.
This covers every finding, but about 338 matches that nobody has assessed would block all merges at once, most of them old or noisy.

### Replace vulnix with grype

grype would cover the kernel and Chrome, but the spike showed it missing nine real, accepted CUPS findings.
Swapping one tool for the other would trade one blind spot for another.

### Record the limitation and keep vulnix alone

Documenting the gap without adding a check leaves the kernel, the largest part of the attack surface, with no automated vulnerability report.

## Decision

The build workflow runs grype on each host's closure in addition to vulnix, as an advisory check.
For each host it:

1. generates a CycloneDX SBOM of the closure with sbomnix
2. converts the patch list in the SBOM into OpenVEX `fixed` statements
3. runs grype with those statements and with the hand-written statements in `openvex.json`
4. posts the remaining findings as a pull request comment, and keeps the full JSON report as a download on the workflow run

The script `ci/grype-scan.sh` carries out these steps, and `just scan-grype` runs the same script locally, so a local scan matches CI.
The grype step cannot fail the job.
The vulnix gate from [0006](0006-enforce-vulnix-in-ci.md) and its whitelist rules are unchanged.

Hand-written statements in `openvex.json` follow the same standard as `vulnix.toml`: each one has a specific justification and links its assessment.
A `not_affected` statement gives a justification and an impact statement, and an `affected` statement gives an action statement, which records the mitigation.

By 2027-01-16, grype becomes a gate for the packages vulnix cannot match, starting with the kernel and Chrome, or a new record explains why not.

## Consequences

- Kernel and Chrome findings are visible on every pull request, for the first time.
- Each pull request gets a second, longer scan comment for each host.
  Most of its findings are not yet assessed, and some are noise, until the triage catches up.
- Builds take longer: sbomnix and grype run after the build, and grype downloads its vulnerability database on each run.
  That database is a third-party dependency, like the NVD mirror vulnix uses.
- Triage now lives in two places, `vulnix.toml` and `openvex.json`, in two formats.
  OpenVEX has no expiry date, so the `until` rule from [0006](0006-enforce-vulnix-in-ci.md) cannot apply to `openvex.json` yet.
  Choosing which tool is primary, whether one triage file can serve both, and how expiry works are left to a later record, after a period of observation.
- The patch list from sbomnix could also replace the "already patched" entries in `vulnix.toml`, but vulnix cannot read OpenVEX.
  That is part of the same later decision.
- The nightly scan from [0015](0015-scan-main-for-new-vulnerabilities-on-a-schedule.md) still runs vulnix only.
