# dotfiles

Fedora 45 + Hyprland setup for a laptop with an external monitor.
Everything is edited **here**; files in `~/.config` are only symlinks into this repo.

## Quick start

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh -n     # dry run: shows every change, touches nothing
./install.sh        # do it
```

Re-running `./install.sh` is always safe: each step checks what's already done.

## Layout

```
dotfiles/
├── install.sh              # bootstrap script (see below)
├── scripts/                # helpers: gen-wallpapers.py (makes the wallpapers; needs Pillow)
├── packages/               # what to dnf install, one package per line
│   ├── hyprland.txt        #   compositor + hypr* tools (Hyprland COPR)
│   ├── quickshell.txt      #   desktop shell (Quickshell COPR)
│   ├── desktop.txt         #   apps and tools (official Fedora)
│   └── remove.txt          #   packages to uninstall (e.g. Thunar)
├── system/                 # root-level config (copied, never symlinked)
│   ├── repos/*.repo        #   -> /etc/yum.repos.d/
│   ├── fonts.txt           #   fonts to download (pinned URL + sha256)
│   ├── services.sh         #   system services (sudo)
│   └── user-services.sh    #   systemd --user units (hypridle, polkit agent, quickshell)
└── home/                   # stow packages, each mirrors $HOME
    ├── autostart/          # hides unwanted /etc/xdg/autostart entries
    ├── hypr/               # ~/.config/hypr: hyprland.lua + modules/, hypridle, hyprlock
    ├── kitty/              # terminal: font + colours
    ├── quickshell/         # the desktop shell (QML): Theme.qml, shell.qml, bar/
    ├── systemd/            # quickshell.service + drop-ins limiting hypr* services to Hyprland
    └── uwsm/               # ~/.config/uwsm/env-hyprland: session environment
```

## install.sh

| Command                     | What it does                                              |
|-----------------------------|-----------------------------------------------------------|
| `./install.sh`              | all steps: `repos packages fonts wallpapers link services defaults` |
| `./install.sh <step>...`    | only those steps, e.g. `./install.sh link`                |
| `./install.sh -n`           | dry run                                                   |
| `./install.sh -y`           | don't ask dnf for confirmation                            |
| `./install.sh unlink`       | remove every dotfile symlink from `$HOME`                 |

Run it as your normal user; it calls `sudo` only for the steps that need root.

Guarantees:
- **Nothing is overwritten.** If a real file sits where a symlink should go, it is
  moved to `~/.dotfiles-backup/<timestamp>/` first and the script tells you.
- **All or nothing linking.** Stow runs in simulation mode first. If any package
  would fail, `$HOME` is left untouched.
- **Stops at the first error** (`set -Eeuo pipefail`) and prints the failing line.

## Common tasks

**Add a program's config**
```sh
mkdir -p home/<app>/.config/<app>
mv ~/.config/<app>/<file> home/<app>/.config/<app>/   # or write a new one
./install.sh link
```
Stow links individual files (`--no-folding`), so apps that write caches or state
into `~/.config/<app>` don't end up writing into this repo.

**Add / remove a package:** add a line to the right `packages/*.txt` (or to
`packages/remove.txt` to uninstall it), then `./install.sh packages`. Removals also
drop dependencies nothing else needs. A package in both lists is an error.

**Change a default app:** edit `MIME_DEFAULTS` at the top of `install.sh`, then `./install.sh defaults`.

**Disable or enable a service:** edit the lists in `system/services.sh`, then `./install.sh services`.

**Hide a `/etc/xdg/autostart` entry:** copy one of the files in
`home/autostart/.config/autostart/`, rename it to match the system entry, then run `./install.sh link`.

## Repos

Hyprland isn't in the official Fedora 45 repos, and Fedora's Quickshell is an old
0.2.x snapshot, so two COPRs are added. Each is limited with `includepkgs=` to
exactly the packages needed. Everything else in them is invisible to dnf, so they
can never replace a Fedora package (the Hyprland COPR ships its own kitty and waybar, for example).

| Repo file in `system/repos/` | Allowed packages |
|---|---|
| [sdegler/hyprland](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/) | Hyprland, hypr* tools, their libraries |
| [errornointernet/quickshell](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell/) | `quickshell`, `cpptrace` |

If an update fails with `nothing provides <X>`, add `<X>` to that repo's
`includepkgs`, then run `./install.sh repos packages`.

Quickshell uses Qt private APIs. When Fedora updates Qt, dnf may hold the Qt
update back for a few days until the COPR rebuilds Quickshell. That's expected.

## Look

Palette "Carbon & Pewter": neutral near-black base (#111111), dim grey text, one pewter (grey-blue) accent, muted
status colours. Font: **Maple Mono NF** everywhere (bar 12 px, notifications, launcher, lock screen,
terminal). It is not in Fedora, so `./install.sh fonts` downloads the
exact version listed in `system/fonts.txt` and verifies its checksum. To use another font, change
`fontFamily` in `Theme.qml` (and `font_family` in `hyprlock.conf`, `font_family` in `kitty.conf`).

The palette is defined in `home/quickshell/.config/quickshell/Theme.qml` and repeated
in `hypr/modules/look.lua`, `hypr/hyprlock.conf` and `kitty/kitty.conf`. Change all
four to re-theme.

## Quickshell

After adding a new file run `./install.sh link` (stow links file by file).

Runs as `quickshell.service` (Hyprland sessions only). It reloads when a file is saved in
place; if a change does not show up (some tools replace the file instead), restart it.

```sh
systemctl --user restart quickshell      # restart
journalctl --user -u quickshell -f       # logs / QML errors
```

- `Theme.qml`: colours, fonts, sizes, and which monitor is the main one
- `shell.qml`: entry point listing each piece
- `ShellState.qml`: on/off switches reachable from keybinds (`qs ipc call bar toggle`)
- `bar/`: menu bar on every monitor with no background, so its text sits directly on the
  wallpaper (`barOpacity` in `Theme.qml`; raise it for a solid strip).
  Left: workspaces (`[1] 2 3`) and the focused app's name. Right: clock.
  The bar is "quiet": status only appears on the main monitor when it needs attention:

  | Item | Shown when |
  |---|---|
  | `bat` | 30% or less, or charging |
  | `vol` | muted |
  | `wifi` / `net` | there is no connection |
  | `bt` | a device is connected |

  `Super + B` hides or shows the bar. If the main monitor is unplugged, the laptop's
  bar takes over the status area.
- `notifications/`: Quickshell is the notification daemon. Pop-ups drop down from the
  top-centre of the main monitor, newest on top, up to 4 at once. Normal ones close
  after 5 s (paused while hovered); critical ones stay. Click to dismiss.
  dunst (from the Sway spin) is kept out of Hyprland by a systemd drop-in.
- `osd/`: small volume / brightness indicator at the bottom-centre of the main monitor.
  Volume shows on any change; brightness shows when the brightness keys are used
  (they call `qs ipc call osd brightness`), so idle dimming stays silent.
- `picker/Picker.qml`: the shared Spotlight-style window (search field + list) that the launcher and
  the clipboard history are built on. Up/Down or Tab to move, Enter to choose, Esc or a click
  outside to close. The window has a fixed size and only the card inside it grows and shrinks;
  Hyprland's own fade is switched off for these windows (`rules.lua`). Resizing the window per
  keystroke made the first version smear. New pickers (power menu, ...) should reuse it.
- `launcher/`: app launcher (`Super + Space`). Results appear as you type (name, then
  description/keywords, then letters-in-order). `qs ipc call launcher search <text>` opens it prefilled.
- `clipboard/`: clipboard history (`Super + V`) from `cliphist` (fed by `wl-paste --watch` in
  `autostart.lua`). Shows the latest entries; typing filters the whole history. Enter copies the entry
  back to the clipboard; paste with Ctrl+V. Multi-line entries show on one line but are restored exactly.
- `wallpaper/`: wallpaper on every monitor, cross-fading (about 0.3 s) when it changes. `Super + W`
  picks one; `qs ipc call wallpaper next` cycles; `qs ipc call wallpaper set <file>` uses any image.
  It lists `~/.local/share/wallpapers` (five generated ones that look clearly different: carbon, contours,
  dusk, pewter-glow, slate; made by `./install.sh wallpapers`, which remakes them when the designs change) and `~/Pictures/Wallpapers` (**put your own images there**;
  png, jpg, webp). The choice is remembered in `~/.local/state/dotfiles/wallpaper`.
  The bar has no background of its own. When the top edge of a wallpaper is light (measured when
  you pick it), the bar automatically gets a dark blurred background so its text stays readable;
  `brightWallpaper` and `barBackdropOpacity` in `Theme.qml` tune that.
- `panel/`: quick settings. Click the clock area of the bar (or `Super + A`) to open a panel under it:
  volume slider (click `vol` to mute) and output device, Wi-Fi (on/off, networks, password prompt for new
  secured ones), Bluetooth (on/off, devices, scan and pair), wallpaper (opens the picker) and the power
  actions `lock logout suspend reboot shutdown`; logout, reboot and shutdown ask for a second click.
  Wi-Fi and Bluetooth scan only while their list is open. Esc or a click outside closes it.
  `qs ipc call panel open <out|wifi|bt>` opens it with a list expanded.

## Desktop

Quickshell does as much as possible: bar, launcher, notifications, wallpaper, OSDs.
The hypr* tools cover what's safer outside the shell: `hypridle`, `hyprpolkitagent`,
and `hyprlock` as a fallback lock screen in case the Quickshell lock crashes.
File manager: Nautilus.

## Hyprland

Log in by picking **Hyprland (uwsm-managed)** in SDDM. The config is Lua
(Hyprland 0.57+), split by topic in `home/hypr/.config/hypr/modules/`:
`monitors`, `input`, `look`, `rules`, `binds`, `autostart`. Hyprland reloads
on save; `./install.sh link` also checks it with `Hyprland --verify-config`.

Monitors: laptop `eDP-1` (1920x1200, scaled 1.2) on the left, Samsung `HDMI-A-1` (2560x1440)
in the centre as the main screen. Workspaces 1-9 are on the main screen, 10 on the laptop.
Change the laptop scale with `laptopScale` in `modules/monitors.lua`; positions follow automatically.

| Keys | Action |
|---|---|
| `Super + Return` / `E` / `Space` | terminal (kitty) / files (Nautilus) / app launcher |
| `Super + Q` | close window |
| `Super + F` / `M` | fullscreen / maximize |
| `Super + Shift + Space` | toggle floating |
| `Super + arrows` or `h j k l` | move focus (crosses to the other monitor at the edge) |
| `Super + Shift + arrows` or `h j k l` | move window |
| `Super + ,` / `.` | focus laptop / main monitor (`+ Shift`: send window there) |
| `Super + 1..0` | workspace 1-10 (`+ Shift`: move window there) |
| `Super + Tab` | previous workspace |
| `Super + S` | scratchpad (`+ Shift`: send window there) |
| `Super + V` | clipboard history |
| `Super + W` | choose wallpaper |
| `Super + A` | quick settings (also: click the clock) |
| `Print` / `Shift + Print` | screenshot region / whole monitor, to clipboard |
| `Super + B` | hide / show the bar |
| `Super + Escape` | lock |
| `Super + Shift + E` | log out |

Idle (`hypridle.conf`): dim at 2.5 min, lock at 5, screens off at 5.5, suspend at 30.
Apps that are playing media prevent this automatically.

Session environment variables go in `home/uwsm/.config/uwsm/env-hyprland`, not
`hl.env()`, so systemd services and apps get them too. Apps are launched with
`uwsm app -- <cmd>` so each runs in its own systemd scope.

## Services

`system/services.sh` turns off what this bare-metal laptop doesn't use: VM guest
tools, live-ISO units, iSCSI/RAID/LVM/Stratis, ModemManager, sssd, homed, CUPS,
Avahi, PackageKit (masked). Bluetooth stays on.
`system/user-services.sh` enables hypridle and hyprpolkitagent and disables obex. To undo one:
`sudo systemctl unmask <unit> && sudo systemctl enable --now <unit>`.
