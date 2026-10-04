default: check

# Defaults to this machine; hostnames match nixosConfigurations names
HOST := `hostname`

# ── Local checks (mirrors CI tiers 1 + 2) ───────────────────────────────────

check: format-check lint evaluate secrets
    @echo "All checks passed"

format-check:
    nix run --inputs-from . nixpkgs#nixfmt -- --check $(find . -name '*.nix' -not -path './.direnv/*')

lint:
    nix run --inputs-from . nixpkgs#statix -- check .
    nix run --inputs-from . nixpkgs#deadnix -- --fail .

evaluate:
    nix flake check --no-build

secrets:
    bash scripts/check-secrets.sh

# ── Auto-fix ────────────────────────────────────────────────────────────────

fix:
    nix run --inputs-from . nixpkgs#nixfmt -- $(find . -name '*.nix' -not -path './.direnv/*')
    nix run --inputs-from . nixpkgs#statix -- fix .
    nix run --inputs-from . nixpkgs#deadnix -- --edit .

# ── Build (mirrors CI tier 3) ───────────────────────────────────────────────

build:
    nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel

scan: build
    nix run --inputs-from . nixpkgs#vulnix -- --closure ./result --whitelist vulnix.toml

# ── System management ───────────────────────────────────────────────────────

apply:
    sudo nixos-rebuild switch --flake .#{{HOST}}

apply-home:
    home-manager switch --flake .#{{HOST}}

# ── Dependency updates (mirrors CI tier 5) ──────────────────────────────────

update:
    nix flake update
    @echo "Run 'just build' then 'just diff' to review changes before applying"

diff: build
    nix run --inputs-from . nixpkgs#nvd -- diff /run/current-system result
