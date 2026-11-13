_: {
  # ── immurok fingerprint key ──────────────────────────────────────────────────
  # Runs the daemon, its system user, the D-Bus policy and the session agent.
  # Deliberately no PAM rule yet: enabling this can't change how sudo, polkit
  # or login work. Pair the key and enrol a finger first; the PAM rules come
  # later, in modules/security.nix next to the fprintd settings.
  # The module is declared in the immurok input (flake.nix), for framework-13
  # only.
  services.immurok.enable = true;
}
