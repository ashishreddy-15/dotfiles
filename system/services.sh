#!/usr/bin/env bash
# System services: which are on, which are off on this laptop.
# Run by `./install.sh services` (or: sudo bash ~/dotfiles/system/services.sh). Re-running is safe.
# DRY_RUN=1 bash system/services.sh shows what would change, without root.
# To undo one: sudo systemctl unmask <unit> && sudo systemctl enable --now <unit>
set -u
here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$here/../scripts/lib/ui.sh"
source "$here/../scripts/lib/svc.sh"

(( EUID == 0 || DRY_RUN )) || die "run as root: sudo bash $0"

# ---- kept on (and turned back on if an earlier run turned them off) ----
svc_group on   "Bluetooth"                  bluetooth.service

# ---- off: disabled and stopped (can be turned on again any time) ----
svc_group off  "virtual machine guest tools" vboxservice.service vmtoolsd.service vgauthd.service qemu-guest-agent.service
svc_group off  "live-USB installer leftovers" livesys.service livesys-late.service
# The disk is LUKS + btrfs: no LVM, RAID, Stratis or iSCSI.
svc_group off  "unused storage stacks"      iscsi-onboot.service iscsi-starter.service iscsid.socket iscsiuio.socket \
                                            mdmonitor.service raid-check.timer lvm2-monitor.service lvm2-lvmpolld.socket \
                                            dm-event.socket stratisd.service
svc_group off  "mobile broadband modem"     ModemManager.service
# authselect profile is "local", no homed users.
svc_group off  "enterprise / remote login"  sssd.service sssd-kcm.socket systemd-homed.service systemd-homed-activate.service
svc_group off  "smart-card reader"          pcscd.socket
svc_group off  "printing"                   cups.socket cups.path cups.service
svc_group off  "network discovery (mDNS)"   avahi-daemon.socket avahi-daemon.service
svc_group off  "'at' job scheduler"         atd.service
svc_group off  "waiting for network at boot" NetworkManager-wait-online.service

# ---- masked: these start on demand over D-Bus, so disabling alone is not enough ----
svc_group mask "GNOME Software backend (use dnf)" packagekit.service

svc_missing_note

(( DRY_RUN )) && exit 0

# Monitor brightness over DDC/CI (ddcutil) needs access to /dev/i2c-*. The ddcutil package ships a udev rule that
# grants it to the logged-in user, but only devices created after the package was installed get it: without
# this, a reboot would be needed. Re-applying the rules fixes that at once (no logout needed); harmless to repeat.
if command -v ddcutil >/dev/null; then
  udevadm trigger --subsystem-match=i2c-dev && udevadm settle
fi

# Our udev rules (system/udev/*.rules), e.g. the tablet pad's ExpressKeys: install them and apply them at once, so the
# device does not have to be plugged in again.
rules_dir="$here/udev"
if compgen -G "$rules_dir/*.rules" >/dev/null; then
  new=()
  for f in "$rules_dir"/*.rules; do
    cmp -s "$f" "/etc/udev/rules.d/${f##*/}" || new+=("${f##*/}")
  done
  if (( ${#new[@]} )); then
    install -m 644 "$rules_dir"/*.rules /etc/udev/rules.d/
    udevadm control --reload
    udevadm trigger --subsystem-match=input --action=change && udevadm settle
    done_ "installed device rules: ${new[*]}"
  else
    ok "device rules in place ($(cd "$rules_dir" && echo *.rules))"
  fi
fi
exit 0
