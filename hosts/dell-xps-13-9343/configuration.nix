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

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-39.8.10" ];
  };

  # ── Boot ─────────────────────────────────────────────────────────────────────

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # Broadwell (5th-gen Intel) is well-supported by the LTS kernel;
    # linuxPackages_latest is not required here unlike the AMD Strix Point machine.
    kernelPackages = pkgs.linuxPackages;
  };

  # ── Network ──────────────────────────────────────────────────────────────────

  networking = {
    hostName = "dell-xps-13-9343";
    networkmanager.enable = true;
  };

  # ── Hardware ─────────────────────────────────────────────────────────────────

  hardware.cpu.intel.updateMicrocode = true;

  # ── User ─────────────────────────────────────────────────────────────────────

  users.users.huw = {
    isNormalUser = true;
    description = "Huw";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
    ];
  };

  programs.zsh.enable = true;

  # ── Nix daemon ───────────────────────────────────────────────────────────────

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # ── State version ────────────────────────────────────────────────────────────
  # Set to the NixOS version at time of install. Do not update this value.

  system.stateVersion = "25.05";
}
