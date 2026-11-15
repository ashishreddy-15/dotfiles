# Using it

How each part works day to day. For the keys, see the table in the [README](../README.md#keys).

- [Settings](#settings)
- [Wallpapers](#wallpapers)
- [Notifications](#notifications)
- [Bluetooth](#bluetooth)
- [Screenshots and recording](#screenshots-and-recording)
- [Touchpad](#touchpad)
- [Pen tablet](#pen-tablet)
- [Login screen](#login-screen)
- [Bash](#bash)
- [Neovim](#neovim)
- [Java and Maven](#java-and-maven)
- [Hiding apps and autostart entries](#hiding-apps-and-autostart-entries)

## Settings

`Super + I` (press again, or Esc, to close). A window of its own, centred, with a sidebar:

| Group | Sections |
|---|---|
| Connections | Wi-Fi, Bluetooth |
| Device | Display (brightness, night light), Sound, Power (profile, battery), Touchpad, Tablet |
| Personal | Appearance, Wallpaper, Notifications |

**Keyboard.** It opens on the sidebar: Up / Down change section. Right, Enter or Tab go into the section; there, Tab
or Up / Down move between controls, Enter and Space press, and Left / Right adjust (choices, steppers, sliders, the
wallpaper grid; switches only take Space / Enter). Left on a plain row, or Shift+Tab from the first control, goes back
to the sidebar.

**Appearance** (colour scheme, GTK / icon / cursor theme, cursor size, fonts) runs the `appearance` command, which
writes gsettings, the two `settings.ini` files (symlinks into `home/gtk/`, so `git diff` shows what changed and you can
commit it) and the running cursor. In a terminal: `appearance get`, `appearance list gtk|icons|cursors|fonts`,
`appearance set font-size 11`.

- GTK4 / libadwaita apps (Nautilus, pavucontrol) and GTK3 apps (blueman, file dialogs) get the palette in both
  schemes. For GTK3, `adw-gtk3` is listed once and the scheme picks `adw-gtk3` or `adw-gtk3-dark`;
  `~/.config/gtk-3.0/scheme.css` points at `dark.css` or `light.css`.
- The icon theme is **Carbon**: Adwaita with its blue folders recoloured to the palette's pewter. It is built into
  `~/.local/share/icons/Carbon` by `appearance icons` (and by `appearance sync`, which `./install.sh link` runs), so
  nothing is copied into the repo.

### Light and dark

One switch changes everything: **Settings > Appearance > Colour scheme**, or `appearance toggle`
(`appearance set color-scheme prefer-light`) in a terminal.

| What | How it follows |
|---|---|
| The shell (cards, Settings, notifications) | `Theme.dark`, read from `~/.local/state/dotfiles/scheme` at startup and changed at once on a switch |
| Window borders and shadows | `look.lua` reads the same file; the switch reloads Hyprland |
| kitty | switches between `dark-theme.auto.conf` and `light-theme.auto.conf` itself, in every open window |
| Prompt, fzf, bat, `install.sh` output | use the terminal's 16 colours, so they change with kitty |
| Neovim | `mono.lua` has both palettes and follows `background`, which Neovim takes from the terminal |
| GTK apps | gsettings, the theme twin and the stylesheets in `home/gtk` |

The bar is the exception: it has no background, so its text follows the wallpaper, not the scheme (see
[wallpapers](#wallpapers)). The lock and login screens are light text over the darkened wallpaper in both schemes. Apps with
their own setting (Brave, JetBrains IDEs, Qt apps) follow only if that setting is "system" / "sync with OS".

## Wallpapers

Settings > Wallpaper shows a grid of thumbnails (click one, or arrows + Enter). It lists two folders, alphabetically:

- `~/.local/share/wallpapers`: 21 photos from Unsplash and Wikimedia Commons, downloaded by
  `./install.sh wallpapers` from `system/wallpapers.txt`. They are pinned by checksum; a failed or changed download only
  skips that photo with a warning. Photos from Commons carry the credit their licences require, in the comment above
  each entry (Unsplash photographers could not be looked up automatically, so they are not listed).
- `~/Pictures/Wallpapers`: **put your own images here** (png, jpg, webp).

The choice is remembered in `~/.local/state/dotfiles/wallpaper`; `qs ipc call wallpaper next` cycles and
`qs ipc call wallpaper set <file>` uses any image. The wallpaper cross-fades (about 0.3 s) on every monitor, and the
lock screen and login screen use the same one.

The bar has no background, so its text follows the wallpaper: on a wallpaper whose top edge is light it switches to
dark text, on a dark one to light text (measured when you pick it).

To add or remove a pinned photo, edit `system/wallpapers.txt` (each entry: name, sha256, URL) and run
`./install.sh wallpapers`; photos no longer listed there are removed. Settings shows small cached copies
(`~/.cache/dotfiles/wallpaper-thumbs`, made by Pillow at login) so it opens instantly; delete the folder and it is rebuilt.

## Notifications

Pop-ups appear top-centre for a few seconds. Everything you have not dealt with stays in the **notification centre**
(`Super + N`, or the bell in the bar, which shows a count and turns into a crossed bell while Silence is on): a panel at
the right edge, grouped by app ("2 more" expands), with each notification's buttons, an x to dismiss, and Silence and
Clear all at the top. Opening it clears the pop-ups.

Every notification is also kept for **7 days** in an archive on disk (`~/.local/state/dotfiles/notifications.jsonl`,
readable only by you, plain text). Settings > Notifications shows it by day (Today, Yesterday, This week, All) with
search and Clear history.

## Bluetooth

Put the device in pairing mode, open Settings > Bluetooth and click it. BlueZ's questions (a PIN, "does this code
match?", "may this device connect?") appear as a prompt in the middle of the screen; nothing is accepted until you click
Pair or Allow (Esc declines). The agent behind it is `bt-agent` (`bt-agent.service`; logs:
`journalctl --user -u bt-agent -f`). Only `bluetoothd` can call it (system bus policy), and the computer is pairable only
while Settings > Bluetooth is open.

Connected devices that report a battery (headphones, mice, keyboards) show a small gauge and the percentage in their row;
it turns amber at 30% or less and red at 15% or less.

## Screenshots and recording

- **`Print`** freezes every screen first, so the control center, pop-ups and anything else that closes when it loses
  focus stay in the shot; then drag a region or click a window. Every shot goes to `~/Pictures/Screenshots/` and the
  clipboard, with a notification (`home/bin/.local/bin/screenshot`).
- **`Super + Shift + R`** records a region (drag, or click a window); **`Super + Ctrl + R`** the focused monitor. Press the
  same key again, or click the red "rec 0:12" in the bar, to stop. Videos (MP4, H.264) go to `~/Videos/Recordings/`.
  Silent by default; `screenrecord screen --audio` also records what the computer plays.

## Touchpad

Settings > Touchpad: tap to click, natural scrolling, speed (the touchpad's own; the mouse is not affected), scroll
speed, right click (two fingers or the corner), tap and drag, off while typing. Applied live by `quickshell/Touchpad.qml`
(`qs ipc call touchpad status`); `hypr/modules/input.lua` is the baseline.

## Pen tablet

Settings > Tablet appears when one is connected (written for the Wacom Intuos BT S):

- which screen it covers (default: the one you are working on),
- keep proportions (trims the active area to the screen's shape, following you between the 16:10 laptop and the 16:9
  monitor),
- orientation (180° for left-handed), pen or mouse mode, the battery, and a pad to try it.

`quickshell/Tablet.qml` applies the choices live with `hyprctl eval` (`qs ipc call tablet status` shows what it
applied); `hypr/modules/tablet.lua` is the default without the shell.

**ExpressKeys.** Settings > Tablet sets each of the four keys (Undo, Redo, Pen, Eraser by default: Xournal++'s
shortcuts). The `tablet-keys` helper (`home/bin`) sends them to the focused window. It runs only while the tablet is
plugged in: udev starts and stops `tablet-keys@<event>.service` (`system/udev/70-tablet-pad.rules`, installed by
`./install.sh services`), and that rule gives your session read access to the pad only, not the `input` group. The pen's
two buttons and pressure curves are set in the app (Xournal++: Edit > Preferences > Input System).

## Login screen

The "carbon" SDDM theme (`system/sddm/carbon/`) matches the lock screen: the wallpaper lightly blurred, the date and a
large light clock near the top, your name and a frosted password pill near the bottom, session and power buttons small
along the bottom edge. Install or update it with `./install.sh sddm` (sudo, and only when a file differs). It copies
Maple Mono and your current wallpaper into the theme, because the login screen cannot read your home folder, so run it
again after changing the wallpaper. Preview without logging out:
`sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/carbon`. The cursor is Adwaita everywhere.

## Bash

Everything lives in `home/bash/.bashrc.d/` (Fedora's own `~/.bashrc` loads every file there, so it is left alone).

**The prompt** `~/dotfiles  main  3.2s ✗1 ❯` shows the folder, the git branch, how long the last command took (from 2 s)
and its exit code when it failed; plus `user@host` over SSH and `(venv)` when one is active. It starts **no programs**
when drawn (the branch is read from `.git/HEAD`, the time from `$EPOCHREALTIME`): about 0.05 ms per prompt. fzf and
zoxide are loaded from files, never with `eval "$(...)"`, so they start no programs either.

**Aliases**

| Group | Aliases |
|---|---|
| dnf | `din` install, `dup` upgrade, `drm` remove, `dse` search; also `dinfo`, `dprov`, `dls`, `dhist` |
| files | `ll`, `la`, `lt`; `..`, `...`, `dots`, `mkcd`; `cp` and `mv` ask before overwriting, `rm` asks once before deleting many files or a folder |
| git | `gs`, `gd`, `gds`, `ga`, `gc`, `gca`, `gp`, `gl`, `gsw`, `glog` |
| systemd | `sc` / `scu` (systemctl), `jf` / `jfu` (follow logs); `reload` re-reads the shell config |

**Finding things**

| Keys | Does |
|---|---|
| `Ctrl + R` | search the whole history with fzf |
| `Ctrl + T` | pick files (with a bat preview) |
| `Alt + C` | go into a folder |
| `**` + Tab | complete anything fuzzily |
| `z <part of a name>` / `zi` | jump to a folder you use often (zoxide) / pick one with fzf |
| Up / Down | search the history for what you have typed |

## Neovim

`home/nvim/.config/nvim` (its own README lists the plugins and keys). Plugin versions are pinned in `lazy-lock.json`; the
first start installs them (or `nvim --headless "+Lazy! restore" +qa`). What it needs from the system (Neovim, gcc, make,
tree-sitter-cli, npm, fd) is in `packages/editor.txt`. The colour scheme (`colors/mono.lua`) uses the desktop's palette,
checked by `scripts/ui-check`. Java support (intellij-lsp.nvim) uses the JDK from SDKMAN.

## Java and Maven

`./install.sh sdkman` installs SDKMAN into `~/.sdkman` (for your user; it is told not to edit `~/.bashrc`) and the
versions in `packages/sdkman.txt` (Temurin 25 LTS, Maven 3.10.0), made the defaults. `~/.bashrc.d/40-sdkman.sh` puts the
current versions on `PATH` and sets `JAVA_HOME` / `MAVEN_HOME` without loading SDKMAN, so new shells stay fast; `sdk`
loads it the first time you type it. To change a version: `sdk install java <version>`, `sdk default java <version>`,
and update `packages/sdkman.txt`.

## Hiding apps and autostart entries

- **An app from the launcher:** add `home/applications/.local/share/applications/<same file name as the system one>.desktop`
  containing `[Desktop Entry]`, `Type=Application`, `Name=...` and `NoDisplay=true`, then `./install.sh link`.
  Currently hidden: Foot (3), Rofi and its theme selector, Tuned Switcher, Xarchiver (Sway-era leftovers).
- **An `/etc/xdg/autostart` entry:** copy one of the files in `home/autostart/.config/autostart/`, rename it to match the
  system entry, then `./install.sh link`. nm-applet no longer starts at login (Wi-Fi is in Settings); it is still
  installed, so run `nm-applet` by hand if you ever need it.
