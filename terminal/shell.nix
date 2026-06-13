_: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
    };

    shellAliases = {
      # File listing — eza replaces ls/ll from dotfiles
      ls = "eza --color=auto --group-directories-first";
      ll = "eza -alh --color=auto --group-directories-first --git";
      lsg = "ll | grep";
      lh = "eza -alh --sort=modified | head";

      # Core utils
      df = "df -h";
      du = "du -h -d 2";
      l = "bat --paging=auto";
      less = "bat --paging=always";
      tf = "tail -f";
      cl = "clear";
      gz = "tar -zcvf";

      # Vi muscle memory
      ":q" = "exit";

      # Git
      gs = "git status";
      glg = "git l";
      gps = "git push";
      gpsh = "git push -u origin HEAD";

      # Nix shortcuts
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nixos-config#framework-13";
      hms = "home-manager switch --flake ~/.config/nixos-config#framework-13";
      nfu = "nix flake update";
    };

    initContent = ''
      # (f)ind by (n)ame — ported from dotfiles
      function fn() { ls **/*$1* }

      # zoxide — smarter cd; use 'z' to jump, 'zi' for interactive
      eval "$(zoxide init zsh)"

      # fzf shell integration — Ctrl-R for fuzzy history
      source <(fzf --zsh)
    '';
  };

  # direnv — auto-activates nix dev shells on cd
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
