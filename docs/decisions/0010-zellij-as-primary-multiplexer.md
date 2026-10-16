# 0010. Use zellij as the primary terminal multiplexer

- **Status:** Accepted
- **Decided by:** @huwd
- **Decided:** 2026-06-13
- **Recorded:** 2026-10-16
- **Discussion:** [#40](https://github.com/huwd/declarative_laptop/issues/40), [#70](https://github.com/huwd/declarative_laptop/issues/70)

## Summary

A terminal multiplexer splits one terminal window into panes and tabs, and keeps sessions running when the window closes.
The configuration includes both zellij and tmux, but only one is active at a time.
Zellij is the active one, because its key bindings are easier to discover and its configuration fits Home Manager.
It also gave a chance to learn a newer tool.
The tmux module remains for now as a fallback and is a candidate for removal.

## Context

The earlier dotfiles used tmux, with tmuxinator for session layouts ([#40](https://github.com/huwd/declarative_laptop/issues/40)).
The initial NixOS scaffold (`a08e5b9`) added modules for both multiplexers and made zellij the default.
No discussion at the time recorded the reasons.
@huwd supplied them when this record was written, so they are a recollection rather than contemporary evidence.

## Options considered

### Zellij (chosen)

Zellij shows its key bindings on screen and groups them into modes: `Ctrl-p` for panes and `Ctrl-t` for tabs.
It has native layouts, so it replaces tmuxinator.
Home Manager provides `programs.zellij`, and the `config.kdl` file is written from `terminal/zellij.nix`.
Neovim and zellij share pane navigation through the `zellij.nvim` plugin, which takes the role that `vim-tmux-navigator` has in tmux.

Zellij is younger than tmux and less widely installed.
Its modal key bindings differ from the tmux prefix chords that the earlier dotfiles used.

### tmux

Tmux is mature, widely available and familiar from the earlier dotfiles.
Its `terminal/tmux.nix` module keeps the same prefix (`C-a`) and vi-style bindings.
It lost because its key bindings must be remembered rather than discovered, and its layouts need separate tooling.
It also offered no new learning, which was part of the project's purpose ([0001](0001-why-this-project.md)).

### No multiplexer

The terminal emulator, Alacritty, has no panes or tabs, so a multiplexer provides these.
This option wasn't evaluated in detail.

## Decision

`terminal/default.nix` imports `./zellij.nix`, and zsh starts zellij in each new terminal.
`terminal/tmux.nix` stays in the repository but is not imported.

## Consequences

- The key bindings are documented in the header of `terminal/zellij.nix`, which is the source of truth for them.
- Switching back to tmux means importing `./tmux.nix` instead of `./zellij.nix` in `terminal/default.nix`, then applying the configuration with `just apply`.
- Keeping two multiplexer modules costs some maintenance.
  If tmux goes unused, remove `terminal/tmux.nix` and record that in a new decision record that supersedes this one.
- Zellij is less common on other machines, so habits formed here transfer less well to servers and other people's systems.
