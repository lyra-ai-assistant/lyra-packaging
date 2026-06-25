#!/usr/bin/env bash
# build-app-ci.sh — downloads latest artifacts from GitHub Releases
# Run from repo root: ./scripts/build-app-ci.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

ORG="lyra-ai-assistant"

rm -rf artifacts
mkdir -p artifacts/server artifacts/ui

echo "==> Downloading latest lyra-server release..."
gh release download \
    --repo "$ORG/lyra-server" \
    --pattern "*.whl" \
    --dir artifacts/server

echo "==> Downloading latest lyra-ui release..."
gh release download \
    --repo "$ORG/lyra-ui" \
    --pattern "*.tar.gz" \
    --dir artifacts/ui

echo
echo "Artifacts:"
find artifacts -type f
