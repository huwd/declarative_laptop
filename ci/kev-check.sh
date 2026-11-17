#!/usr/bin/env bash
# Cross-reference scan findings and triage with CISA's Known Exploited
# Vulnerabilities (KEV) catalogue (ADR 0019).
#
# Usage: ci/kev-check.sh <output-dir>
#
# ci/grype-scan.sh calls this after grype. Run it from the repository root:
# it reads <output-dir>/grype.json and <output-dir>/patches.openvex.json
# from that script, plus vulnix.toml and openvex.json.
#
# A CVE in KEV is being exploited in the wild. The check flags:
#   - open grype findings in KEV
#   - triage entries (vulnix.toml, openvex.json) for a CVE in KEV whose
#     justification does not mention KEV, so the decision predates it
#   - accepted risks (vulnix.toml entries with `until`) in KEV that have
#     not been reviewed against it, or whose `until` runs past KEV's due date
# Triage that mentions KEV, and CVEs that Nixpkgs patches, are listed as
# already reviewed.
#
# Writes to <output-dir>:
#   kev.json         the KEV feed, as downloaded
#   kev-hits.json    every match, with "attention": true for those flagged
#   kev.md           section for the pull request comment
#
# In GitHub Actions it also prints a "CISA KEV" warning annotation for each
# flagged match. It never fails because of a match: the check is advisory.
set -euo pipefail

out=$1
url=https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json
in_ci=${GITHUB_ACTIONS:-false}

if ! curl -sSfL --retry 3 -o "$out/kev.json" "$url"; then
  printf '> [!WARNING]\n> CISA KEV check skipped: the feed could not be downloaded.\n' > "$out/kev.md"
  if [ "$in_ci" = true ]; then
    echo "::warning title=CISA KEV::KEV check skipped: the feed could not be downloaded"
  fi
  exit 0
fi

# vulnix.toml is TOML, which jq cannot read; Nix can.
nix eval --impure --json \
  --expr 'builtins.fromTOML (builtins.readFile ./vulnix.toml)' \
  > "$out/vulnix-whitelist.json"

jq -n \
  --slurpfile kev "$out/kev.json" \
  --slurpfile grype "$out/grype.json" \
  --slurpfile patches "$out/patches.openvex.json" \
  --slurpfile vex openvex.json \
  --slurpfile wl "$out/vulnix-whitelist.json" '
  ($kev[0].vulnerabilities | map({ key: .cveID, value: . }) | from_entries) as $k
  | def text: if type == "array" then join(" ") else (. // "") end;
    def mentions_kev: text | test("\\bKEV\\b");
    def cves: if type == "array" then .[] else . end;
  [
    ($grype[0].matches[]
      | { package: "\(.artifact.name) \(.artifact.version)", cve: .vulnerability.id,
          attention: true, reason: "open grype finding" }),

    ($patches[0].statements[]
      | { package: .products[0]["@id"], cve: .vulnerability.name,
          attention: false, reason: "patched in Nixpkgs" }),

    ($vex[0].statements[]
      | ([.status_notes, .impact_statement, .action_statement] | map(text) | join(" ") | mentions_kev) as $ack
      | { package: (.products | map(.["@id"]) | join(", ")), cve: .vulnerability.name,
          attention: ($ack | not),
          reason: (if $ack then "openvex.json \(.status), reviewed against KEV"
                   else "openvex.json \(.status), justification does not mention KEV" end) }),

    ($wl[0] | to_entries[]
      | .key as $pkg | .value as $e | ($e.comment | mentions_kev) as $ack
      | $e.cve | cves
      | . as $cve
      | ($k[$cve].dueDate // "") as $due
      | { package: $pkg, cve: $cve, until: $e.until,
          attention: ((($ack | not)) or ($e.until != null and $due != "" and $e.until > $due)),
          reason: (
            if $e.until != null and $due != "" and $e.until > $due
              then "accepted risk until \($e.until), after the KEV due date"
            elif $e.until != null and ($ack | not)
              then "accepted risk, not reviewed against KEV"
            elif ($ack | not)
              then "whitelisted in vulnix.toml, comment does not mention KEV"
            else "whitelisted in vulnix.toml, reviewed against KEV" end) })
  ]
  | map(select($k[.cve]) + { added: $k[.cve].dateAdded, due: $k[.cve].dueDate })
  | unique_by([.package, .cve, .reason])
  | sort_by([(.attention | not), .added])
  | { catalogue: $kev[0].catalogVersion, hits: . }
' > "$out/kev-hits.json"

catalogue=$(jq -r '.catalogue' "$out/kev-hits.json")
flagged=$(jq '[.hits[] | select(.attention)] | length' "$out/kev-hits.json")
reviewed=$(jq '[.hits[] | select(.attention | not)] | length' "$out/kev-hits.json")
# A jq expression, so the single quotes are deliberate.
# shellcheck disable=SC2016
row='"| `\(.package)` | [\(.cve)](https://nvd.nist.gov/vuln/detail/\(.cve)) | \(.reason) | \(.added) | \(.due) |"'

{
  if [ "$flagged" -gt 0 ]; then
    echo "> [!CAUTION]"
    echo "> **CISA KEV: $flagged known-exploited CVE matches need attention** (catalogue $catalogue)."
    echo "> Each one is being exploited in the wild. Fix it, or re-triage it and mention KEV in the justification."
    echo
    echo "| Package | CVE | Why flagged | In KEV since | KEV due |"
    echo "| --- | --- | --- | --- | --- |"
    jq -r ".hits[] | select(.attention) | $row" "$out/kev-hits.json"
  else
    echo "**CISA KEV:** nothing needs attention (catalogue $catalogue)."
  fi
  if [ "$reviewed" -gt 0 ]; then
    echo
    echo "<details><summary>CISA KEV: $reviewed matches already patched or reviewed</summary>"
    echo
    echo "| Package | CVE | Status | In KEV since | KEV due |"
    echo "| --- | --- | --- | --- | --- |"
    jq -r ".hits[] | select(.attention | not) | $row" "$out/kev-hits.json"
    echo
    echo "</details>"
  fi
} > "$out/kev.md"

if [ "$in_ci" = true ]; then
  jq -r '.hits[] | select(.attention)
    | "::warning title=CISA KEV::\(.cve) in \(.package) is a known exploited vulnerability: \(.reason) (in KEV since \(.added))"' \
    "$out/kev-hits.json"
fi

echo "CISA KEV ($catalogue): $flagged need attention, $reviewed already reviewed"
