{ pkgs, ... }:
{
  # ── Firewall ─────────────────────────────────────────────────────────────────

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ]; # open ports explicitly as needed
    allowedUDPPorts = [ ];
    # Example: allowedTCPPorts = [ 22 443 ];
  };

  # ── Password manager and encrypted dev secrets ───────────────────────────────
  # The age identity for dev secrets is derived from a Bitwarden SSH-agent
  # signature (one Bitwarden approval per use, if set to ask) and never stored.
  # See docs/decisions/0013.
  environment.systemPackages = with pkgs; [
    bitwarden-cli # `bw` — scripting and terminal access to your vault
    # Bitwarden browser extension handles GUI access via Firefox/Chrome
    age # `age-keygen -y` to compute recipients
    sops # `sops updatekeys` and friends, beyond what the wrappers cover
    betterleaks # secret scanner for staged changes and history; see docs/decisions/0014
    (import ../packages/secrets-tools.nix { inherit pkgs; }) # with-secrets, secrets-edit, sops-age-derive
  ];

  # ── SSH ──────────────────────────────────────────────────────────────────────
  # The daemon is disabled: nothing needs inbound SSH, and it removes the
  # sshd exposure behind the openssh finding in vulnix.toml. The openssh package
  # stays in the closure for the ssh client, ssh-keygen and git.
  # To enable it, add a trusted-interface or source-specific firewall rule
  # first; do not open it globally on a roaming laptop. NixOS defaults
  # openFirewall to true, which would silently override the empty
  # allowedTCPPorts list in the firewall config above.
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
    # polkit (Bitwarden biometric unlock, GNOME prompts), sudo and the lock
    # screen (gdm-fingerprint, which NixOS creates). Not used at the login
    # screen: a fingerprint can't unlock the GNOME keyring there, so the
    # password is needed anyway. See docs/decisions/0018.
    pam.services = {
      login.fprintAuth = false;
      gdm-password.fprintAuth = false;
      sudo.fprintAuth = true;
    };

    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };
  };

  services.fprintd.enable = true;

  # The login screen reads this from the gdm dconf profile, the lock screen
  # from the user profile, so this turns fingerprint off at login only.
  programs.dconf.profiles.gdm.databases = [
    {
      settings."org/gnome/login-screen".enable-fingerprint-authentication = false;
    }
  ];
}
