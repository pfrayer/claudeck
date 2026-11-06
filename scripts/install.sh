#!/usr/bin/env bash
# Installe cc-sessions-web pour l'utilisateur courant :
#   - lien ~/bin/cc-sessions-web -> src/cc-sessions-web
#   - unit systemd utilisateur, activée et démarrée
#   - ~/.config/cc-sessions-web/env (port), créé seulement s'il n'existe pas
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HOME/bin"
UNIT_DIR="$HOME/.config/systemd/user"
CONF_DIR="$HOME/.config/cc-sessions-web"

mkdir -p "$BIN" "$UNIT_DIR" "$CONF_DIR"
ln -sfn "$REPO/src/cc-sessions-web" "$BIN/cc-sessions-web"
[ -e "$CONF_DIR/env" ] || cp "$REPO/config/env.example" "$CONF_DIR/env"
cp "$REPO/config/cc-sessions-web.service" "$UNIT_DIR/cc-sessions-web.service"

systemctl --user daemon-reload
systemctl --user enable --now cc-sessions-web.service
systemctl --user restart cc-sessions-web.service

# shellcheck disable=SC1091
. "$CONF_DIR/env"
echo "cc-sessions-web actif : http://localhost:${CC_SESSIONS_WEB_PORT:-8765}/"
