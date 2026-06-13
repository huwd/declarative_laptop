_:
{
  # Alacritty — fast, GPU-accelerated, intentionally minimal.
  # No built-in tabs or splits; those are tmux/zellij's job.
  # Switch to programs.ghostty if you want a more featureful emulator.
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 8; y = 8; };
        decorations = "full";
        opacity = 0.97;
        startup_mode = "Windowed";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 13.0;
      };

      # Catppuccin Mocha — pairs well with the starship/bat/lazygit themes
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };

      cursor = {
        style = { shape = "Block"; blinking = "On"; };
        blink_interval = 500;
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      keyboard.bindings = [
        # Pass Ctrl-h/j/k/l through to tmux/neovim
        { key = "H"; mods = "Control"; chars = "\\u0008"; }
      ];
    };
  };
}
