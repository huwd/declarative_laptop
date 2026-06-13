{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Modern CLI replacements
    eza          # ls — declared in shell.nix aliases
    bat          # cat/less — declared in shell.nix aliases
    ripgrep      # grep
    fd           # find
    fzf          # fuzzy finder — shell integration in shell.nix
    zoxide       # smart cd — init in shell.nix

    # Nix-specific tooling
    nvd          # diff between NixOS generations
    nix-tree     # visual TUI of the nix dependency closure
    vulnix       # CVE scanner for the nix store

    # General utils worth having
    jq           # JSON
    yq-go        # YAML
    htop         # process monitor
    curl
    wget
    unzip
  ];

  # bat — syntax-highlighted pager; configure theme to match terminal
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  # fzf — wired to Ctrl-R in shell.nix initContent
  programs.fzf = {
    enable = true;
    enableZshIntegration = false; # handled manually in shell.nix for control
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--info=inline"
    ];
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };
}
