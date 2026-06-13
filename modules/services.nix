{ pkgs, ... }:
{
  # ── Audio (PipeWire) ─────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;      # PulseAudio compatibility
    jack.enable = false;      # enable if you do pro audio work
  };
  hardware.pulseaudio.enable = false;   # replaced by PipeWire

  # ── Bluetooth ────────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;   # battery percentage reporting
  };
  services.blueman.enable = true;   # GUI Bluetooth manager

  # ── Printing ─────────────────────────────────────────────────────────────────
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      hplip       # HP printers; swap/remove if not applicable
    ];
  };
  # Network printer discovery — restricted to the local interface only.
  # openFirewall = false avoids exposing mDNS on public wifi networks.
  # If network printing stops working, check the firewall first.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = false;
  };

  # ── Firmware updates (LVFS) ──────────────────────────────────────────────────
  services.fwupd.enable = true;
  # Run `sudo fwupdmgr update` to apply; Framework releases BIOS/EC updates here

  # ── Power management ─────────────────────────────────────────────────────────
  services.power-profiles-daemon.enable = true;
  # Do not enable TLP alongside power-profiles-daemon — they conflict

  # ── Suspend / lid ────────────────────────────────────────────────────────────
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    extraConfig = ''
      IdleAction=suspend
      IdleActionSec=20min
    '';
  };

  # ── Timezone + locale ────────────────────────────────────────────────────────
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Syncthing ────────────────────────────────────────────────────────────────
  services.syncthing = {
    enable = true;
    user = "huw";
    dataDir = "/home/huw";
    configDir = "/home/huw/.config/syncthing";
    openDefaultPorts = true;   # 22000/tcp, 21027/udp
    # Currently managed via web UI at localhost:8384
    #
    # To go declarative, add a settings block — example shape:
    #
    # settings = {
    #   devices = {
    #     phone = { id = "XXXXXXX-..."; name = "Pixel"; };
    #     nas   = { id = "XXXXXXX-..."; name = "NAS"; };
    #   };
    #   folders = {
    #     "~/Documents" = {
    #       id      = "documents";
    #       devices = [ "phone" "nas" ];
    #     };
    #   };
    # };
    #
    # Device IDs are shown in the web UI under Actions → Show ID.
    # Committing them here makes every rebuild reproduce the full sync topology.
  };

  # ── Flatpak ──────────────────────────────────────────────────────────────────
  # Safety valve for apps not in nixpkgs. Keep the footprint small.
  # Flatpak apps are outside the Nix store and therefore outside vulnix —
  # see OPSEC.md for the residual risk and mitigations.
  services.flatpak.enable = true;

  # Automatic Flatpak updates — runs weekly, keeps runtimes and apps current
  systemd.services.flatpak-update = {
    description = "Update Flatpak runtimes and applications";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.flatpak}/bin/flatpak update --noninteractive";
    };
  };
  systemd.timers.flatpak-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;     # catch up if the machine was off
    };
  };

  # grype — CVE scan of Flatpak runtimes after each update
  # Covers runtime-level vulnerabilities; individual app internals vary.
  # Results land in the journal: journalctl -u flatpak-scan
  systemd.services.flatpak-scan = {
    description = "Scan Flatpak installation for CVEs (grype)";
    after = [ "flatpak-update.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.grype}/bin/grype dir:/var/lib/flatpak --output table";
    };
  };
  systemd.timers.flatpak-scan = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  environment.systemPackages = [ pkgs.grype ];
}
