# git-sign-off: sign off and sign an agent's commits, push the branch and
# mark its pull request ready. Git runs it as `git sign-off`.
# See docs/decisions/0022 for the design. `nix build .#git-sign-off` builds
# it, running shellcheck over the script.
{ pkgs }:
pkgs.writeShellApplication {
  name = "git-sign-off";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gh
    pkgs.git
    pkgs.gnugrep
  ];
  text = builtins.readFile ./git-sign-off/git-sign-off.sh;
}
