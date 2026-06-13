_:
{
  imports = [
    ./shell.nix
    ./prompt.nix
    ./tools.nix
    ./editor.nix
    ./emulator.nix
    ./zellij.nix    # ← swap for ./tmux.nix to switch multiplexers
    # ./tmux.nix
  ];
}
