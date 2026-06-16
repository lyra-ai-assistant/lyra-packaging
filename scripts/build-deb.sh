#!/usr/bin/env bash
# build-deb.sh — builds lyra_1.1.0-1_amd64.deb
# Run from the repo root: ./scripts/build-deb.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

source "$ROOT/scripts/pip_installer.sh"

PKGROOT="packages/debian/lyra"
ARTIFACTS_SERVER="artifacts/server"
ARTIFACTS_UI="artifacts/ui"
WHEEL=$(find "$ARTIFACTS_SERVER" -name "*.whl" | head -n1)
TARBALL=$(find "$ARTIFACTS_UI" -name "*.tar.gz" | head -n1)
VENDOR="$PKGROOT/usr/lib/lyra/vendor"

echo "==> Cleaning previous build tree..."
rm -rf \
    "$PKGROOT/usr/lib" \
    "$PKGROOT/usr/bin" \
    "$PKGROOT/opt/lyra" \
    "$PKGROOT/usr/share/applications" \
    "$PKGROOT/usr/share/doc/lyra"

echo "==> Installing Python server + deps (vendored)..."
mkdir -p "$VENDOR"
pip_install --no-deps --target="$VENDOR" "$WHEEL"
pip_install \
    --target="$VENDOR" \
    fastapi==0.115.4 \
    uvicorn==0.32.0 \
    pydantic==2.9.2 \
    markdown==3.6 \
    huggingface-hub==0.26.2 \
    "numpy>=2.0.0" \
    regex==2024.9.11 \
    tqdm==4.66.6 \
    requests==2.32.3 \
    "chromadb>=0.5.0"

echo "==> Removing srcdir references..."
find "$VENDOR" -name "direct_url.json" -delete

echo "==> Creating wrappers..."
mkdir -p "$PKGROOT/usr/bin"
cat > "$PKGROOT/usr/bin/lyra" <<'WRAPPER'
#!/usr/bin/env python3
import sys
sys.path.insert(0, '/usr/lib/lyra/vendor')
from lyra.cli.commands import main
main()
WRAPPER
chmod 755 "$PKGROOT/usr/bin/lyra"

cat > "$PKGROOT/usr/bin/lyra-install-backend" <<'WRAPPER'
#!/usr/bin/env python3
import sys
sys.path.insert(0, '/usr/lib/lyra/vendor')
from lyra.scripts.install_backend import detect_and_install
detect_and_install()
WRAPPER
chmod 755 "$PKGROOT/usr/bin/lyra-install-backend"

echo "==> Installing Electron UI..."
mkdir -p "$PKGROOT/opt/lyra"
tar -xzf "$TARBALL" -C "$PKGROOT/opt/lyra" --strip-components=1
ln -sf /opt/lyra/lyra-ui "$PKGROOT/usr/bin/lyra-ui"

echo "==> Installing desktop entry..."
mkdir -p "$PKGROOT/usr/share/applications"
cat > "$PKGROOT/usr/share/applications/lyra.desktop" <<DESKTOP
[Desktop Entry]
Name=Lyra
Comment=Lyra AI assistant for GNU/Linux
Exec=lyra-ui
Icon=/opt/lyra/resources/app/assets/app/256x256.png
Terminal=false
Type=Application
Categories=Utility;
DESKTOP

echo "==> Installing docs..."
mkdir -p "$PKGROOT/usr/share/doc/lyra"
cat > "$PKGROOT/usr/share/doc/lyra/README" <<DOC
Lyra AI assistant
Run 'lyra-install-backend' after installation to download the AI model.
DOC

echo "==> Building .deb..."
mkdir -p dist
python3 "$ROOT/scripts/deb_builder.py" "$PKGROOT" "dist/lyra_1.1.0-1_amd64.deb"

echo "==> Done: dist/lyra_1.1.0-1_amd64.deb"
