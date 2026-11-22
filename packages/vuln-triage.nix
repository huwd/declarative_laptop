# vuln-triage: validate triage/vulnerabilities.ttl against triage/shapes.ttl
# and compile it into each scanner's format (ADR 0024).
#
#   nix build .#vuln-triage      # result/vulnix.toml
#
# The build fails, printing the SHACL report, if a statement breaks the
# triage rules.
{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [
    ps.pyshacl
    ps.rdflib
  ]);
in
pkgs.runCommand "vuln-triage"
  {
    nativeBuildInputs = [ python ];
    src = ../triage;
  }
  ''
    python ${./vuln-triage/compile.py} "$src/vulnerabilities.ttl" "$src/shapes.ttl" "$out"
  ''
