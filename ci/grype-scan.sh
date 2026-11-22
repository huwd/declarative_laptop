#!/usr/bin/env bash
# Advisory grype scan of a NixOS system closure (ADR 0019), with each
# finding classified by where a fix exists (ADR 0026).
#
# Usage: ci/grype-scan.sh <closure> <output-dir> <host>
#
# Run it from the repository root, so it can build the triage (ADR 0024),
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
#   triage.openvex.json    the permanent triage statements, compiled from
#                          triage/vulnerabilities.ttl
#   accepted.json          the accepted risks from the same graph
#   grype.json             full report, including the matches VEX removed
#   grype.txt              the same findings as a table
#   kev.json, kev-hits.json, kev.md   CISA KEV cross-check, from ci/kev-check.sh
#   upstream.cdx.json      SBOM of <host> evaluated against the nixos-unstable head
#   fix-status.json        each finding's fix status, from ci/fix-status.nix
#   upstream.md            the comment's Upstream section
#   comment.md             pull request comment body
#
# Exit status reports whether the scan ran, never whether it found anything.
set -euo pipefail

closure=$1
out=$2
host=$3
mkdir -p "$out"

# 0. Triage: compile triage/vulnerabilities.ttl (ADR 0024). Its OpenVEX
# document holds only permanent statements (not_affected and fixed), so
# grype drops those findings; accepted risks stay in the report, and
# accepted.json labels them with their expiry in the comment.
triage=$(nix build .#vuln-triage --no-link --print-out-paths)
cp "$triage/openvex.json" "$out/triage.openvex.json"
cp "$triage/accepted.json" "$out/accepted.json"
chmod u+w "$out/triage.openvex.json" "$out/accepted.json"

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

# 3. Match. Both VEX documents remove findings: the Nixpkgs patches, and
# the permanent triage. grype keeps them under ignoredMatches in the JSON
# report, so nothing disappears silently.
# --quiet keeps grype's warnings about the SBOM's CPEs out of the log.
grype "sbom:$out/sbom.cdx.json" \
  --vex "$out/patches.openvex.json" \
  --vex "$out/triage.openvex.json" \
  --quiet \
  -o "json=$out/grype.json" \
  -o "table=$out/grype.txt"

# 4. Known exploited vulnerabilities: flag findings and triage entries for
# CVEs in CISA's KEV catalogue, and write kev.md for the comment.
ci/kev-check.sh "$out"

# 5. Upstream: classify each finding by where a fix exists (ADR 0026).
# Evaluate the host against the current nixos-unstable head, without
# building it, and take a build-time SBOM of that derivation. Only this
# section depends on an unpinned input, so it records the revision it used.
# It is advisory too: if any step fails, the section says so and the scan
# carries on.
docs=https://github.com/huwd/declarative_laptop/blob/main/docs/vulnerability-scans.md
upstream() {
  local rev date drv pinned
  rev=$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/nixos-unstable | cut -f1) || return 1
  [ -n "$rev" ] || return 1
  drv=$(nix eval --raw --override-input nixpkgs "github:NixOS/nixpkgs/$rev" \
    ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath") || return 1
  date=$(nix flake metadata --json "github:NixOS/nixpkgs/$rev" | jq -r '.lastModified | todate | .[:10]') || return 1
  pinned=$(jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked.rev' flake.lock)
  sbomnix "$drv" --buildtime --cdx "$out/upstream.cdx.json" --spdx /dev/null --csv /dev/null > /dev/null 2>&1 || return 1
  nix eval --impure --json --expr \
    "import $PWD/ci/fix-status.nix { grype = $(realpath "$out/grype.json"); head = $(realpath "$out/upstream.cdx.json"); accepted = $(realpath "$out/accepted.json"); }" \
    > "$out/fix-status.json" || return 1

  # One row for each package, CVE and version, as grype can match a CVE twice.
  # shellcheck disable=SC2016
  jq -r --arg rev "$rev" --arg date "$date" --arg pinned "$pinned" --arg docs "$docs" '
    unique_by([.package, .version, .cve]) as $f
    | def n($b): [$f[] | select(.bucket == $b)] | length;
      def rows($b; cols):
        [$f[] | select(.bucket == $b)] | group_by([.package, .version])
        | sort_by(-length) | .[:15][] | cols;
    "### Upstream: against nixos-unstable `\($rev[:12])` (\($date))",
    "",
    "Where a fix exists for each pinned finding, at the head of `nixos-unstable` ([fix status](\($docs)#fix-status)).",
    "This section changes as `nixos-unstable` moves; it is reproducible against the revision above.",
    (if $rev == $pinned then "The pinned Nixpkgs is already at this revision, so nothing is actionable." else empty end),
    "",
    "| Fix status | Findings | What to do |",
    "| --- | --- | --- |",
    "| Accepted | \(n("accepted")) | accepted in the triage until a date: see the accepted risks above |",
    "| Actionable | \(n("actionable")) | Nixpkgs has the fix: run `just update` |",
    "| Pending Nixpkgs | \(n("pending")) | fixed upstream, not yet in Nixpkgs: wait, or look for a Nixpkgs pull request |",
    "| No fix upstream | \(n("no-fix")) | triage it: accept it with a mitigation, or remove the package |",
    "| Unknown | \(n("unknown")) | grype has no fix information: triage it by hand |",
    (if n("actionable") > 0 then
      "", "**Actionable:**", "", "| Package | Pinned | At the head | CVEs |", "| --- | --- | --- | --- |",
      rows("actionable"; "| `\(.[0].package)` | \(.[0].version) | \(.[0].atHead // "patched") | \(length) |")
    else empty end),
    (if n("pending") > 0 then
      "", "**Pending Nixpkgs:**", "", "| Package | Pinned | Fixed in | CVEs |", "| --- | --- | --- | --- |",
      rows("pending"; "| `\(.[0].package)` | \(.[0].version) | \(map(.fixedIn // "?") | unique | join(", ")) | \(length) |")
    else empty end)
  ' "$out/fix-status.json" > "$out/upstream.md"
}
if ! upstream; then
  printf '### Upstream\n\nSkipped: evaluating %s against the nixos-unstable head failed. The pinned findings above are complete.\n' "$host" > "$out/upstream.md"
fi

# 6. Comment. GitHub rejects comments over 65,536 characters, so the full
# table goes in a collapsed section and is cut short if it is too long.
commit=$(git rev-parse --short HEAD)
db_built=$(grype db status -o json | jq -r '.built[:10]')
matches=$(jq '.matches | length' "$out/grype.json")
ignored=$(jq '[.ignoredMatches[]?] | length' "$out/grype.json")
patched=$(jq '.statements | length' "$out/patches.openvex.json")
permanent=$(jq '.statements | length' "$out/triage.openvex.json")
severities=$(jq -r '
  [.matches[].vulnerability.severity]
  | group_by(.) | map("\(length) \(.[0] | ascii_downcase)") | join(", ")
' "$out/grype.json")
by_package=$(jq -r '
  [.matches[].artifact | "\(.name) \(.version)"]
  | group_by(.) | map({ pkg: .[0], n: length }) | sort_by(-.n) | .[:15][]
  | "| `\(.pkg)` | \(.n) |"
' "$out/grype.json")

# Findings that the triage accepts as real, low-risk and unpatched, with
# their expiry. A purl without a version covers every version.
# shellcheck disable=SC2016
accepted_rows=$(jq -r --slurpfile risks "$out/accepted.json" '
  .matches as $m
  | (now | strftime("%Y-%m-%d")) as $today
  | $risks[0][]
  | . as $r
  | [ $m[]
      | select(.vulnerability.id as $id | $r.cves | index($id))
      | select(.artifact.purl as $p | $r.products | any(. == $p or ($p | startswith(. + "@"))))
    ] as $hits
  | select($hits | length > 0)
  | ($r.id | sub("^.*#"; "")) as $name
  | "| `\($hits[0].artifact.name) \($hits[0].artifact.version)` | \($hits | map(.vulnerability.id) | unique | length) | "
    + (if $r.until < $today then "**expired** \($r.until)" else $r.until end)
    + " | [`\($name)`](https://github.com/huwd/declarative_laptop/blob/main/triage/vulnerabilities.ttl) |"
' "$out/grype.json")
accepted_count=$(jq -r --slurpfile risks "$out/accepted.json" '
  [ .matches[] as $x | $risks[0][]
    | select(.cves | index($x.vulnerability.id))
    | select(.products | any(. == $x.artifact.purl or ($x.artifact.purl | startswith(. + "@"))))
    | $x.vulnerability.id + " " + $x.artifact.purl ] | unique | length
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
  echo "### Pinned: this commit's closure"
  echo
  echo "The closure from \`flake.lock\` at \`$commit\`, scanned with the grype database built on $db_built ([pinned]($docs#pinned))."
  echo
  cat "$out/kev.md"
  echo
  echo "**$matches findings** (${severities:-none})."
  echo "VEX removed $ignored more: Nixpkgs patches $patched CVEs, and [the triage](https://github.com/huwd/declarative_laptop/blob/main/docs/vulnerability-triage.md) holds $permanent permanent statements."
  if [ -n "$accepted_rows" ]; then
    echo
    echo "**$accepted_count of these findings are accepted risks** in the triage: real, unpatched and accepted until the date shown. Each statement gives the mitigation."
    echo
    echo "| Package | CVEs | Accepted until | Statement |"
    echo "| --- | --- | --- | --- |"
    echo "$accepted_rows"
  fi
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
  echo
  cat "$out/upstream.md"
} > "$out/comment.md"

echo "grype ($host): $matches findings, $ignored removed by VEX"
