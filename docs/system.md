# System

- [Repos](#repos)
- [The look](#the-look)
- [Hyprland](#hyprland)
- [Monitors and the lid](#monitors-and-the-lid)
- [Idle and sleep](#idle-and-sleep)
- [Services](#services)

## Repos

Hyprland is not in the official Fedora 45 repos, and Fedora's Quickshell is an old 0.2.x snapshot, so two COPRs are
added. Each is limited with `includepkgs=` to exactly the packages needed; everything else in them is invisible to dnf,
so they can never replace a Fedora package (the Hyprland COPR ships its own kitty and waybar, for example).

| Repo file in `system/repos/` | Allowed packages |
|---|---|
| [sdegler/hyprland](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/) | Hyprland, hypr* tools, their libraries |
| [errornointernet/quickshell](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell/) | `quickshell`, `cpptrace` |

If an update fails with `nothing provides <X>`, add `<X>` to that repo's `includepkgs`, then run
`./install.sh repos packages`.

Quickshell uses Qt private APIs. When Fedora updates Qt, dnf may hold the Qt update back for a few days until the COPR
rebuilds Quickshell. That is expected.

## The look

Palette **"Carbon & Pewter"**: a neutral base, grey text, one pewter (grey-blue) accent and muted status colours. It
comes in two versions, dark (near-black `#111111`) and light (warm off-white `#ececea`); see
[light and dark](features.md#light-and-dark) for the switch. Font: **Maple Mono NF** everywhere (bar, notifications,
launcher, lock screen, terminal). It is not in Fedora, so `./install.sh fonts` downloads the exact version in
`system/fonts.txt` and verifies its checksum. To use another font, change `fontFamily` in `Theme.qml` (and
`font_family` in `hyprlock.conf` and `kitty.conf`).

Both versions are defined in `home/quickshell/.config/quickshell/Theme.qml` (each colour is one line,
`dark ? "<dark>" : "<light>"`) and repeated in:

| File | Dark | Light |
|---|---|---|
| `hypr/modules/look.lua` (window borders, shadow) | yes | yes |
| `kitty/dark-theme.auto.conf`, `light-theme.auto.conf` | yes | yes |
| `gtk-4.0/gtk.css`, `gtk-3.0/dark.css` and `light.css` | yes | yes |
| Neovim's `colors/mono.lua` | yes | yes |
| `hypr/hyprlock.conf`, the SDDM theme | yes | no: light text over the darkened wallpaper in both schemes |

Change them all to re-theme; `scripts/ui-check` fails if they drift apart. The prompt, fzf and the installer's output
use the terminal's 16 colours, so they follow kitty's theme and need no change.

## Hyprland

Log in by picking **Hyprland (uwsm-managed)** in SDDM. The config is Lua (Hyprland 0.57+), split by topic in
`home/hypr/.config/hypr/modules/`: `monitors`, `input`, `look`, `rules`, `binds`, `autostart`, `tablet`. Hyprland reloads
on save; `./install.sh link` also checks it with `Hyprland --verify-config`.

Sway is still installed as a fallback session: if Hyprland ever fails to start, pick Sway in SDDM. Its leftover launcher
entries are hidden (see [features](features.md#hiding-apps-and-autostart-entries)).

Quickshell does as much as possible (bar, launcher, notifications, wallpaper, OSDs). The hypr* tools cover what is safer
outside the shell: `hypridle`, `hyprpolkitagent` and `hyprlock` (the lock screen). File manager: Nautilus.

Session environment variables go in `home/uwsm/.config/uwsm/env-hyprland`, not `hl.env()`, so systemd services and apps
get them too. Apps are launched with `uwsm app -- <cmd>`, so each runs in its own systemd scope.

## Monitors and the lid

The laptop `eDP-1` (1920x1200, scaled 1.2) sits on the left, bottom-aligned with the Samsung `HDMI-A-1` (2560x1440) in
the centre, which is the main screen. Workspaces 1-7 live on the main screen, 8-10 on the laptop. Change the laptop scale
with `laptopScale` in `modules/monitors.lua`; positions follow automatically.

**The lid.** With another monitor connected, closing the lid turns the laptop screen off and Hyprland moves workspaces 8-10
(and their windows) to the main monitor. Opening the lid reloads the config, the screen comes back, and those workspaces go
home. Starting with the lid shut keeps the laptop screen off, and unplugging the monitor while the lid is shut turns it
back on so you are never left without a display. With no other monitor, closing the lid suspends as usual.

## Idle and sleep

`hypridle.conf`: dim at 2.5 min, lock at 5, screens off at 5.5, suspend at 30. Dimming covers every screen the shell can
control (the laptop panel and, over DDC, the external monitor) down to 10% (`idleDimLevel` in `Theme.qml`), quietly (no
indicator), and puts each back as it was; without the shell running, only the laptop dims. Apps that are playing media
prevent all of this automatically.

## Services

`system/services.sh` turns off what this bare-metal laptop does not use: VM guest tools, live-ISO units,
iSCSI / RAID / LVM / Stratis, ModemManager, sssd, homed, CUPS, Avahi, PackageKit (masked). Bluetooth stays on.
`system/user-services.sh` turns on quickshell, hypridle, hyprpolkitagent and bt-agent and turns off obex.

Each list is a set of `svc_group on|off|mask "<what they are>" units...` lines (helpers in `scripts/lib/svc.sh`). A run
prints one line per group with its state (`✓ off  printing  cups.socket cups.path cups`) and a line per unit it actually
changes. `./install.sh -n services` shows the real state without needing root.

To undo one: `sudo systemctl unmask <unit> && sudo systemctl enable --now <unit>`.

## Handwriting recognition service

`hw-ocr` turns a PNG of one handwritten line (dark ink on white, any size) into text, locally on the CPU, with the
fine-tuned TrOCR model in `~/handwriting/models/trocr-small-ft` (the training code and data live in `~/handwriting`).

It is **socket-activated**: `hw-ocr.socket` listens on `$XDG_RUNTIME_DIR/hw-ocr.sock` and costs nothing. The first
connection starts `hw-ocr.service`, which loads the model (about 3 s, then ~700 MB of RAM) and exits after 10 idle
minutes; the next connection starts it again. `./install.sh link` puts the files in place and `./install.sh services`
enables the socket (it only needs your user, but that step also runs the root part).

| Piece | Where |
|---|---|
| client | `home/bin/.local/bin/hw-ocr`: `hw-ocr line.png` prints the text, `hw-ocr warm` preloads the model |
| daemon, clean-up, tests | `home/bin/.local/share/hw-ocr/` (`hw_ocrd.py`, `hw_post.py`, `hw_chunk.py`, `test_post.py`) |
| units | `home/systemd/.config/systemd/user/hw-ocr.{socket,service}` |

Protocol (one request line, one JSON reply line, requests served one at a time): `warm` gives `{"ok":true}`; an
absolute path to a PNG gives `{"text":"...","ms":123}` or `{"error":"..."}`.

- Output is cleaned conservatively (`hw_post.py`): trailing ` .` removed, `localhost : 8080` and `https : //` joined.
  Run the tests with `python3 home/bin/.local/share/hw-ocr/test_post.py`.
- Lines wider than 9:1 are split at wide blank gaps and recognised in pieces (the model squashes every image to
  384x384, so long lines lose detail): on 16 synthetic 12-15:1 lines this cut the character error from 11% to 2.6%.
- Settings (`systemctl --user edit hw-ocr`, then `[Service] Environment=...`): `HW_MODEL`, `HW_PYTHON` (default
  `~/handwriting/venv/bin/python`), `HW_THREADS` (8), `HW_IDLE` (600 s), `HW_CHUNK=0` (no splitting), `HW_BEAMS` (3; 1 = fastest).
- Logs: `journalctl --user -u hw-ocr`. Typical speed once loaded: 0.25 to 0.4 s per line; the first request after
  idle takes about 3 s.
