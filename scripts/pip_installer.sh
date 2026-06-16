# pip_installer.sh — source this file, then call: pip_install <args>
# Detects uv, pip, or pip3 in order of preference.

detect_pip() {
    if command -v uv &>/dev/null; then
        echo "uv pip"
    elif command -v pip &>/dev/null; then
        echo "pip"
    elif command -v pip3 &>/dev/null; then
        echo "pip3"
    else
        echo "ERROR: No Python package installer found (uv, pip, pip3)" >&2
        exit 1
    fi
}

pip_install() {
    local installer
    installer=$(detect_pip)
    echo "==> Using installer: $installer"
    $installer install "$@"
}
