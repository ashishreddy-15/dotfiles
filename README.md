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
├── packages/               # what to dnf install, one package per line
│   ├── hyprland.txt        #   compositor + hypr* tools (Hyprland COPR)
│   ├── quickshell.txt      #   desktop shell (Quickshell COPR)
│   ├── desktop.txt         #   apps and tools (official Fedora)
│   └── remove.txt          #   packages to uninstall (e.g. Thunar)
├── system/                 # root-level config (copied, never symlinked)
│   ├── repos/*.repo        #   -> /etc/yum.repos.d/
│   └── services.sh         #   enable/disable systemd services
└── home/                   # stow packages, each mirrors $HOME
    └── autostart/.config/autostart/   # hides unwanted /etc/xdg/autostart entries
```

## install.sh

| Command                     | What it does                                              |
|-----------------------------|-----------------------------------------------------------|
| `./install.sh`              | all steps: `repos packages services link defaults`        |
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

## Desktop

Quickshell does as much as possible: bar, launcher, notifications, wallpaper, OSDs.
The hypr* tools cover what's safer outside the shell: `hypridle`, `hyprpolkitagent`,
and `hyprlock` as a fallback lock screen in case the Quickshell lock crashes.
File manager: Nautilus.

## Services

`system/services.sh` turns off what this bare-metal laptop doesn't use: VM guest
tools, live-ISO units, iSCSI/RAID/LVM/Stratis, ModemManager, sssd, homed, CUPS,
Avahi, PackageKit (masked). Bluetooth stays on. To undo one:
`sudo systemctl unmask <unit> && sudo systemctl enable --now <unit>`.
