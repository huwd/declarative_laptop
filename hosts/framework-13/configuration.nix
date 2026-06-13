{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop/gnome.nix
    ../../modules/apps.nix
    ../../modules/development/default.nix
    ../../modules/security.nix
    ../../modules/services.nix
  ];

  # ── Nixpkgs ──────────────────────────────────────────────────────────────────

  nixpkgs.config.allowUnfree = true;

  # ── Boot ─────────────────────────────────────────────────────────────────────

  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Latest kernel — required for Strix Point (AMD Ryzen AI 300) hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Force s2idle suspend (modern standby) — recommended for Framework on AMD
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # ── Network ──────────────────────────────────────────────────────────────────

  networking.hostName = "framework-13";
  networking.networkmanager.enable = true;

  # ── User ─────────────────────────────────────────────────────────────────────

  users.users.huw = {
    isNormalUser = true;
    description  = "Huw";
    shell        = pkgs.zsh;
    extraGroups  = [
      "wheel"           # sudo
      "networkmanager"  # manage wifi without sudo
      "docker"          # docker without sudo
      "audio"
      "video"
    ];
  };

  # Required for zsh to be a valid login shell
  programs.zsh.enable = true;

  # ── Nix daemon ───────────────────────────────────────────────────────────────

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 30d";
  };

  # ── State version ────────────────────────────────────────────────────────────
  # Set to the NixOS version at time of install. Do not update this value.

  system.stateVersion = "25.05";
}
