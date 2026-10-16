default: check

# Defaults to this machine; hostnames match nixosConfigurations names
HOST := `hostname`

# ── Local checks (mirrors CI tiers 1 + 2) ───────────────────────────────────

check: format-check lint evaluate secrets docs-lint
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

# Markdown structure lint (config: .markdownlint-cli2.jsonc)
docs-lint:
    nix run --inputs-from . nixpkgs#markdownlint-cli2

# Advisory prose/spelling check (British English) — local only, not in CI or `check`
docs-prose *FILES:
    nix run .#vale -- {{ if FILES == "" { "$(git ls-files '*.md')" } else { FILES } }}

# Build the documentation site into ./result (fails on broken internal links)
docs-site:
    nix build .#docs-site

# Preview the documentation site at http://127.0.0.1:1111
# Re-run to pick up changes to the Markdown sources
docs-serve:
    #!/usr/bin/env bash
    set -euo pipefail
    dir=$(mktemp -d)
    trap 'rm -rf "$dir"' EXIT
    cp -r site/. "$dir"/
    chmod -R u+w "$dir"
    nix run --inputs-from . nixpkgs#python3 -- scripts/build-site-content.py . "$dir/content"
    nix run --inputs-from . nixpkgs#zola -- --root "$dir" serve

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

# ── Dependency updates (mirrors CI tier 5) ──────────────────────────────────

update:
    nix flake update
    @echo "Run 'just build' then 'just diff' to review changes before applying"

diff: build
    nix run --inputs-from . nixpkgs#nvd -- diff /run/current-system result
