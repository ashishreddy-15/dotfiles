#!/usr/bin/env bash
# Enable/disable systemd USER services (run as your normal user, no sudo).
# Called by `./install.sh services`. Re-running is safe.
#
# Units enabled here are WantedBy=graphical-session.target, so they start at the
# next login. Drop-ins in home/systemd/ limit Hyprland helpers to Hyprland sessions.
set -u

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user, not root." >&2
  exit 1
fi

ENABLE=(
  hypridle.service          # idle -> lock / screens off / suspend
  hyprpolkitagent.service   # password prompts for GUI apps
)

DISABLE=(
  obex.service              # Bluetooth file transfer (headsets/mice don't need it)
)

systemctl --user daemon-reload

for u in "${ENABLE[@]}"; do
  if systemctl --user cat "$u" &>/dev/null; then
    systemctl --user enable "$u" >/dev/null 2>&1 && echo "enabled (user):  $u"
  else
    echo "skip (not installed): $u"
  fi
done

for u in "${DISABLE[@]}"; do
  if systemctl --user cat "$u" &>/dev/null; then
    systemctl --user disable --now "$u" >/dev/null 2>&1 && echo "disabled (user): $u"
  fi
done
