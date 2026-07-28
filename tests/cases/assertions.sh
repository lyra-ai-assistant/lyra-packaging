#!/usr/bin/env bash
# Shared assertions run inside both the Ubuntu and Arch install-test
# containers, after the package has been installed via the OS's own package
# manager (apt/pacman). Same binaries and layout on both distros, so one
# script covers both — OS-specific setup lives in the Dockerfiles instead.
set -uo pipefail

FAILED=0
fail() { echo "FAIL: $1" >&2; FAILED=1; }
pass() { echo "OK: $1"; }

echo "== binaries on PATH =="
for bin in lyra lyra-ui lyra-install-backend; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "$bin found"
  else
    fail "$bin not found on PATH"
  fi
done

echo "== lyra --version =="
if lyra --version >/dev/null 2>&1; then
  pass "lyra --version"
else
  fail "lyra --version failed"
fi

echo "== lyra serve --help =="
if lyra serve --help >/dev/null 2>&1; then
  pass "lyra serve --help"
else
  fail "lyra serve --help failed"
fi

echo "== desktop entry present =="
if [ -f /usr/share/applications/lyra.desktop ]; then
  pass "desktop entry present"
else
  fail "desktop entry missing at /usr/share/applications/lyra.desktop"
fi

echo "== lyra-ui launcher resolves (not launched — headless, no X server) =="
if [ -e /opt/lyra/lyra-ui ] || command -v lyra-ui >/dev/null 2>&1; then
  pass "lyra-ui launcher present"
else
  fail "lyra-ui launcher missing"
fi

echo "== lyra uninstall =="
if lyra uninstall --yes >/dev/null 2>&1; then
  pass "lyra uninstall ran"
else
  fail "lyra uninstall failed or does not support --yes — check CLI flag name"
fi

if [ "$FAILED" -ne 0 ]; then
  echo "ONE OR MORE CHECKS FAILED" >&2
  exit 1
fi

echo "ALL CHECKS PASSED"
