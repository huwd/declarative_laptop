{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    google-chrome

    # Communication
    signal-desktop

    # Notes
    obsidian

    # Password manager (desktop app — browser extension is primary)
    bitwarden-desktop
  ];
}
