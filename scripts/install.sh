#!/usr/bin/env bash
# Installs claudeck for the current user:
#   - symlink ~/.local/bin/claudeck -> src/claudeck
#   - if a systemd user session is available: user unit, enabled and started,
#     plus ~/.config/claudeck/env (port), created only if missing
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO/src/claudeck"
BIN="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
CONF_DIR="$HOME/.config/claudeck"

if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' 2>/dev/null; then
  echo "claudeck needs Python 3.9 or newer as python3." >&2
  exit 1
fi

mkdir -p "$BIN"
ln -sfn "$SRC" "$BIN/claudeck"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "Note: $BIN is not in your PATH; add it to run 'claudeck' by name." ;;
esac

if ! command -v systemctl >/dev/null || ! systemctl --user show-environment >/dev/null 2>&1; then
  echo "Installed $BIN/claudeck (no systemd user session: no background service)."
  echo "Run it with: claudeck"
  exit 0
fi

mkdir -p "$UNIT_DIR" "$CONF_DIR"
[ -e "$CONF_DIR/env" ] || cp "$REPO/config/env.example" "$CONF_DIR/env"
cp "$REPO/config/claudeck.service" "$UNIT_DIR/claudeck.service"

systemctl --user daemon-reload
systemctl --user enable --now claudeck.service
systemctl --user restart claudeck.service

# shellcheck disable=SC1091
. "$CONF_DIR/env"
echo "claudeck running: http://localhost:${CLAUDECK_PORT:-8765}/"
