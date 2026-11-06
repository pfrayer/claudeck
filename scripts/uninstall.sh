#!/usr/bin/env bash
# Stops and removes the unit and the symlink. Leaves ~/.config/cc-sessions-web/env in place.
set -euo pipefail
if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user disable --now cc-sessions-web.service 2>/dev/null || true
  rm -f "$HOME/.config/systemd/user/cc-sessions-web.service"
  systemctl --user daemon-reload
fi
rm -f "$HOME/.local/bin/cc-sessions-web"
echo "cc-sessions-web uninstalled (config kept in ~/.config/cc-sessions-web/)"
