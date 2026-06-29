#!/usr/bin/env bash
# sync-version.sh — syncs VERSION to PKGBUILD and debian/control
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
VERSION=$(cat "$ROOT/VERSION")

echo "==> Syncing version $VERSION..."

# PKGBUILD
sed -i "s/^pkgver=.*/pkgver=$VERSION/" \
    "$ROOT/packages/arch/lyra/PKGBUILD"

# debian/control
sed -i "s/^Version:.*/Version: $VERSION/" \
    "$ROOT/packages/debian/lyra/DEBIAN/control"

# deb output filename in build-deb.sh
sed -i "s/lyra_[0-9]*\.[0-9]*\.[0-9]*-1_amd64/lyra_${VERSION}-1_amd64/g" \
    "$ROOT/scripts/build-deb.sh"

echo "==> Done"
