#!/usr/bin/env bash
# install.sh -- one-command installer for `?` (ask-cli)
# Installs bin/? to --prefix (default ~/.local/bin) and agents/ask.md to
# ~/.config/opencode/agents/ask.md. Pass --sudo to install to /usr/local/bin.
set -eu

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
SUDO=""
VERSION="1.0.0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2 ;;
    --sudo) SUDO="sudo"; PREFIX="/usr/local/bin"; shift ;;
    -h|--help)
      echo "usage: install.sh [--prefix DIR] [--sudo]"
      echo "  --prefix DIR  install the wrapper to DIR (default ~/.local/bin)"
      echo "  --sudo        install to /usr/local/bin via sudo"
      exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

AGENTS_DIR="$HOME/.config/opencode/agents"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ask-cli"

needs() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: '$1' not found in PATH (required)" >&2
    return 1
  }
}

echo "[1/4] checking prerequisites..."
needs bash || exit 1
needs python3 || echo "warning: python3 not found in PATH (set PYTHON_BIN, e.g. 'python' on Windows)" >&2
needs opencode || {
  echo "error: opencode CLI not found. Install it first:" >&2
  echo "  curl -fsSL https://opencode.ai/install | bash" >&2
  exit 1
}

echo "[2/4] installing wrapper to $PREFIX/?..."
mkdir -p "$PREFIX"
install_cmd=()
[[ -n "$SUDO" ]] && install_cmd+=(sudo)
install_cmd+=(install -Dm755 "$REPO/bin/?" "$PREFIX/?")
"${install_cmd[@]}"

echo "[3/4] installing ask agent to $AGENTS_DIR/ask.md..."
mkdir -p "$AGENTS_DIR"
cp "$REPO/agents/ask.md" "$AGENTS_DIR/ask.md"

echo "[4/4] installing model config to $CONFIG_DIR/models.conf..."
mkdir -p "$CONFIG_DIR"
if [[ -f "$CONFIG_DIR/models.conf" ]]; then
  echo "  (config already exists at $CONFIG_DIR/models.conf -- leaving it untouched)"
else
  cp "$REPO/config/models.conf" "$CONFIG_DIR/models.conf"
  echo "  (default config written; edit $CONFIG_DIR/models.conf to change default model and aliases)"
fi

echo ""
echo "installed:"
echo "  $PREFIX/? (v$VERSION)"
echo "  $AGENTS_DIR/ask.md"
echo "  $CONFIG_DIR/models.conf"

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo "note: add $PREFIX to your PATH, then run: ? -h" >&2 ;;
esac

echo "done. try: ? what is opencode"