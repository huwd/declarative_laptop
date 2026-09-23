{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Modern CLI replacements
    eza # ls — declared in shell.nix aliases
    bat # cat/less — declared in shell.nix aliases
    btop # prettier process monitor
    ripgrep # grep
    fd # find
    fzf # fuzzy finder — shell integration in shell.nix
    zoxide # smart cd — init in shell.nix

    # Nix-specific tooling
    nvd # diff between NixOS generations
    nix-tree # visual TUI of the nix dependency closure
    vulnix # CVE scanner for the nix store

    # General utils worth having
    jq # JSON
    yq-go # YAML
    htop # process monitor
    curl
    wget
    unzip
    openssl # used by the jwt() shell function in shell.nix
    wl-clipboard # wl-copy / wl-paste — CLI clipboard for Wayland (used by gh)
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
    fileWidget.command = "fd --type f --hidden --follow --exclude .git";
    changeDirWidget.command = "fd --type d --hidden --follow --exclude .git";
  };
}
