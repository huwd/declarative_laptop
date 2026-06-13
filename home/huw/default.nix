{ ... }:
{
  imports = [
    ../../terminal/default.nix
  ];

  home.username    = "huw";
  home.homeDirectory = "/home/huw";

  # Set to the home-manager release at time of setup. Do not update this value.
  home.stateVersion = "25.05";

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
