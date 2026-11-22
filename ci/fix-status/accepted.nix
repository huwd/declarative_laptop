# Which grype findings the triage accepts as risks (ADR 0027, A).
#
#   (import ./accepted.nix path).isAccepted "pkg:nix/binutils@2.46" "CVE-2026-6846"
#
# `path` is accepted.json, compiled from triage/vulnerabilities.ttl by
# `nix build .#vuln-triage`, or null for none. Each accepted risk names its
# products as purls. A purl without a version covers every version of the
# package: the same rule grype applies to the triage's VEX statements, and
# the comment's accepted-risk table in ci/grype-scan.sh.
path:
let
  inherit (builtins)
    any
    elem
    fromJSON
    readFile
    stringLength
    substring
    ;

  risks = if path == null then [ ] else fromJSON (readFile path);

  covers =
    product: purl: product == purl || substring 0 (stringLength product + 1) purl == "${product}@";
in
{
  isAccepted =
    purl: cve: any (r: elem cve r.cves && any (product: covers product purl) r.products) risks;
}
