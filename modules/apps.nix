{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Browsers
    # firefox — managed by Home Manager (home/huw/browser.nix) with declared extensions
    google-chrome   # compatibility only; zero extensions policy

    # Communication
    signal-desktop

    # Notes
    obsidian

    # Password manager (desktop app — browser extension is primary)
    bitwarden-desktop
  ];
}
