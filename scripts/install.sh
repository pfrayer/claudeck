#!/usr/bin/env bash
# Installs cc-sessions-web for the current user:
#   - symlink ~/.local/bin/cc-sessions-web -> src/cc-sessions-web
#   - if a systemd user session is available: user unit, enabled and started,
#     plus ~/.config/cc-sessions-web/env (port), created only if missing
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO/src/cc-sessions-web"
BIN="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
CONF_DIR="$HOME/.config/cc-sessions-web"

if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' 2>/dev/null; then
  echo "cc-sessions-web needs Python 3.9 or newer as python3." >&2
  exit 1
fi

mkdir -p "$BIN"
ln -sfn "$SRC" "$BIN/cc-sessions-web"

# Older versions linked from ~/bin: remove that link if it points here.
OLD="$HOME/bin/cc-sessions-web"
if [ -L "$OLD" ] && [ "$(readlink "$OLD")" = "$SRC" ]; then
  rm -f "$OLD"
  echo "Removed old link $OLD"
fi

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "Note: $BIN is not in your PATH; add it to run 'cc-sessions-web' by name." ;;
esac

if ! command -v systemctl >/dev/null || ! systemctl --user show-environment >/dev/null 2>&1; then
  echo "Installed $BIN/cc-sessions-web (no systemd user session: no background service)."
  echo "Run it with: cc-sessions-web"
  exit 0
fi

mkdir -p "$UNIT_DIR" "$CONF_DIR"
[ -e "$CONF_DIR/env" ] || cp "$REPO/config/env.example" "$CONF_DIR/env"
cp "$REPO/config/cc-sessions-web.service" "$UNIT_DIR/cc-sessions-web.service"

systemctl --user daemon-reload
systemctl --user enable --now cc-sessions-web.service
systemctl --user restart cc-sessions-web.service

# shellcheck disable=SC1091
. "$CONF_DIR/env"
echo "cc-sessions-web running: http://localhost:${CC_SESSIONS_WEB_PORT:-8765}/"
