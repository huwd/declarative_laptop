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
      # home-manager is wired as a NixOS module (see flake.nix), not the
      # standalone CLI — nrs applies both system and home-manager config.
      # nixos-rebuild picks nixosConfigurations.<hostname> when no #host is given
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nixos-config";
      nfu = "nix flake update";
      # Run justfile recipes from anywhere: nx diff, nx apply, nx update
      nx = "just --justfile ~/.config/nixos-config/justfile --working-directory ~/.config/nixos-config";
    };

    initContent = ''
      # (f)ind by (n)ame — ported from dotfiles
      function fn() { ls **/*$1* }

      # ~nix — named directory for this repo: cd ~nix, nvim ~nix/modules/apps.nix
      hash -d nix=~/.config/nixos-config

      # zoxide — smarter cd; use 'z' to jump, 'zi' for interactive
      eval "$(zoxide init zsh)"

      # fzf shell integration — Ctrl-R for fuzzy history
      source <(fzf --zsh)

      # npm global installs (ad-hoc CLIs; AI agents come from Nix via
      # ai-agents.nix) — nix store and system
      # paths are read-only, so npm's global prefix points here instead.
      # One-time setup: npm config set prefix "$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
  };

  # direnv — auto-activates nix dev shells on cd
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
