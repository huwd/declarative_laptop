# Terminal Environment

Home Manager manages the terminal setup.
The modules in `terminal/` declare its components, and `home/huw/default.nix` imports them.

## Stack

| Concern | Tool | Notes |
|---------|------|-------|
| Shell | zsh | Native Home Manager — no prezto |
| Prompt | Starship | Replaces agnoster; powerline aesthetic |
| Multiplexer | tmux **or** zellij | See switching instructions below |
| Emulator | Alacritty | Fast, minimal; delegates to tmux/zellij |
| Editor | Neovim (LazyVim) | Binary via Nix; plugins via LazyVim |
| Git TUI | LazyGit | Home Manager module |
| File listing | eza | Replaces ls/ll aliases |
| Pager | bat | Replaces less/cat in aliases |
| Search | ripgrep | Replaces grep in scripts |
| Find | fd | Sane syntax over find |
| Fuzzy search | fzf | History, file, and command search |
| Directory jump | zoxide | Replaces cd muscle memory over time |

## Switching Multiplexers

Open `terminal/default.nix` and swap one line:

```nix
# tmux (default — strong vi/vim-navigator muscle memory)
./tmux.nix

# zellij (modern Rust multiplexer — different keybind model)
# ./zellij.nix
```

See `terminal/tmux.nix` and `terminal/zellij.nix` for full documentation of the key binding differences.

## Key Aliases Carried Forward

From `~/.dotfiles/zsh/aliases.zsh` and `git.zsh`, adapted for NixOS:

| Alias | Expands to | Change from dotfiles |
|-------|-----------|---------------------|
| `ll` | `eza -alh --git` | eza replaces ls |
| `lsg` | `ll \| grep` | unchanged |
| `lh` | `eza -alh --sort=modified \| head` | eza replaces ls |
| `gs` | `git status` | unchanged |
| `glg` | `git l` | unchanged |
| `gps` | `git push` | unchanged |
| `gpsh` | `git push -u origin HEAD` | simplified |
| `:q` | `exit` | unchanged |
| `l` | `bat --paging=auto` | bat replaces less |

## What's Dropped

- **prezto** — Home Manager's `programs.zsh` handles plugin loading, themes and completions
- **nvm** — replaced by per-project `devenv.nix` / `nix shell`
- **rbenv** — same; see `OS.md` dev environment philosophy
- **tmuxinator** — zellij has native layouts; tmux sessions can use plain scripts if needed
- **macOS-specific tmux hacks** — `reattach-to-user-namespace` removed; irrelevant on Linux

## How Home Manager applies dotfiles

Home Manager applies the user configuration during `nixos-rebuild switch`.
You do not need to manually symlink, stow, or copy anything.
Running:

```bash
nixos-rebuild switch --flake ~/.config/nixos-config#framework-13
```

applies both system and Home Manager configuration in one step.
