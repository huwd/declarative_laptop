{ pkgs, ... }:
{
  # ── Container runtimes ───────────────────────────────────────────────────────

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  # ── Language runtimes ────────────────────────────────────────────────────────
  #
  # Per-project toolchains → devenv.nix
  # System-wide only what's needed outside any project context

  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh

    # Containers
    docker-compose
    lazydocker # Docker TUI

    # Rust — rustup manages stable/nightly/targets itself
    # Do not also install pkgs.rustc — they conflict
    rustup

    # Node — system-wide for AI CLI tools and one-off scripts
    # Per-project versions → devenv.nix
    nodejs_22

    # Python
    python3
    uv # fast package/project manager; replaces pip/venv

    # Editor fallback
    vscode

    # Terminal help
    tldr

    # SBX (Docker Sandboxed Execution)
    # Too new for nixpkgs — install via Docker:
    #   docker run --rm docker/sbx <command>
    # Or follow https://docs.docker.com/sbx once the CLI ships as a binary
  ];

  # docker group membership is declared in hosts/framework-13/configuration.nix
}
