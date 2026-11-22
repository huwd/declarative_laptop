# Classify each grype finding by where a fix exists (ADR 0026).
#
#   nix eval --impure --json --expr \
#     "import ./ci/fix-status.nix { grype = $PWD/grype-report/grype.json; head = $PWD/grype-report/upstream.cdx.json; }"
#
# `grype` is grype's JSON report for the pinned closure. `head` is a
# CycloneDX SBOM, from sbomnix, of the same host evaluated against the
# nixos-unstable head. Each finding gets one bucket:
#
#   actionable  the head patches this CVE, or has a version at or above
#               grype's fixed version: `just update` picks the fix up
#   pending     grype knows a fixed version, but the head doesn't have it
#   no-fix      grype says upstream has no fix
#   unknown     grype has no fix information
#
# The head can hold several versions of a package, such as two Python
# minor versions. Each finding is compared with the closest version at or
# above the pinned one, so a fix in an unrelated major version doesn't count.
# Versions are compared with builtins.compareVersions, as Nixpkgs does.
{ grype, head }:
let
  inherit (builtins)
    any
    compareVersions
    elem
    filter
    fromJSON
    groupBy
    readFile
    sort
    ;

  report = fromJSON (readFile grype);
  sbom = fromJSON (readFile head);

  components = groupBy (c: c.name) (sbom.components or [ ]);
  ofName = name: components.${name} or [ ];

  earliest =
    versions:
    if versions == [ ] then null else builtins.head (sort (a: b: compareVersions a b < 0) versions);

  patchedAtHead =
    name: cve:
    any (c: any (p: any (r: (r.id or "") == cve) (p.resolves or [ ])) (c.pedigree.patches or [ ])) (
      ofName name
    );

  classify =
    match:
    let
      name = match.artifact.name;
      version = match.artifact.version;
      cve = match.vulnerability.id;
      fix = match.vulnerability.fix or { };
      state = fix.state or "";
      fixedIn = earliest (filter (f: compareVersions f version > 0) (fix.versions or [ ]));
      atHead = earliest (
        filter (v: compareVersions v version >= 0) (map (c: c.version or "") (ofName name))
      );
      bucket =
        if patchedAtHead name cve then
          "actionable"
        else if state == "fixed" then
          if fixedIn != null && atHead != null && compareVersions atHead fixedIn >= 0 then
            "actionable"
          else
            "pending"
        else if
          elem state [
            "not-fixed"
            "wont-fix"
          ]
        then
          "no-fix"
        else
          "unknown";
    in
    {
      package = name;
      inherit
        version
        cve
        bucket
        fixedIn
        atHead
        ;
    };
in
map classify report.matches
