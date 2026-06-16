#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
ARCH_DIR="$ROOT/packages/arch/lyra"

echo "==> Copying artifacts..."
cp "$ROOT/artifacts/server/"*.whl "$ARCH_DIR/"
cp "$ROOT/artifacts/ui/"*.tar.gz "$ARCH_DIR/"

echo "Building Arch package..."
cd "$ARCH_DIR"
rm -rf src pkg *.pkg.tar.zst
makepkg -f

echo
echo "Generated package:"
find "$ARCH_DIR" -name "*.pkg.tar.zst" -type f
