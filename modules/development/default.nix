{ pkgs, ... }:
{
  # ── Generic Linux binary compat ──────────────────────────────────────────────
  # NixOS has no standard dynamic loader path, so prebuilt binaries from npm
  # global installs (e.g. Claude Code) fail with "cannot start dynamically
  # linked executable". nix-ld provides that loader stub.
  # https://nix.dev/permalink/stub-ld
  programs.nix-ld.enable = true;

  # NixOS also has no /usr/bin or /bin FHS tree, so tools that hard-code a
  # binary's path there (rather than searching $PATH) can't find it even
  # when it's installed and on PATH — e.g. `claude plugin eval` requires
  # bubblewrap at a fixed path since it runs unattended with no one to
  # approve a PATH-based lookup. envfs mounts a FUSE fs at /usr/bin that
  # resolves any missing name against the calling process's own $PATH.
  services.envfs.enable = true;

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
  # System-wide defaults track the newest stable release of each language.
  # Projects that need an older version pin it in their own devenv.nix,
  # activated automatically on cd by direnv (`.envrc`: `use devenv`).

  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh

    # Task runner — see justfile (check, fix, build, apply)
    just

    # Sandboxing — Claude Code (interactive Bash tool and `claude plugin eval`)
    # requires this on Linux; declared explicitly rather than relying on it
    # showing up transitively (e.g. via fwupd)
    bubblewrap

    # Containers
    docker-compose
    docker-sbx
    lazydocker # Docker TUI

    # Per-project dev environments (languages, versions, services)
    devenv

    # Rust — rustup manages stable/nightly/targets itself; pin per project
    # with rust-toolchain.toml. Do not also install pkgs.rustc — they conflict
    rustup

    # Node — newest release line (nodejs_latest follows it as nixpkgs updates)
    nodejs_latest

    # Python — python3 is nixpkgs' default, currently the newest stable (3.14)
    python3
    uv # fast package/project manager; replaces pip/venv

    # Ruby — nixpkgs' plain `ruby` lags a major version, so name the newest
    ruby_4_0

    # Editor fallback
    vscode

    # Terminal help
    tldr
  ];

  # devenv's binary cache, so its tooling downloads prebuilt instead of
  # compiling. Configured system-wide rather than making huw a trusted-user
  # (trusted users can import arbitrary store paths — effectively root).
  nix.settings = {
    extra-substituters = [ "https://devenv.cachix.org" ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # NixOS defaults EDITOR to nano in /etc/set-environment, which every shell
  # re-reads; Home Manager's EDITOR=nvim is only sourced once per login, so
  # nano wins in nested shells. Set it here to override the default.
  environment.variables.EDITOR = "nvim";

  # docker group membership is declared in hosts/framework-13/configuration.nix
}
