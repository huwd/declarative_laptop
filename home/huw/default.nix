_:
{
  imports = [
    ../../terminal/default.nix
    ./browser.nix
  ];

  home = {
    username = "huw";
    homeDirectory = "/home/huw";
    # Set to the home-manager release at time of setup. Do not update this value.
    stateVersion = "25.05";
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
