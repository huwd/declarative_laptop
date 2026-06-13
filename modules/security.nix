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
  services.openssh = {
    enable = true;
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
