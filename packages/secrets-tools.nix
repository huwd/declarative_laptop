# Tools for encrypted dev secrets: with-secrets, secrets-edit and sops-age-derive.
# See docs/decisions/0013 for the design. `nix build .#secrets-tools` builds all
# three, and the build runs sops-age-derive's unit tests (including its golden
# vector) and shellcheck over the scripts.
{ pkgs }:
let
  # Prints an age identity derived from an SSH-agent signature. ssh-keygen is
  # put on its PATH so it works wherever it is called from.
  sops-age-derive = pkgs.stdenvNoCC.mkDerivation {
    pname = "sops-age-derive";
    version = "1";

    src = ./sops-age-derive;

    nativeBuildInputs = [
      pkgs.python3
      pkgs.makeBinaryWrapper
    ];

    doCheck = true;
    nativeCheckInputs = [
      pkgs.age
      pkgs.openssl
    ];
    checkPhase = ''
      runHook preCheck
      python3 -I -m unittest discover -s . -p 'test_*.py'
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 sops-age-derive.py $out/bin/sops-age-derive
      wrapProgram $out/bin/sops-age-derive \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.openssh ]}
      runHook postInstall
    '';

    meta.mainProgram = "sops-age-derive";
  };

  with-secrets = pkgs.writeShellApplication {
    name = "with-secrets";
    runtimeInputs = [
      pkgs.git
      pkgs.sops
      sops-age-derive
    ];
    text = builtins.readFile ./secrets-tools/with-secrets.sh;
  };

  secrets-edit = pkgs.writeShellApplication {
    name = "secrets-edit";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.sops
      sops-age-derive
    ];
    text = builtins.readFile ./secrets-tools/secrets-edit.sh;
  };
in
pkgs.symlinkJoin {
  name = "secrets-tools";
  paths = [
    sops-age-derive
    with-secrets
    secrets-edit
  ];
  meta.mainProgram = "with-secrets";
}
