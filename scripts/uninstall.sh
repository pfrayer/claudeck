#!/usr/bin/env bash
# Stops and removes the unit and the symlink. Leaves ~/.config/cc-sessions-web/env in place.
set -euo pipefail
systemctl --user disable --now cc-sessions-web.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/cc-sessions-web.service" "$HOME/bin/cc-sessions-web"
systemctl --user daemon-reload
echo "cc-sessions-web uninstalled (config kept in ~/.config/cc-sessions-web/)"
