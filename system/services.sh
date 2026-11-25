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
# Core Proton VPN + D-Bus kill switch keep working; only app-based split tunneling needs this daemon (~182 MiB).
svc_group off  "Proton VPN split tunneling" me.proton.vpn.split_tunneling.service
# systemd-journald already persists logs under /var/log/journal/; rsyslog just duplicates them to /var/log/messages.
svc_group off  "duplicate syslog (journald)" rsyslog.service
# No cron jobs installed; Fedora maintenance runs on systemd timers.
svc_group off  "cron (using systemd timers)" crond.service
# Single-socket laptop: kernel MSI-X affinity handles IRQs, and 10 s polling inhibits deeper package C-states.
svc_group off  "IRQ balancer (10s wakeup)"  irqbalance.service
# Single NVMe: the kernel nvme driver already logs critical faults, and no local MTA is configured.
svc_group off  "NVMe SMART poller"          smartd.service
# Non-ECC laptop RAM: fatal MCEs still hit kernel dmesg/journald/pstore.
svc_group off  "MCE logger"                 mcelog.service
# Avoid 3-hourly background dnf5 spikes on AC and daily plocate NVMe scans (use `dup`/`fd`/`rg`).
svc_group off  "background cache timers"    dnf-makecache.timer plocate-updatedb.timer
# SDDM + Hyprland handle graphics; use plain agetty on tty1 instead of GPU-rendered kmscon.
svc_group off  "GPU VT console (kmscon)"    kmsconvt@tty1.service
SVC_NOW=0
svc_group on   "plain VT console (tty1)"    getty@tty1.service
SVC_NOW=1

# ---- masked: these start on demand over D-Bus, so disabling alone is not enough ----
svc_group mask "GNOME Software backend (use dnf)" packagekit.service

svc_missing_note

# ALSA mixer state: removing /etc/alsa/state-daemon.conf lets Fedora use one-shot alsa-restore.service
# (0 persistent RAM) instead of the resident `alsactl rdaemon` (~4 MiB); PipeWire manages runtime volumes.
if [[ -e /etc/alsa/state-daemon.conf ]]; then
  if (( DRY_RUN )); then
    would "switch ALSA from resident alsactl daemon to one-shot restore (remove /etc/alsa/state-daemon.conf)"
  else
    systemctl stop alsa-state.service >/dev/null 2>&1 || true
    rm -f /etc/alsa/state-daemon.conf
    gone "removed /etc/alsa/state-daemon.conf (ALSA now uses one-shot alsa-restore)"
  fi
else
  ok "ALSA mixer uses one-shot restore (no resident alsactl daemon)"
fi

# Helper: install drop-in config files from $1/*.conf into $2; returns 0 if any changed.
install_dropins() {
  local src_dir=$1 dest_dir=$2 label=$3 f new=()
  compgen -G "$src_dir/*.conf" >/dev/null || return 1
  for f in "$src_dir"/*.conf; do
    cmp -s "$f" "$dest_dir/${f##*/}" 2>/dev/null || new+=("${f##*/}")
  done
  if (( ${#new[@]} == 0 )); then
    ok "$label in place ($(cd "$src_dir" && echo *.conf))"
    return 1
  fi
  if (( DRY_RUN )); then
    would "install $label: ${new[*]}"
    return 1
  fi
  install -d -m 755 "$dest_dir"
  install -m 644 "$src_dir"/*.conf "$dest_dir/"
  done_ "installed $label: ${new[*]}"
  return 0
}

if install_dropins "$here/sysctl" /etc/sysctl.d "kernel/zram tuning"; then
  sysctl --system >/dev/null
fi
if install_dropins "$here/networkmanager" /etc/NetworkManager/conf.d "Wi-Fi power save"; then
  systemctl reload NetworkManager.service >/dev/null 2>&1 || true
fi

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
