# Vale bundled with its styles, so `nix run .#vale` needs no `vale sync`.
# Mirrors nixpkgs' vale.withStyles, plus this repo's own styles under
# .vale/styles and the en_GB Hunspell dictionary for British spelling.
{ pkgs }:
pkgs.symlinkJoin {
  name = "vale-with-house-styles-${pkgs.vale.version}";
  paths = [
    pkgs.vale
    pkgs.valeStyles.write-good
    pkgs.valeStyles.proselint
  ];
  nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
  postBuild = ''
    styles=$out/share/vale/styles
    cp -r --no-preserve=mode ${../.vale/styles}/. $styles/
    mkdir -p $styles/config/dictionaries
    ln -s ${pkgs.hunspellDicts.en_GB-ise}/share/hunspell/en_GB.{aff,dic} $styles/config/dictionaries/
    wrapProgram $out/bin/vale --set VALE_STYLES_PATH $styles
  '';
  meta.mainProgram = "vale";
}
