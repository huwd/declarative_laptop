# CI/CD Plan

## Objectives

Every change to this config repo must satisfy two guarantees before it reaches
the machine:

1. **No regressions** — the system still evaluates, builds, and is deployable
2. **No silent security drift** — new or updated packages are checked against
   known CVEs

Changes that pass CI can be applied with confidence. Changes that fail CI are
never shipped.

## On "Only the Changes"

A NixOS system is a single closure — you cannot build "just the part that
changed" in isolation. The unit of deployment is the full system.

What you *can* do is lean on Nix's content-addressed store: unchanged
derivations are never rebuilt, they are fetched from the binary cache. A
one-line change to `modules/apps.nix` triggers a rebuild of only the affected
packages. The kernel, GNOME, and everything else come from cache.

In practice this means:

- **Syntax and lint checks** are genuinely scoped to changed `.nix` files
- **Evaluation and build** always cover the full config, but the cache makes
  this cheap after the first cold run
- `magic-nix-cache-action` on GitHub Actions maintains the cache between runs
  automatically

## Tier Structure

### Tier 1 — Syntax (every push, < 1 min)

Fast, file-scoped checks. Run on the diff of changed `.nix` files only.

| Check | Tool | What it catches |
|-------|------|----------------|
| Formatting | `nixfmt-rfc-style --check` | Unformatted Nix files |
| Linting | `statix check` | Antipatterns: broad `with`, deprecated syntax |
| Dead code | `deadnix --fail` | Unused variables and imports |
| Commit messages | `convco check` | Conventional commits format |

Formatting and linting are enforceable as auto-fixes locally:

```bash
nixfmt .               # format all .nix files in place
statix fix             # auto-fix antipatterns where possible
deadnix --edit         # remove dead code in place
```

### Tier 2 — Evaluation (every push, 1–3 min)

Evaluates all flake outputs without building derivations. Catches structural
errors: missing imports, conflicting option definitions, type mismatches.

| Check | Tool | What it catches |
|-------|------|----------------|
| Flake validity | `nix flake check` | Invalid outputs, eval errors |
| Secret hygiene | custom script | Declared secrets without a `.age` file |

The secret hygiene check is a shell script that diffs `secrets/secrets.nix`
declarations against committed `.age` files:

```bash
# scripts/check-secrets.sh
# Fails if any secret declared in secrets.nix has no matching .age file
```

### Tier 3 — Build and Security (every PR, ~5 min cached / 30 min cold)

Actually realises the full system closure. This is the ground truth: if this
passes, the config is deployable.

| Check | Tool | What it catches |
|-------|------|----------------|
| Full build | `nix build .#nixosConfigurations.framework-13...` | Build failures |
| CVE scan | `vulnix --closure result` | Known vulnerabilities in closure |

`vulnix` findings are reported as annotations on the PR. A whitelist
(`vulnix.toml`) can suppress known false positives or accepted risks, but any
new finding blocks merge until triaged.

### Tier 4 — Informational (every PR, alongside Tier 3)

Not a pass/fail gate. Produces output that informs the reviewer.

| Output | Tool | What it shows |
|--------|------|--------------|
| Package diff | `nvd diff <prev> <new>` | What packages changed and by how much |

The `nvd` diff is posted as a PR comment. On a routine `nix flake update` PR
this shows the full set of package version bumps — the equivalent of a
Dependabot summary.

To diff against the previous build, the CI job stores the closure path of the
last successful build on `main` as a GitHub Actions cache key.

### Tier 5 — Dependency Updates (weekly scheduled)

Automated `nix flake update` that opens a PR if `flake.lock` changed. The PR
runs tiers 3 and 4 and includes the `nvd` diff and `vulnix` findings in the
PR body. Acts as Dependabot for the full OS.

```
Monday 09:00 → nix flake update → if flake.lock changed → open PR
                                                          → tier 3 build
                                                          → tier 4 nvd diff
                                                          → vulnix scan
                                                          → PR body = diff + findings
```

## Historic CVE Analysis

Because `flake.lock` is committed on every change, the git history is a
timestamped record of every package version ever installed. To query historic
exposure:

```bash
git checkout <past-commit>
nix build .#nixosConfigurations.framework-13.config.system.build.toplevel \
  --no-link --print-out-paths > /tmp/old-closure
vulnix --closure /tmp/old-closure
git checkout main
```

This answers: "Was my system affected by CVE-YYYY-XXXXX, and if so, between
which dates?"

## Future: VM Smoke Tests

Not implemented in the initial setup. Worth adding when the config stabilises.

`nixos-rebuild build-vm` builds a QEMU VM from the config. A test script can
then boot it and assert:

- GNOME session starts
- User `huw` exists and can log in
- `zsh` is the login shell
- Key services are running (Syncthing, fwupd, etc.)

NixOS's `nixos-test` framework provides a Python-based assertion API for this.
Cost: ~10 min per run. Gate: PR merge (or nightly only, to avoid slowing the
PR loop).

## Local Workflow

Before pushing, run the tier 1 and 2 checks locally:

```bash
# Format
nixfmt .

# Lint
statix check .
deadnix --fail .

# Evaluate
nix flake check

# Full build (optional locally — CI will catch this)
nix build .#nixosConfigurations.framework-13.config.system.build.toplevel
```

A `justfile` or `Makefile` target will wrap these:

```bash
just check    # tier 1 + 2
just build    # tier 3
just update   # nix flake update + nvd diff
```

## Branch and PR Policy

Follows the global standard in `~/.claude/CLAUDE.md`:

- No direct commits to `main`
- Branch naming: `<type>/<short-description>`
- All tiers must pass before merge
- Tier 5 update PRs are auto-opened by CI; reviewed and merged manually
