# dotfiles

A Fedora 45 desktop built around **Hyprland** and a hand-written **Quickshell** shell, for a laptop with an external
monitor. One calm palette ("Carbon & Pewter"), one font (Maple Mono), and one rule: edit everything **here**. The files
in `~/.config` are only symlinks into this repo.

**What you get**

- A bar, app menu, launcher, clipboard history, notification centre, control center and a full **Settings** window, all
  in one shell (Wi-Fi, Bluetooth, sound, display, wallpaper, touchpad, pen tablet, appearance).
- A lock screen and login screen in the same look, 21 wallpapers, GTK apps in the same palette.
- A fast bash prompt, Neovim set up for Java, screenshots and screen recording.
- An installer that is safe to re-run and tells you, in plain colour-coded steps, what it changed.

## Quick start

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh -n     # dry run: shows every change, touches nothing
./install.sh        # do it
```

Then log in by picking **Hyprland (uwsm-managed)** in SDDM. Re-running `./install.sh` is always safe: each step checks
what is already done.

## Keys

`Super` is the Windows key.

| Keys | Does |
|---|---|
| `Super + Return` / `E` / `W` | terminal / files / browser (Brave Origin) |
| `Super + Space` | launcher (type to search apps) |
| `Super + A` | app menu: every app as an icon, with a search |
| `Super + D` | control center (also: click the clock) |
| `Super + I` | Settings (`Super + Shift + A`: on Appearance) |
| `Super + N` | notification centre (also: the bell in the bar) |
| `Super + V` | clipboard history |
| `Caps Lock` (laptop: Copilot key) | handwriting strip: press, write with the pen, press again to type it in (see [features](docs/features.md#handwriting-input)) |
| `Super + Shift + W` | open / close the handwriting strip |
| `Super + X` | power menu (lock, log out, suspend, reboot, shut down) |
| `Super + Escape` | lock |
| `Super + Q` | close window |
| `Super + F` / `M` | fullscreen / maximize |
| `Super + Shift + Space` | toggle floating |
| `Super + arrows` or `h j k l` | move focus (`+ Shift`: move the window) |
| `Super + 1..0` | workspace 1-10 (`+ Shift`: move the window there) |
| `Super + Tab` | previous workspace |
| `Super + ,` / `.` | focus the laptop / main monitor (`+ Shift`: send the window there) |
| `Super + S` | scratchpad (`+ Shift`: send the window there) |
| `Super + [` / `]` | brightness down / up on the focused screen |
| `Super + B` | hide / show the bar |
| `Print` | screenshot: the screen freezes, then drag a region or click a window |
| `Shift + Print` / `Ctrl + Print` | screenshot of the focused monitor / every monitor |
| `Super + Shift + R` / `Ctrl + R` | record a region or window / the focused monitor; again to stop |
| `Super + Shift + E` | log out |

## Everyday tasks

| I want to... | Do this |
|---|---|
| Install a package | add a line to a `packages/*.txt`, then `./install.sh packages` |
| Remove a package | add it to `packages/remove.txt`, then `./install.sh packages` |
| Add a Flathub app | add its id to `packages/flatpak.txt`, then `./install.sh flatpaks` |
| Add a program's config | move it to `home/<app>/.config/<app>/`, then `./install.sh link` |
| Add a wallpaper | drop it in `~/Pictures/Wallpapers` (or pin one in `system/wallpapers.txt`) |
| Change a default app | edit `MIME_DEFAULTS` at the top of `install.sh`, then `./install.sh defaults` |
| Turn a service on or off | edit the lists in `system/services.sh`, then `./install.sh services` |
| Switch dark / light | Settings > Appearance, or `appearance toggle` |
| Change the theme colours | `Theme.qml` plus the files that repeat it (see [the look](docs/system.md#the-look)) |
| Restart the shell | `systemctl --user restart quickshell` (logs: `journalctl --user -u quickshell -f`) |
| Check nothing drifted | `scripts/ui-check` |

New files need `./install.sh link` (stow links file by file, so apps that write caches into `~/.config/<app>` do not
write into this repo).

## install.sh

| Command | What it does |
|---|---|
| `./install.sh` | every step: `repos packages flatpaks sdkman fonts wallpapers link services sddm defaults` |
| `./install.sh <step>...` | only those steps, e.g. `./install.sh link` |
| `./install.sh -n` | dry run |
| `./install.sh -y` | do not ask dnf for confirmation |
| `./install.sh unlink` | remove every dotfile symlink from `$HOME` |

Run it as your normal user; it asks for `sudo` only for the steps that need root, and only when something differs.

- **Nothing is overwritten.** A real file where a symlink should go is moved to `~/.dotfiles-backup/<time>/` first.
- **All or nothing linking.** Stow simulates first; if any package would fail, `$HOME` is untouched.
- **Stops at the first error** and prints the failing line.
- **Readable output.** Numbered steps, one line saying what each does, then `✓` already fine (dim), `+` changed,
  `−` removed or turned off, `→` happening now (in a dry run: what would happen), `!` warning, and a summary of every
  change at the end. Colour follows the palette and is off when the output is not a terminal (or `NO_COLOR` is set).

## What is where

```
dotfiles/
├── install.sh          the bootstrap script
├── scripts/            ui-check (guard rails for the look), lib/ (shared output and service helpers)
├── packages/           what to install, one package per line
│   ├── hyprland.txt    compositor and hypr* tools (Hyprland COPR)
│   ├── quickshell.txt  the shell (Quickshell COPR)
│   ├── desktop.txt     apps and tools (Fedora)
│   ├── editor.txt, shell.txt, dev.txt   Neovim and its needs, shell tools, dev tools
│   ├── flatpak.txt     Flathub apps          sdkman.txt   Java and Maven
│   └── remove.txt      packages to uninstall
├── system/             root-level config, copied rather than linked
│   ├── repos/          the two COPR repo files (limited to exactly the packages needed)
│   ├── sddm/           the "carbon" login theme
│   ├── udev/           device rules (the tablet's ExpressKeys)
│   ├── fonts.txt, wallpapers.txt   pinned downloads (URL + sha256)
│   └── services.sh, user-services.sh   what runs and what does not
└── home/               stow packages, each mirrors $HOME
    ├── hypr/           Hyprland (Lua, split by topic), hypridle, hyprlock
    ├── quickshell/     the shell (QML)         ├── nvim/    Neovim
    ├── bash/           prompt, aliases, fzf    ├── kitty/   terminal
    ├── gtk/            GTK3 / GTK4 look        ├── bin/     appearance, screenshot, screenrecord, bt-agent, tablet-keys
    └── systemd/, uwsm/, applications/, autostart/   session plumbing and hidden launcher entries
```

## More

| Page | Covers |
|---|---|
| [docs/features.md](docs/features.md) | using Settings, Bluetooth, wallpapers, notifications, screenshots and recording, touchpad, pen tablet, login screen, bash, Neovim, Java |
| [docs/shell.md](docs/shell.md) | how the Quickshell shell is put together, the design rules, external monitor brightness |
| [docs/system.md](docs/system.md) | repos, the look, Hyprland (monitors, lid, idle), services |
| [TODO.md](TODO.md) | what is done and what is left |
| [home/nvim/.config/nvim/README.md](home/nvim/.config/nvim/README.md) | the Neovim plugins and keys |
