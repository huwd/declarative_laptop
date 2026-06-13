{ pkgs, ... }:
{
  # ── Firewall ─────────────────────────────────────────────────────────────────

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];   # open ports explicitly as needed
    allowedUDPPorts = [];
    # Example: allowedTCPPorts = [ 22 443 ];
  };

  # ── Secrets management ───────────────────────────────────────────────────────
  # agenix is wired at the flake level (see flake.nix + secrets/)
  # Secrets are decrypted at activation using the host SSH key

  # ── Password manager ─────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    bitwarden-cli   # `bw` — scripting and terminal access to your vault
    # Bitwarden browser extension handles GUI access via Firefox/Chrome
  ];

  # ── SSH ──────────────────────────────────────────────────────────────────────
  # Enabled for remote access, but NOT exposed through the firewall.
  # openFirewall = false means port 22 is only reachable via a trusted network
  # (Tailscale, home LAN) — not from public wifi.
  # NixOS defaults openFirewall to true, which would silently override the
  # empty allowedTCPPorts list in the firewall config above.
  services.openssh = {
    enable = true;
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

  # ── Polkit ───────────────────────────────────────────────────────────────────
  security.polkit.enable = true;

  # ── Sudo ─────────────────────────────────────────────────────────────────────
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
