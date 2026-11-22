# What Debian's security tracker records for each grype finding (ADR 0027, B).
#
#   (import ./debian.nix path).verdict "pkg:nix/binutils@2.46" "CVE-2025-69649"
#
# `path` is debian.json from ci/evidence/debian.py, or null for none.
# Each entry is keyed by the finding's purl and grype's vulnerability ID,
# which can be a GitHub advisory with the CVE as a related ID. The verdict
# is evidence, not proof: the classifier shows it beside a finding and
# never changes the finding's bucket because of it.
path:
let
  inherit (builtins)
    fromJSON
    listToAttrs
    readFile
    ;

  entries = if path == null then [ ] else fromJSON (readFile path);

  verdicts = listToAttrs (
    map (e: {
      name = "${e.purl} ${e.finding}";
      value = e.verdict;
    }) entries
  );
in
{
  # One of fixed-upstream, fixed-debian, fixed-later, not-affected,
  # unimportant or open, or null when Debian has no entry.
  verdict = purl: id: verdicts."${purl} ${id}" or null;
}
