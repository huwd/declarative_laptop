# The documentation site, built with Zola from this repository's Markdown.
# `nix build .#docs-site` leaves the finished site in ./result.
#
# scripts/build-site-content.py copies the Markdown into Zola's layout and
# rewrites relative links to Zola's @/ links; Zola then fails the build if any
# internal link doesn't resolve.
{
  pkgs,
  baseUrl ? "https://huwd.github.io/declarative_laptop",
}:
let
  root = ../.;
  fs = pkgs.lib.fileset;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "docs-site";
  version = "0";

  # Only the files the site is built from, so unrelated changes don't rebuild it.
  src = fs.toSource {
    inherit root;
    fileset = fs.unions [
      (root + "/site")
      (root + "/scripts/build-site-content.py")
      (root + "/docs")
      (root + "/README.md")
      (root + "/CLAUDE.md")
      (root + "/HARDWARE.md")
      (root + "/OPSEC.md")
    ];
  };

  nativeBuildInputs = [
    pkgs.python3
    pkgs.zola
  ];

  # Zola creates an HTTP client at start-up and panics without CA certificates,
  # even though this build makes no network requests.
  env.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  buildPhase = ''
    runHook preBuild
    python3 scripts/build-site-content.py . site/content
    zola --root site build --base-url ${baseUrl} --output-dir "$PWD/public"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r public $out
    runHook postInstall
  '';
}
