{ pkgs, ... }:
{
  # Neovim — binary only. LazyVim manages its own plugins via lazy.nvim.
  # Do not declare neovim plugins here; they will fight LazyVim.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  # LazyVim config lives in ~/.config/nvim — track it in the nixos-config repo
  # by symlinking, or manage it separately in its own git repo.
  #
  # Option A: symlink from within this repo (add your nvim config at
  #   home/huw/nvim/ and uncomment):
  #
  # xdg.configFile."nvim" = {
  #   source = ../nvim;
  #   recursive = true;
  # };
  #
  # Option B: keep nvim config in a separate repo and clone it to
  #   ~/.config/nvim on first boot (simpler; avoids Nix/LazyVim friction).

  # LazyGit
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [ "blue" "bold" ];
          inactiveBorderColor = [ "white" ];
          selectedLineBgColor = [ "default" ];
        };
        showFileTree = true;
        nerdFontsVersion = "3";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
      os.editPreset = "nvim";
    };
  };

  home.packages = with pkgs; [
    delta # syntax-highlighted git diffs; used by lazygit and git itself
  ];

  # delta config lives in ~/.gitconfig [delta] section — manage via git config
  # or add programs.git.enable = true here and declare it in Nix if you want
  # home-manager to own your full git config.
}
