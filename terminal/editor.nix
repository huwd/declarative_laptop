_: {
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
