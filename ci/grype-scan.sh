#!/usr/bin/env bash
# Advisory grype scan of a NixOS system closure (ADR 0019).
#
# Usage: ci/grype-scan.sh <closure> <output-dir> <host>
#
# Run it from the repository root, so it finds openvex.json and the triage,
# with sbomnix, grype, jq, curl and nix on PATH:
#
#   nix shell --inputs-from . nixpkgs#sbomnix nixpkgs#grype nixpkgs#jq \
#     -c ci/grype-scan.sh ./result grype-report framework-13
#
# CI (.github/workflows/build.yml) and `just scan-grype` both call this
# script, so a local scan gives the same result as CI.
#
# Writes to <output-dir>:
#   sbom.cdx.json, sbom.spdx.json, sbom.csv   SBOM of the closure, from sbomnix
#   patches.openvex.json   "fixed" statements for the CVEs Nixpkgs patches
#   grype.json             full report, including the matches VEX removed
#   grype.txt              the same findings as a table
#   kev.json, kev-hits.json, kev.md   CISA KEV cross-check, from ci/kev-check.sh
#   comment.md             pull request comment body
#
# Exit status reports whether the scan ran, never whether it found anything.
set -euo pipefail

closure=$1
out=$2
host=$3
mkdir -p "$out"

# 1. Inventory: every package in the closure, with a CPE and a purl.
sbomnix "$closure" \
  --cdx "$out/sbom.cdx.json" \
  --spdx "$out/sbom.spdx.json" \
  --csv "$out/sbom.csv"

# 2. sbomnix lists the patches Nixpkgs applies, and the CVEs each one fixes,
# under each component's pedigree. Nixpkgs often patches without changing
# the version, which version matching cannot see, so turn each of those CVEs
# into an OpenVEX "fixed" statement for that package.
jq '{
  "@context": "https://openvex.dev/ns/v0.2.0",
  "@id": "urn:declarative-laptop:nixpkgs-patches",
  author: "ci/grype-scan.sh, from the sbomnix patch list",
  timestamp: (now | todate),
  version: 1,
  statements: [
    .components[]
    | select(.pedigree.patches and .purl)
    | .purl as $purl
    | .pedigree.patches[].resolves[]?
    | select(.type == "security")
    | {
        vulnerability: { name: .id },
        products: [ { "@id": $purl } ],
        status: "fixed",
        status_notes: ("Nixpkgs applies a patch for this CVE: " + (.references[0] // "no reference"))
      }
  ] | unique_by(.vulnerability.name + .products[0]["@id"])
}' "$out/sbom.cdx.json" > "$out/patches.openvex.json"

# 3. Match. Both VEX documents remove findings; grype keeps them under
# ignoredMatches in the JSON report, so nothing disappears silently.
# --quiet keeps grype's warnings about the SBOM's CPEs out of the log.
grype "sbom:$out/sbom.cdx.json" \
  --vex "$out/patches.openvex.json" \
  --vex openvex.json \
  --quiet \
  -o "json=$out/grype.json" \
  -o "table=$out/grype.txt"

# 4. Known exploited vulnerabilities: flag findings and triage entries for
# CVEs in CISA's KEV catalogue, and write kev.md for the comment.
ci/kev-check.sh "$out"

# 5. Comment. GitHub rejects comments over 65,536 characters, so the full
# table goes in a collapsed section and is cut short if it is too long.
matches=$(jq '.matches | length' "$out/grype.json")
ignored=$(jq '[.ignoredMatches[]?] | length' "$out/grype.json")
patched=$(jq '.statements | length' "$out/patches.openvex.json")
severities=$(jq -r '
  [.matches[].vulnerability.severity]
  | group_by(.) | map("\(length) \(.[0] | ascii_downcase)") | join(", ")
' "$out/grype.json")
by_package=$(jq -r '
  [.matches[].artifact | "\(.name) \(.version)"]
  | group_by(.) | map({ pkg: .[0], n: length }) | sort_by(-.n) | .[:15][]
  | "| `\(.pkg)` | \(.n) |"
' "$out/grype.json")

table=$(cat "$out/grype.txt")
limit=50000
if [ "${#table}" -gt "$limit" ]; then
  table="${table:0:$limit}
… cut short: the full report is in the grype-report-$host workflow artifact."
fi

{
  echo "## 🛡️ grype CVE scan, advisory ($host)"
  echo
  echo "Advisory only: this scan never fails the build ([ADR 0019](https://github.com/huwd/declarative_laptop/blob/main/docs/decisions/0019-add-advisory-grype-scan.md))."
  echo "It covers packages vulnix cannot match, such as the kernel and Chrome."
  echo
  cat "$out/kev.md"
  echo
  echo "**$matches findings** (${severities:-none})."
  echo "VEX removed $ignored more: Nixpkgs patches $patched CVEs, and \`openvex.json\` holds the hand-written triage."
  if [ "$matches" -gt 0 ]; then
    echo
    echo "| Package | Findings |"
    echo "| --- | --- |"
    echo "$by_package"
    echo
    echo "<details><summary>All findings</summary>"
    echo
    echo '```text'
    echo "$table"
    echo '```'
    echo
    echo "</details>"
  fi
} > "$out/comment.md"

echo "grype ($host): $matches findings, $ignored removed by VEX"
