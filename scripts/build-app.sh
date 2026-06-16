#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

rm -rf dist artifacts

echo "Building server..."
(
    cd lyra-server
    rm -rf dist
    uv build
)

echo "Building UI..."
(
    cd lyra-ui
    pnpm install --frozen-lockfile
    pnpm build
)

echo "Collecting artifacts..."
mkdir -p artifacts/server artifacts/ui

cp lyra-server/dist/*.whl artifacts/server/
cp lyra-server/dist/*.tar.gz artifacts/server/
cp dist/*.tar.gz artifacts/ui/

echo
echo "Artifacts:"
find artifacts -type f
