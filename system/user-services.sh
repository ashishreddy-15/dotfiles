#!/usr/bin/env bash
# Your systemd USER services (run as your normal user, no sudo). Called by `./install.sh services`. Re-running is safe.
# DRY_RUN=1 shows what would change.
#
# Units turned on here are WantedBy=graphical-session.target, so they start at the next login.
# Drop-ins in home/systemd/ limit Hyprland helpers to Hyprland sessions.
set -u
here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$here/../scripts/lib/ui.sh"
SVC="systemctl --user"
SVC_NOW=0           # enabled now, started with the session
source "$here/../scripts/lib/svc.sh"

(( EUID != 0 )) || die "run as your normal user, not root"

(( DRY_RUN )) || systemctl --user daemon-reload

svc_group on  "desktop shell: bar, launcher"   quickshell.service
svc_group on  "idle: lock, screen off, sleep"  hypridle.service
svc_group on  "password prompts for apps"      hyprpolkitagent.service
svc_group on  "Bluetooth pairing prompts"      bt-agent.service
svc_group off "Bluetooth file transfer"        obex.service
svc_missing_note

# Tablet ExpressKeys: udev starts tablet-keys@<event node> when a pad is plugged in (system/udev/70-tablet-pad.rules).
# For a pad that is already plugged in when the rule is installed, start it now.
if [[ -f /etc/udev/rules.d/70-tablet-pad.rules ]]; then
  for dev in /sys/class/input/event*; do
    [[ $(cat "$dev/device/name" 2>/dev/null) == Wacom*Pad ]] || continue
    unit="tablet-keys@${dev##*/}.service"
    if systemctl --user is-active -q "$unit"; then ok "tablet ExpressKeys running"
    elif (( DRY_RUN )); then would "start the tablet ExpressKeys"
    else systemctl --user start "$unit" && done_ "started the tablet ExpressKeys"
    fi
  done
fi
exit 0
