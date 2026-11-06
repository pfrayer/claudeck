#!/usr/bin/env bash
# Stops and removes the unit and the symlink. Leaves ~/.config/claudeck/env in place.
set -euo pipefail
if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user disable --now claudeck.service 2>/dev/null || true
  rm -f "$HOME/.config/systemd/user/claudeck.service"
  systemctl --user daemon-reload
fi
rm -f "$HOME/.local/bin/claudeck"
echo "claudeck uninstalled (config kept in ~/.config/claudeck/)"
