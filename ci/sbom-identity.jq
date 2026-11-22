# Give grype the package identities it needs (ADR 0027, E).
#
#   jq -f ci/sbom-identity.jq sbom.cdx.json > sbom.identity.cdx.json
#
# sbomnix guesses each CPE and purl from the Nix name, and grype has no
# NixOS data, so a package whose Nix name differs from its upstream name
# matches nothing. This rewrites two kinds:
#
#   python3.14-nltk     a PyPI package: name nltk, purl pkg:pypi/nltk@<version>,
#                       and no CPE, so grype matches it against GitHub's
#                       advisories for PyPI
#   ffmpeg-headless     a variant of ffmpeg: keep its name and purl, so the
#                       triage can tell the builds apart, and give it ffmpeg's
#                       CPE at its own version
#
# A variant takes the base package's CPE when the base is in the SBOM,
# because sbomnix knows some vendors (git is git-scm:git). Otherwise it
# takes the CPE sbomnix guessed, with the suffix removed. Each rewritten
# component keeps its Nix name in the property declarative-laptop:nix-name.

def pypi_name: ascii_downcase | gsub("[-_.]+"; "-");

def variant_suffix: "-(headless|minimal|unwrapped|full|wrapped|nox|small)$";

def note($name): .properties = ((.properties // []) + [{ name: "declarative-laptop:nix-name", value: $name }]);

# The CPE of each name in the SBOM, without its version.
([.components[] | select(.cpe) | { key: .name, value: (.cpe | split(":")) }] | from_entries) as $cpes
| .components |= map(
    .name as $name
    | if ($name | test("^python3\\.[0-9]+-[A-Za-z]")) and ((.version // "") | test("^[0-9]")) then
        ($name | sub("^python3\\.[0-9]+-"; "")) as $pkg
        | note($name)
        | .name = $pkg
        | .purl = "pkg:pypi/\($pkg | pypi_name)@\(.version)"
        | del(.cpe)
      elif ($name | test(variant_suffix)) and .cpe then
        ($name | sub(variant_suffix; "")) as $base
        | (.cpe | split(":")) as $own
        | ($cpes[$base] // ($own | .[3] = $base | .[4] = $base)) as $parts
        | note($name)
        | .cpe = ($parts | .[5] = $own[5] | join(":"))
      else
        .
      end
  )
