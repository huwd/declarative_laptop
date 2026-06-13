{ ... }:
#
# Zellij — primary multiplexer.
# Swap this for tmux.nix in default.nix to revert.
#
# NAVIGATION MODEL
# ─────────────────
# Alt-hjkl moves focus between panes from anywhere — no prefix, no mode.
# This is safe in the shell (unlike Ctrl-hjkl, where Ctrl-h is backspace).
#
# Inside neovim, Ctrl-hjkl works for split navigation via the zellij.nvim
# plugin (see NEOVIM INTEGRATION below). At a split edge, zellij.nvim calls
# the zellij CLI to hop to the adjacent pane — same end result as
# vim-tmux-navigator, different architecture.
#
# PANE OPERATIONS (Ctrl-p to enter pane mode, Esc to leave)
# ─────────────────────────────────────────────────────────
#   Ctrl-p v       new pane right
#   Ctrl-p s       new pane down
#   Ctrl-p f       toggle fullscreen
#   Ctrl-p z       toggle floating pane
#   Ctrl-p x       close pane
#   Ctrl-p r       enter resize mode (then hjkl to resize)
#
# TAB OPERATIONS (Ctrl-t to enter tab mode)
# ─────────────────────────────────────────
#   Ctrl-t n       new tab
#   Ctrl-t x       close tab
#   Ctrl-t 1-9     jump to tab
#
# SESSION (Ctrl-o)
# ────────────────
#   Ctrl-o d       detach
#   Ctrl-o w       session manager
#
# SCROLL / SEARCH (Ctrl-s)
# ────────────────────────
#   Ctrl-s         enter scroll mode
#   Ctrl-s /       search (in scroll mode)
#   Mouse wheel    scroll without entering mode
#
# NEOVIM INTEGRATION
# ──────────────────
# Add zellij.nvim to your LazyVim config (~/.config/nvim/lua/plugins/zellij.lua):
#
#   return {
#     "fresh2dev/zellij.nvim",
#     lazy = false,
#     keys = {
#       { "<C-h>", function() require("zellij").move_left()  end },
#       { "<C-j>", function() require("zellij").move_down()  end },
#       { "<C-k>", function() require("zellij").move_up()    end },
#       { "<C-l>", function() require("zellij").move_right() end },
#     },
#     opts = {},
#   }
#
# Do NOT bind Ctrl-hjkl in the zellij config below — let neovim own them.
#
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true; # auto-starts zellij when opening a terminal
  };

  xdg.configFile."zellij/config.kdl".text = ''
    // Shell
    default_shell "zsh"

    // Aesthetics
    pane_frames false
    theme "catppuccin-dark"
    default_layout "compact"

    // Behaviour
    mouse_mode true
    copy_on_select false
    scroll_buffer_size 10000

    keybinds {
        // Alt-hjkl — pane focus from anywhere, no prefix required
        // Shell-safe: does not conflict with readline bindings
        shared_except "locked" {
            bind "Alt h" { MoveFocus "Left"; }
            bind "Alt j" { MoveFocus "Down"; }
            bind "Alt k" { MoveFocus "Up"; }
            bind "Alt l" { MoveFocus "Right"; }
        }

        // Pane mode — Ctrl-p to enter
        pane {
            bind "v" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "s" { NewPane "Down"; SwitchToMode "Normal"; }
        }
    }
  '';
}
