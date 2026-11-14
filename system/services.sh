#!/usr/bin/env bash
# Disable system services this laptop doesn't need.
# Run with: sudo bash ~/dotfiles/system/services.sh
# Re-running is safe. To undo one: sudo systemctl unmask <unit> && sudo systemctl enable --now <unit>
set -u

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

# Disabled + stopped (can be re-enabled any time)
DISABLE=(
  # Virtual machine guest tools (this is bare metal)
  vboxservice.service vmtoolsd.service vgauthd.service qemu-guest-agent.service
  # Leftovers from the live ISO installer
  livesys.service livesys-late.service
  # Storage stacks not in use (disk is LUKS + btrfs, no LVM/RAID/Stratis/iSCSI)
  iscsi-onboot.service iscsi-starter.service iscsid.socket iscsiuio.socket
  mdmonitor.service raid-check.timer
  lvm2-monitor.service lvm2-lvmpolld.socket dm-event.socket
  stratisd.service
  # No mobile-broadband modem
  ModemManager.service
  # Enterprise/remote login (authselect profile is "local", no homed users)
  sssd.service sssd-kcm.socket
  systemd-homed.service systemd-homed-activate.service
  # Smart-card reader daemon
  pcscd.socket
  # Not wanted: printing, mDNS discovery
  cups.socket cups.path cups.service
  avahi-daemon.socket avahi-daemon.service
  # Misc
  atd.service                          # `at` job scheduler
  NetworkManager-wait-online.service   # only delays boot
)

# Masked: started on demand over D-Bus, so disabling alone isn't enough
MASK=(
  packagekit.service   # GNOME Software backend; use dnf instead
)

# Kept on (and re-enabled if an earlier run turned them off)
ENABLE=(
  bluetooth.service    # basic Bluetooth; pair with `bluetoothctl`
)

for u in "${ENABLE[@]}"; do
  systemctl unmask "$u" >/dev/null 2>&1
  systemctl enable --now "$u" >/dev/null 2>&1 && echo "enabled:  $u"
done

for u in "${DISABLE[@]}"; do
  if systemctl cat "$u" &>/dev/null; then
    systemctl disable --now "$u" 2>&1 | grep -v '^Removed' || true
    echo "disabled: $u"
  else
    echo "skip (not installed): $u"
  fi
done

for u in "${MASK[@]}"; do
  systemctl stop "$u" 2>/dev/null
  systemctl mask "$u" >/dev/null 2>&1 && echo "masked:   $u"
done

# User-level: Bluetooth OBEX file transfer (sending files to/from phones; not needed for headsets/mice)
if [[ -n "${SUDO_USER:-}" ]]; then
  sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" \
    systemctl --user disable --now obex.service >/dev/null 2>&1 && echo "disabled (user): obex.service"
fi

echo "Done."
