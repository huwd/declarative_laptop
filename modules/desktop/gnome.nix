{ pkgs, ... }:
{
  # Display server + desktop
  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  environment = {
    # Strip default GNOME apps we replace or don't use
    gnome.excludePackages = with pkgs; [
      epiphany # GNOME web — using Firefox/Chrome
      geary # GNOME mail — using Thunderbird
      gnome-music # using Spotify
      gnome-tour
      totem # video player — using VLC
    ];

    # GNOME extensions
    systemPackages = with pkgs; [
      gnomeExtensions.appindicator # system tray (Spotify, Signal, etc.)
      gnomeExtensions.blur-my-shell
      gnomeExtensions.caffeine # inhibit suspend on demand
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.just-perfection # UI density / behaviour tweaks
    ];

    # HiDPI — fractional scaling support under Wayland
    # Set your preferred scale in GNOME Settings → Displays
    # 125% or 150% suits the Framework 13 at 2256×1504
    sessionVariables = {
      NIXOS_OZONE_WL = "1"; # hint Electron/Chrome apps to use Wayland
    };
  };

  # Required for extensions and dconf user settings
  programs.dconf.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono # terminal emulator (see emulator.nix)
      nerd-fonts.fira-code
      nerd-fonts.meslo-lg
      inter # clean sans-serif for UI
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Inter" ];
      serif = [ "DejaVu Serif" ];
    };
  };
}
