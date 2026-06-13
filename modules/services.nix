{ pkgs, ... }:
{
  hardware = {
    # ── Audio (PipeWire) ──────────────────────────────────────────────────────
    pulseaudio.enable = false; # replaced by PipeWire

    # ── Bluetooth ─────────────────────────────────────────────────────────────
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true; # battery percentage reporting
    };
  };

  services = {
    # ── Audio (PipeWire) ──────────────────────────────────────────────────────
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; # PulseAudio compatibility
      jack.enable = false; # enable if you do pro audio work
    };

    # ── Bluetooth ─────────────────────────────────────────────────────────────
    blueman.enable = true; # GUI Bluetooth manager

    # ── Printing ──────────────────────────────────────────────────────────────
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip # HP printers; swap/remove if not applicable
      ];
    };

    # Network printer discovery — restricted to the local interface only.
    # openFirewall = false avoids exposing mDNS on public wifi networks.
    # If network printing stops working, check the firewall first.
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = false;
    };

    # ── Firmware updates (LVFS) ──────────────────────────────────────────────
    # Run `sudo fwupdmgr update` to apply; Framework releases BIOS/EC updates here
    fwupd.enable = true;

    # ── Power management ─────────────────────────────────────────────────────
    # Do not enable TLP alongside power-profiles-daemon — they conflict
    power-profiles-daemon.enable = true;

    # ── Suspend / lid ─────────────────────────────────────────────────────────
    logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
      extraConfig = ''
        IdleAction=suspend
        IdleActionSec=20min
      '';
    };

    # ── Syncthing ─────────────────────────────────────────────────────────────
    syncthing = {
      enable = true;
      user = "huw";
      dataDir = "/home/huw";
      configDir = "/home/huw/.config/syncthing";
      openDefaultPorts = true; # 22000/tcp, 21027/udp
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

    # ── Flatpak ───────────────────────────────────────────────────────────────
    # Safety valve for apps not in nixpkgs. Keep the footprint small.
    # Flatpak apps are outside the Nix store and therefore outside vulnix —
    # see OPSEC.md for the residual risk and mitigations.
    flatpak.enable = true;
  };

  # ── Flatpak automation ───────────────────────────────────────────────────────
  systemd = {
    services = {
      # Automatic Flatpak updates — runs weekly, keeps runtimes and apps current
      flatpak-update = {
        description = "Update Flatpak runtimes and applications";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.flatpak}/bin/flatpak update --noninteractive";
        };
      };

      # grype — CVE scan of Flatpak runtimes after each update
      # Covers runtime-level vulnerabilities; individual app internals vary.
      # Results land in the journal: journalctl -u flatpak-scan
      flatpak-scan = {
        description = "Scan Flatpak installation for CVEs (grype)";
        after = [ "flatpak-update.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.grype}/bin/grype dir:/var/lib/flatpak --output table";
        };
      };
    };

    timers = {
      flatpak-update = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true; # catch up if the machine was off
        };
      };

      flatpak-scan = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };
    };
  };

  # ── Timezone + locale ────────────────────────────────────────────────────────
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  environment.systemPackages = [ pkgs.grype ];
}
