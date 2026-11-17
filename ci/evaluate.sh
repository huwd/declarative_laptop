#!/usr/bin/env bash
# Evaluate the flake without building anything: every package, every dev
# shell, and the system of each host that routine CI covers (ADR 0021).
#
# Usage: ci/evaluate.sh [host...]     default: framework-13
#
# This replaces `nix flake check --no-build`, which evaluates every host in
# the flake, including the Dell that CI no longer maintains. A manual run of
# build.yml evaluates and builds any other host.
#
# The "Evaluate flake" job in .github/workflows/check.yml and `just evaluate`
# both call this script.
set -euo pipefail

if [ "$#" -eq 0 ]; then
  set -- framework-13
fi

system=$(nix eval --raw --impure --expr builtins.currentSystem)

# Reading drvPath forces Nix to evaluate and instantiate each derivation,
# which is what `nix flake check --no-build` does for these outputs.
for output in packages devShells; do
  echo "Evaluating $output.$system"
  nix eval --json ".#$output.$system" --apply 'builtins.mapAttrs (_: d: d.drvPath)'
done

for host in "$@"; do
  echo "Evaluating nixosConfigurations.$host"
  nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
  echo
done
