{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Browsers
    # firefox — managed by Home Manager (home/huw/browser.nix) with declared extensions
    google-chrome # compatibility only; zero extensions policy

    # Communication
    signal-desktop

    # Music
    spotify

    # Notes
    obsidian

    # Password manager (desktop app — browser extension is primary)
    bitwarden-desktop
  ];

  # SSH agent — Bitwarden holds the key and prompts on every use,
  # so nothing on disk (or running as huw) can use it silently.
  services.gnome.gcr-ssh-agent.enable = false;
  environment.sessionVariables.SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
}
