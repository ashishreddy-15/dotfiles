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
├── scripts/                # helpers: ui-check (guard rails for the look)
├── packages/               # what to dnf install, one package per line
│   ├── hyprland.txt        #   compositor + hypr* tools (Hyprland COPR)
│   ├── quickshell.txt      #   desktop shell (Quickshell COPR)
│   ├── desktop.txt         #   apps and tools (official Fedora)
│   └── remove.txt          #   packages to uninstall (e.g. Thunar)
├── system/                 # root-level config (copied, never symlinked)
│   ├── repos/*.repo        #   -> /etc/yum.repos.d/
│   ├── sddm/               #   login screen theme "carbon" -> /usr/share/sddm/themes/, and /etc/sddm.conf.d/
│   ├── fonts.txt           #   fonts to download (pinned URL + sha256)
│   ├── wallpapers.txt      #   Unsplash photos to download (pinned URL + sha256)
│   ├── services.sh         #   system services (sudo)
│   └── user-services.sh    #   systemd --user units (hypridle, polkit agent, quickshell)
└── home/                   # stow packages, each mirrors $HOME
    ├── applications/       # hides leftover launcher entries (~/.local/share/applications, NoDisplay)
    ├── autostart/          # hides unwanted /etc/xdg/autostart entries
    ├── bin/                # ~/.local/bin: appearance (GTK look), bt-agent (Bluetooth pairing), screenshot, screenrecord
    ├── gtk/                # ~/.config/gtk-3.0 and gtk-4.0: settings.ini (the defaults) and gtk.css (palette + shape)
    ├── hypr/               # ~/.config/hypr: hyprland.lua + modules/, hypridle, hyprlock
    ├── kitty/              # terminal: font + colours
    ├── quickshell/         # the desktop shell (QML): Theme.qml, shell.qml, bar/
    ├── systemd/            # quickshell.service + drop-ins limiting hypr* services to Hyprland
    └── uwsm/               # ~/.config/uwsm/env-hyprland: session environment
```

## install.sh

| Command                     | What it does                                              |
|-----------------------------|-----------------------------------------------------------|
| `./install.sh`              | all steps: `repos packages fonts wallpapers link services sddm defaults` |
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

**Hide an app from the launcher:** add `home/applications/.local/share/applications/<same file name as the system one>.desktop`
containing `[Desktop Entry]`, `Type=Application`, `Name=...` and `NoDisplay=true`, then run `./install.sh link`.
(Currently hidden: Foot x3, Rofi and its theme selector, Tuned Switcher, Xarchiver: Sway-era leftovers.)
nm-applet no longer starts at login (`home/autostart/`): Wi-Fi is in Settings. It is still installed; run `nm-applet`
by hand if you ever need it.

**Settings:** press `Super + I` (again, or Esc, to close; `Super + Shift + A` opens it on Appearance). It is a window of its own,
centred, with a sidebar: Wi-Fi, Bluetooth, Sound, Display (brightness, night light), Wallpaper (thumbnails), Notifications
(Do Not Disturb, history), Power (profile, battery) and Appearance (colour scheme, GTK / icon / cursor theme, cursor size, fonts).
Keyboard: it opens on the sidebar (Up / Down change section); Right, Enter or Tab go into the section, where Tab or Up / Down
move between controls, Enter and Space press, Left / Right adjust (choices, steppers, sliders, the wallpaper grid; switches only take Space / Enter);
Left on a plain row or Shift+Tab from the first control goes back to the sidebar. Appearance runs `appearance set ...`, which writes gsettings, the two `settings.ini` files (symlinks into
`home/gtk/`, so `git diff` shows what changed and you can commit it) and the running cursor. In a terminal:
`appearance get`, `appearance list gtk|icons|cursors|fonts`, `appearance set font-size 11`.
GTK4 / libadwaita apps (Nautilus, pavucontrol) get the Carbon & Pewter palette in the dark scheme and stock Adwaita
light in the light scheme. GTK3 apps (blueman, file dialogs) always use the dark palette. More GTK themes appear in the
list when installed (for example `sudo dnf install adw-gtk3-theme`).

**Pair a Bluetooth device:** put it in pairing mode, open Settings > Bluetooth and click it. BlueZ's questions (a PIN,
"does this code match?", "may this device connect?") come up as a prompt in the middle of the screen; nothing is
accepted until you click Pair or Allow (Esc declines). The agent behind this is `bt-agent` (user service
`bt-agent.service`; logs: `journalctl --user -u bt-agent -f`). Only `bluetoothd` can call it (system bus policy), and
the computer is pairable only while Settings > Bluetooth is open.

**Login screen (SDDM):** the "carbon" theme in `system/sddm/carbon/` has the same look as the lock screen (no card:
the wallpaper lightly blurred, the date and a large light clock near the top, your name and a frosted password pill
near the bottom; session and power buttons small along the bottom edge). Install or update it
with `./install.sh sddm` (sudo). It copies Maple Mono and your current wallpaper into the theme, because the login
screen cannot read your home folder, so run it again after changing the wallpaper. Preview without logging out:
`sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/carbon`. The cursor is Adwaita everywhere (shell, GTK
apps, login screen).

**Screenshots:** `Print` freezes every screen first (a still frame from `hyprpicker -r`), so the control center,
pop-ups and anything else that closes when it loses focus stay in the shot; then drag a region or click a window.
Every shot goes to `~/Pictures/Screenshots/` and the clipboard, with a notification (`home/bin/.local/bin/screenshot`).

**Screen recording:** `Super + Shift + R` records a region (drag, or click a window), `Super + Ctrl + R` the focused
monitor. Press the same key again, or click the red "rec 0:12" in the bar, to stop. Videos (MP4, H.264) go to
`~/Videos/Recordings/`, with a notification. Silent by default; `screenrecord screen --audio` also records what the
computer plays (`home/bin/.local/bin/screenrecord`).

**Notifications:** pop-ups appear top-centre for a few seconds. Everything you have not dealt with stays in the
**notification centre** (`Super + N`, or the bell in the bar, which shows how many and turns into a crossed bell while
Silence is on): a panel at the right edge, grouped by app ("2 more" expands), with each notification's buttons and x to
dismiss, Silence and Clear all at the top. Opening it clears the pop-ups. Every notification is also kept for 7 days in
an archive on disk (`~/.local/state/dotfiles/notifications.jsonl`, only readable by you, plain text): Settings >
Notifications shows it by day (Today, Yesterday, This week, All) with search and Clear history.

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
- `Notifs.qml` + `notifications/`: Quickshell is the notification daemon (dunst, from the Sway spin, is kept out of
  Hyprland by a systemd drop-in). `Notifs.qml` receives them and keeps a **history** (until you dismiss them) and the
  **pop-ups** on screen. Pop-ups are frosted cards under the bar, top-centre of the main monitor, newest on top,
  up to 4 at once; each runs a thin timeout bar (5 s, paused while hovered; critical ones stay). Click a card or its `×`
  to hide the pop-up (it stays in the history); an action link runs the action. Do Not Disturb hides pop-ups, except
  critical ones, and everything still lands in the history (Settings, Notifications).
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
- `wallpaper/`: wallpaper on every monitor, cross-fading (about 0.3 s) when it changes. Settings > Wallpaper
  picks one (thumbnails); `qs ipc call wallpaper next` cycles; `qs ipc call wallpaper set <file>` uses any image.
  It lists `~/.local/share/wallpapers` (eight Unsplash photos in one mood, atmospheric and muted: fog-forest,
  fog-valley, forest-light, forest-path, moss-valley, canyon, cloud-peak, cloud-sea; fetched by
  `./install.sh wallpapers` from `system/wallpapers.txt`) and `~/Pictures/Wallpapers` (**put your own images there**;
  png, jpg, webp). The picker labels each as
  photo or yours. The choice is remembered in `~/.local/state/dotfiles/wallpaper`.
  The bar has no background of its own, so its text follows the wallpaper, like the macOS menu bar: when
  the top edge of a wallpaper is light (measured when you pick it), the bar switches to dark text, and
  to light text on dark wallpapers. The colours fade over 0.4 s with the wallpaper; the warning/error/ok
  colours get darker versions too. `lightWallpaper` (the switch point) and the `bar*` colours are in `Theme.qml`.
- `Brightness.qml` + `brightness/`: brightness of the screen that has focus. The laptop panel goes through
  `brightnessctl`; an external monitor through `ddcutil` (DDC/CI). Keys: the brightness keys or
  `Super + [` / `Super + ]` (5% steps, held keys repeat). A change shows in the on-screen indicator on that
  screen, or "no control" if the focused screen can't be adjusted. Changes appear instantly and the real
  command is sent a moment later, one at a time (DDC is slow). Setup for the external monitor is below.
- `panel/`: the control center, for the quick things only. Click the clock area of the bar (or `Super + D`) to open it; Esc
  or a click outside closes it. Three bands: a row of round **toggles** (Wi-Fi, Bluetooth, Silence = Do Not Disturb,
  Night light, Keep awake; filled when on), thick **pill sliders** with the icon inside (a brightness per screen, volume,
  mic; click the icon to mute; the name turns into the value while you hover, drag or focus it), and the **media** card
  while something plays. Footer: the battery (opens Settings > Power), Settings, and the power menu (`Super + X`).
  Keyboard: Up / Down (or Tab) move, Left / Right move along the toggles and adjust a slider, Enter / Space press.
- `settings/`: the Settings window (`Super + I`). `SettingsWindow.qml` is the window and sidebar; every section is a file
  (`WifiSection.qml`, `BluetoothSection.qml`, ...) built from the same rows (`SettingRow`, `ListRow`, `Segmented`,
  `Switch`, `Stepper`) and loaded only while it shows, so Wi-Fi and Bluetooth scan only while their section is open.
  **Keyboard:** Up / Down (or Tab) move between controls, Enter / Space activates, Left / Right adjust a slider (Right on
  a tile opens its details), Esc or Backspace goes back a page (Esc closes on the first page); the focused control gets
  an accent outline. `qs ipc call panel open <wifi|bt|output|profile|night|notifications|none>` opens it on a page.
- `Modes.qml`: Do Not Disturb, night light (`hyprsunset -t <kelvin>`, 2500-6500 K) and keep awake (an idle inhibitor held
  by the bar). Do Not Disturb and night light are remembered in `~/.local/state/dotfiles/modes.json`.
  `qs ipc call modes toggleDnd | toggleNight | toggleAwake | setWarmth <kelvin>`.

### Wallpaper photos

The photos come from [Unsplash](https://unsplash.com/license) (free to use under the Unsplash License) and are
downloaded at install time from the list in `system/wallpapers.txt`, not stored in this repo. Each entry
is pinned by checksum; a failed or changed download only skips that photo with a warning. I could not look up
the photographers' names automatically (Unsplash blocks automated page lookups), so they are not listed;
add them as comments in `wallpapers.txt` if you know them. Add or remove photos by editing that file.

The picker (and so the launcher and clipboard history) scrolls: arrows, Page Up/Down or the mouse wheel move
through lists longer than eight rows, and a small `3/12` counter shows where you are.

### External monitor brightness (ddcutil)

Needs two things. (1) Access to `/dev/i2c-*`: the ddcutil package's udev rule grants it, but devices that
existed before the package was installed need the rules re-applied (a logout does not do it; a reboot does):
`./install.sh services` (it runs `udevadm trigger --subsystem-match=i2c-dev`) or just
`sudo udevadm trigger --subsystem-match=i2c-dev && sudo udevadm settle`. (2) DDC/CI switched on in the
monitor's own on-screen menu (some monitors ship with it off; some ports don't support it).
Check with `ddcutil detect`: the monitor should appear as "Display 1". The quick-settings panel says
`no DDC access`, `DDC/CI off or unsupported` or `ddcutil not installed` for a monitor it can't reach, and
looks again each time it opens.

## Design rules

Everything about how the shell looks comes from `Theme.qml`; no colour, size or duration is written anywhere else.

- **Shape.** Windows and floating cards have radius 10 (`radiusCard`; Hyprland's `rounding` matches). A row or
  button inside a card has radius 6 (`radiusRow`) = card radius minus the 4 px gap to the card's edge
  (`cardInset`), so the curves stay parallel. Small marks use `radiusSmall`.
- **One card.** The panel, the pickers (launcher, clipboard, wallpapers) and the indicator are all built from
  `ui/Card.qml`: frosted glass (a slightly see-through surface; Hyprland blurs what is behind it, see the
  `blur-cards` rule in `hypr/modules/rules.lua`), a hairline border, a soft shadow, and the shared enter/exit
  animation. A card lives in a fixed-size window that leaves `shadowMargin` free on each side; only the card
  resizes, never the window (resizing a layer window makes the compositor smear the old frame).
- **Hover and selection** are a light wash over the card (`hover`, `selected`); the selected row in a list also
  gets an accent mark. They fade in `durFast`. An "on" tile uses the same sign (wash + accent mark); an "off" tile is
  only a hairline outline. Solid accent fills are avoided: they shout over the text.
- **Type.** Sizes come from `fontSmall` 11, `fontBase` 12 (also the bar), `fontLarge` 14, `fontXL` 16.
- **Motion.** `durFast` 90 ms, `durBase` 140 ms, `durSlow` 240 ms, `durAmbient` 400 ms (wallpaper and bar
  colours), all ease-out (`easeOut`; `easeInOut` for cross-fades). Enter is `durBase`, exit `durFast`.
- **New pieces** should use `Card`, the tokens and the Hyprland rules above, so they match without extra work.
- **Check animations** by recording (`wf-recorder`, constant frame rate) and measuring frame to frame.
  Compare direct `grim` screenshots to look for leftovers: video compression adds noise on detailed images.

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
| `Super + W` | browser (Brave Origin) |
| `Super + A` | app menu: every app as an icon, with a search (Enter or click starts it) |
| `Super + D` | control center, the dashboard (also: click the clock) |
| `Super + N` | notification centre (also: the bell in the bar) |
| `Super + I` | settings (toggle) |
| `Super + X` | power menu: lock, log out, suspend, reboot, shut down (letters L O S R P; log out / reboot / shut down ask twice) |
| `Super + Shift + A` | settings, on Appearance (GTK theme, colour scheme, fonts, icons, cursor) |
| `Super + [` / `Super + ]` | brightness down / up on the focused screen |
| `Print` | screenshot: the screen freezes, then drag a region or click a window (Esc cancels) |
| `Shift + Print` / `Ctrl + Print` | screenshot of the focused monitor / every monitor |
| `Super + Shift + R` / `Super + Ctrl + R` | record a region or window / the focused monitor; again to stop |
| `Super + B` | hide / show the bar |
| `Super + Escape` | lock |
| `Super + Shift + E` | log out |

Idle (`hypridle.conf`): dim at 2.5 min, lock at 5, screens off at 5.5, suspend at 30. Dimming covers every screen the
shell can control (the laptop panel and, over DDC, the external monitor) to 10% (`idleDimLevel` in `Theme.qml`), quietly
(no indicator), and puts each back as it was; without the shell running, only the laptop dims.
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
