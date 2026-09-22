_: {
  # Steam — the NixOS module (not just the package) also enables 32-bit
  # graphics drivers and the FHS runtime that Steam and Proton need.
  # Firewall stays closed: set remotePlay.openFirewall / localNetworkGameTransfers
  # .openFirewall = true if Remote Play or LAN game transfers are wanted.
  programs.steam.enable = true;
}
