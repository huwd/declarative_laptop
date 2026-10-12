# Neovim (LazyVim)

Based on the [LazyVim starter](https://github.com/LazyVim/starter).

`terminal/editor.nix` links `~/.config/nvim` straight to this directory (`mkOutOfStoreSymlink`), so:

- edits here take effect on the next nvim start — no `just apply` needed
- `lazy-lock.json` (plugin versions) and `lazyvim.json` (enabled extras) come from lazy.nvim / `:LazyExtras`; commit these files

Add or override plugins in `lua/plugins/`, settings in `lua/config/`.
See <https://lazyvim.github.io>.
