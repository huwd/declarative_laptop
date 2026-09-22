_: {
  # AI coding agents. Updates arrive with the weekly flake update — the
  # nixpkgs claude-code wrapper sets DISABLE_AUTOUPDATER, as the store is
  # read-only.
  # No `settings` here on purpose: each tool writes its own config files
  # (~/.claude/settings.json etc.), and a Home Manager-managed copy would be
  # read-only in the Nix store.
  programs.claude-code.enable = true;
  programs.opencode.enable = true;
  programs.codex.enable = true;
}
