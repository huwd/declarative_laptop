{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;

    # Core settings
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";
    terminal = "screen-256color";

    # Plugins — declared here; tmux-plugin-manager not needed on NixOS
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator # C-h/j/k/l pane switching aware of nvim splits
      sensible             # sane defaults
    ];

    extraConfig = ''
      # Split panes — keep both sets of bindings from dotfiles
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind v split-window -h -p 50 -c "#{pane_current_path}"
      bind s split-window -p 50 -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Pane resize with vi keys (shift-ctrl-hjkl in alacritty)
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # New window preserves cwd
      bind c new-window -c "#{pane_current_path}"

      # Synchronise panes (broadcast input)
      bind e setw synchronize-panes on
      bind E setw synchronize-panes off

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Double Ctrl-a sends literal Ctrl-a (for inner sessions / readline)
      bind-key C-a send-prefix

      # Zoom toggle
      bind z resize-pane -Z

      # Copy mode
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Status bar — powerline style, ported from dotfiles
      set -g status-left-length 52
      set -g status-right-length 200
      set -g status-fg white
      set -g status-bg colour234
      set -g status-left \
        '#[fg=colour235,bg=colour252,bold] ❐ #S #[fg=colour252,bg=colour238,nobold]⮀#[fg=colour245,bg=colour238,bold] #(whoami) #[fg=colour238,bg=colour234,nobold]⮀'
      set -g window-status-format \
        '#[fg=colour235,bg=colour252,bold] #I #(pwd="#{pane_current_path}"; echo ''${pwd####*/}) #W '
      set -g window-status-current-format \
        '#[fg=colour234,bg=colour39]⮀#[fg=black,bg=colour39,noreverse,bold] #{?window_zoomed_flag,#[fg=colour228],}#I #(pwd="#{pane_current_path}"; echo ''${pwd####*/}) #W #[fg=colour39,bg=colour234,nobold]⮀'
      set -g status-interval 2

      # Window options
      setw -g pane-base-index 1
      set-window-option -g mouse on
    '';
  };
}
