#!/usr/bin/env bash
# Single entrypoint for the supported-OS install matrix (Ubuntu, Arch Linux —
# see README.md "Supported distributions"). Requires already-built package
# artifacts: run scripts/build-deb.sh and scripts/build-arch.sh first (or
# have CI produce dist/ and packages/arch/lyra/*.pkg.tar.zst).
#
# Usage:
#   ./tests/run.sh            # both OS
#   ./tests/run.sh ubuntu     # single OS
#   ./tests/run.sh archlinux
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

TARGET="${1:-all}"

DEB=$(find dist -maxdepth 1 -name "lyra_*.deb" 2>/dev/null | head -n1 || true)
PKG=$(find packages/arch/lyra -maxdepth 1 -name "lyra-*.pkg.tar.zst" 2>/dev/null | head -n1 || true)

run_ubuntu() {
  [ -n "$DEB" ] || { echo "No .deb found under dist/ — run ./scripts/build-deb.sh first" >&2; exit 1; }
  echo "== Ubuntu install test (artifact: $DEB) =="
  docker build -f tests/docker/ubuntu.Dockerfile -t lyra-install-test:ubuntu "$ROOT"
  docker run --rm lyra-install-test:ubuntu
}

run_archlinux() {
  [ -n "$PKG" ] || { echo "No .pkg.tar.zst found under packages/arch/lyra/ — run ./scripts/build-arch.sh first" >&2; exit 1; }
  echo "== Arch Linux install test (artifact: $PKG) =="
  docker build -f tests/docker/archlinux.Dockerfile -t lyra-install-test:archlinux "$ROOT"
  docker run --rm lyra-install-test:archlinux
}

case "$TARGET" in
  ubuntu) run_ubuntu ;;
  archlinux) run_archlinux ;;
  all) run_ubuntu; run_archlinux ;;
  *) echo "Unknown target '$TARGET' — expected ubuntu, archlinux, or all" >&2; exit 1 ;;
esac

echo "Install test(s) passed."
