{ config, pkgs, ... }:
{
  # Neovim — binary only. LazyVim manages its own plugins via lazy.nvim.
  # Do not declare neovim plugins here; they will fight LazyVim.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    # Preserve the Home Manager 25.05 provider behaviour explicitly.
    withPython3 = true;
    withRuby = true;
    # Load Home Manager's provider settings via the nvim wrapper instead of
    # writing ~/.config/nvim/init.lua, which belongs to LazyVim.
    sideloadInitLua = true;
  };

  # LazyVim config lives in this repo at home/huw/nvim. Link it out-of-store
  # (not a read-only copy) so edits apply on nvim restart without a rebuild,
  # and so lazy.nvim can write lazy-lock.json / lazyvim.json back into git.
  # Assumes the repo is checked out at ~/.config/nixos-config on every host.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos-config/home/huw/nvim";

  home.packages = with pkgs; [
    # nvim-treesitter compiles parsers locally
    gcc
    tree-sitter
  ];

  # LazyGit
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [
            "blue"
            "bold"
          ];
          inactiveBorderColor = [ "white" ];
          selectedLineBgColor = [ "default" ];
        };
        showFileTree = true;
        nerdFontsVersion = "3";
      };
      # lazygit ≥0.55 schema; the old git.paging key triggers a migration that
      # fails because this file is read-only in the Nix store.
      git.diffRenderers = [
        {
          colorArg = "always";
          command = "delta --dark --paging=never";
        }
      ];
      os.editPreset = "nvim";
    };
  };

  # delta itself is installed and configured in git.nix (programs.git.delta)
}
