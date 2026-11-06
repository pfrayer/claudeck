#!/usr/bin/env bash
# Arrête et retire l'unit et le lien. Laisse ~/.config/cc-sessions-web/env en place.
set -euo pipefail
systemctl --user disable --now cc-sessions-web.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/cc-sessions-web.service" "$HOME/bin/cc-sessions-web"
systemctl --user daemon-reload
echo "cc-sessions-web désinstallé (config conservée dans ~/.config/cc-sessions-web/)"
