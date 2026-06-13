#
# AI development shell — persistent nix shell for Claude Code, OpenCode, Codex
#
# Usage:
#   nix develop ~/.config/nixos-config#ai
#
# Or add a .envrc to ~/ai-work/ (or wherever you do AI sessions):
#   echo "use flake ~/.config/nixos-config#ai" > ~/ai-work/.envrc
#   direnv allow
#
# Add this output to flake.nix:
#
#   devShells.x86_64-linux.ai = import ./modules/development/ai-shell.nix {
#     inherit pkgs;
#   };
#
{ pkgs }:
pkgs.mkShell {
  name = "ai";

  packages = with pkgs; [
    nodejs_22     # runtime for Node-based AI CLIs

    # Claude Code — Anthropic's CLI (install via npm until in nixpkgs)
    # Run once to install: npm install -g @anthropic-ai/claude-code
    # Or use the package if available:
    # claude-code

    # OpenCode — TUI for AI coding (opencode.ai)
    # npm install -g opencode-ai

    # Codex — OpenAI CLI
    # npm install -g @openai/codex

    # Python AI libraries (add as needed per project)
    (python3.withPackages (ps: with ps; [
      anthropic
      openai
      tiktoken
    ]))

    # Useful alongside AI tools
    jq # parse API responses
    httpie # HTTP client for API testing
  ];

  shellHook = ''
    echo "AI shell — Claude Code, OpenCode, Codex"
    echo "Node: $(node --version) | Python: $(python3 --version)"

    # Ensure npm globals are on PATH
    export PATH="$HOME/.npm-global/bin:$PATH"
  '';
}
