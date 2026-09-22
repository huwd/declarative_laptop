_: {
  # AI coding agents (Claude Code is installed via npm; see modules/development).
  # No `settings` here on purpose: both tools write their own config files,
  # and a Home Manager-managed copy would be read-only in the Nix store.
  programs.opencode.enable = true;
  programs.codex.enable = true;
}
