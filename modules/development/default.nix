{ pkgs, ... }:
{
  # ── Generic Linux binary compat ──────────────────────────────────────────────
  # NixOS has no standard dynamic loader path, so prebuilt binaries from npm
  # global installs (e.g. Claude Code) fail with "cannot start dynamically
  # linked executable". nix-ld provides that loader stub.
  # https://nix.dev/permalink/stub-ld
  programs.nix-ld.enable = true;

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

    # Task runner — see justfile (check, fix, build, apply)
    just

    # Containers
    docker-compose
    docker-sbx
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
  ];

  # NixOS defaults EDITOR to nano in /etc/set-environment, which every shell
  # re-reads; Home Manager's EDITOR=nvim is only sourced once per login, so
  # nano wins in nested shells. Set it here to override the default.
  environment.variables.EDITOR = "nvim";

  # docker group membership is declared in hosts/framework-13/configuration.nix
}
