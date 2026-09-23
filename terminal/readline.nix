_: {
  # vi keybindings for GNU readline programs (psql, python REPL, irb, ...),
  # ported from dotfiles' vimify/inputrc. zsh has its own line editor and
  # isn't affected by this.
  programs.readline = {
    enable = true;
    variables."editing-mode" = "vi";
  };
}
