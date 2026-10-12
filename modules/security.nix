{ pkgs, ... }:
{
  # ── Firewall ─────────────────────────────────────────────────────────────────

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ]; # open ports explicitly as needed
    allowedUDPPorts = [ ];
    # Example: allowedTCPPorts = [ 22 443 ];
  };

  # ── Secrets management ───────────────────────────────────────────────────────
  # agenix is wired at the flake level (see flake.nix + secrets/)
  # Secrets are decrypted at activation using the host SSH key

  # ── Password manager ─────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    bitwarden-cli # `bw` — scripting and terminal access to your vault
    # Bitwarden browser extension handles GUI access via Firefox/Chrome
  ];

  # ── SSH ──────────────────────────────────────────────────────────────────────
  # The daemon is disabled: nothing needs inbound SSH, and it removes the
  # sshd exposure behind the openssh finding in vulnix.toml. The openssh package
  # stays in the closure for the ssh client, ssh-keygen and git.
  # To enable it, add a trusted-interface or source-specific firewall rule
  # first; do not open it globally on a roaming laptop. NixOS defaults
  # openFirewall to true, which would silently override the empty
  # allowedTCPPorts list in the firewall config above.
  # Without the daemon nothing generates the host key agenix decrypts with;
  # see "Bootstrap agenix" in docs/setup.md.
  services.openssh = {
    enable = false;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  # ── Kernel hardening ─────────────────────────────────────────────────────────
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.kptr_restrict" = 2;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
  };

  # ── Polkit, PAM and sudo ─────────────────────────────────────────────────────
  security = {
    polkit.enable = true;

    # Fingerprint (Goodix MOC sensor, via services.fprintd below) is used by
    # polkit (Bitwarden biometric unlock, GNOME prompts) and sudo. Deliberately
    # not used for login: a fingerprint can't unlock the GNOME keyring, so the
    # password is needed there anyway.
    pam.services = {
      login.fprintAuth = false;
      gdm-password.fprintAuth = false;
      gdm-fingerprint.enable = false;
      sudo.fprintAuth = true;
    };

    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };

  services.fprintd.enable = true;
}
