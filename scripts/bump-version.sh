#!/usr/bin/env bash
# bump-version.sh — bumps VERSION file
# Usage: ./scripts/bump-version.sh [major|feature|patch]
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
VERSION_FILE="$ROOT/VERSION"

current=$(cat "$VERSION_FILE")
IFS='.' read -r V F N <<< "$current"

case "${1:-patch}" in
  major)   V=$((V + 1)); F=0; N=0 ;;
  feature) F=$((F + 1)); N=0 ;;
  patch)   N=$((N + 1)) ;;
  *)
    echo "Usage: $0 [major|feature|patch]"
    exit 1
    ;;
esac

new="$V.$F.$N"
echo "$new" > "$VERSION_FILE"
echo "==> Bumped $current → $new"
