# Which grype findings have a fix commit upstream that isn't in our release
# (ADR 0027, C).
#
#   (import ./commits.nix path).isFixedAfter "pkg:nix/ffmpeg@9.0.2" "CVE-2026-125210"
#
# `path` is commits.json from ci/evidence/commits.py, or null for none. Its
# in-release entries are proofs, which grype's second pass has already
# removed, so only the not-in-release entries matter here. They are
# evidence, not proof: a fix backported under another commit lands here too.
path:
let
  inherit (builtins)
    filter
    fromJSON
    listToAttrs
    readFile
    ;

  entries = if path == null then [ ] else fromJSON (readFile path);

  fixedAfter = listToAttrs (
    map (e: {
      name = "${e.purl} ${e.cve}";
      value = true;
    }) (filter (e: e.status == "not-in-release") entries)
  );
in
{
  isFixedAfter = purl: cve: fixedAfter ? "${purl} ${cve}";
}
