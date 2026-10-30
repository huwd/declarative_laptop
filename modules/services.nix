_: {
  hardware = {
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
    pulseaudio.enable = false; # replaced by PipeWire

    # ── Bluetooth ─────────────────────────────────────────────────────────────
    blueman.enable = true; # GUI Bluetooth manager

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
      settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        IdleAction = "suspend";
        IdleActionSec = "20min";
      };
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
  };

  # ── Timezone + locale ────────────────────────────────────────────────────────
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Host aliases ─────────────────────────────────────────────────────────────
  # Declarative /etc/hosts — NixOS regenerates this file on every rebuild, so
  # hand edits get silently wiped. Add remote machines here instead.
  networking.hosts = {
    "192.168.178.43" = [
      "pi4"
      "pi4.local"
    ];
    "192.168.178.109" = [
      "nas"
      "nas.local"
    ];
  };
}
