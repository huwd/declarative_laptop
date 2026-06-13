_: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Powerline-style left prompt — agnoster lineage
      format = "$directory$git_branch$git_status$nix_shell$jobs$character";

      directory = {
        style = "bg:blue fg:black bold";
        format = "[ $path ]($style)";
        truncation_length = 4;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bg:purple fg:white bold";
        format = "[ $symbol$branch ]($style)";
        symbol = " ";
      };

      git_status = {
        style = "bg:purple fg:yellow bold";
        format = "[$all_status$ahead_behind]($style)";
        conflicted = "!";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        stashed = "$";
        modified = "~";
        staged = "+";
        deleted = "✘";
      };

      nix_shell = {
        style = "bg:teal fg:black bold";
        format = "[ nix:$name ]($style)";
        # Only shows when inside a nix shell / devenv
        heuristic = true;
      };

      jobs = {
        style = "bold yellow";
        format = "[$symbol$number]($style) ";
        symbol = "⚙ ";
        number_threshold = 1;
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };

      # Disable modules we replace with nix shells
      ruby.disabled = true;
      python.disabled = true;
      nodejs.disabled = true;
    };
  };
}
