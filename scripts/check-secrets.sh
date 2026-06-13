#!/usr/bin/env bash
# Verify that every secret declared in secrets/secrets.nix has a committed .age file.
# Fails with a non-zero exit if any are missing.

set -euo pipefail

SECRETS_NIX="secrets/secrets.nix"
MISSING=0

if [[ ! -f "$SECRETS_NIX" ]]; then
  echo "No secrets/secrets.nix found — skipping check"
  exit 0
fi

# Extract "filename.age" entries from secrets.nix
# Matches the agenix convention: "secret-name.age".publicKeys = [ ... ];
while IFS= read -r secret; do
  path="secrets/$secret"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: declared secret '$path' has no committed .age file"
    MISSING=$((MISSING + 1))
  else
    echo "OK: $path"
  fi
done < <(grep -oP '"[^"]+\.age"' "$SECRETS_NIX" | tr -d '"')

if [[ $MISSING -gt 0 ]]; then
  echo ""
  echo "FAIL: $MISSING secret(s) declared but not committed"
  exit 1
fi

echo "All declared secrets have .age files"
