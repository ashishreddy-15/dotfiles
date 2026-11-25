# TODO

The single list of what is left. `[x]` = done, `[ ]` = open. Decisions already made are noted so they are not re-asked.

Decisions: unified 10 px corners, snappy motion (about 140-200 ms), frosted translucent cards with shadows,
GTK apps dark + Carbon & Pewter + Maple Mono, control center as tiles + sliders + detail pages.

## 1. Control center (queued features)

- [x] Do Not Disturb tile (hides pop-ups; critical ones still show) and a notification history page
- [x] Night light tile (hyprsunset) with a warmth page
- [x] Keep awake tile (blocks idle lock/sleep)
- [x] Mic slider (+ mute) under `sound`
- [x] Media block (title, artist, previous / play-pause / next) when a player is running
- [x] Keyboard navigation: arrows / Tab / Enter / Esc, with a visible focus ring
- [x] Battery detail page (charge, state, time, power, energy, health) opened from the header; warning when performance is limited (lap detected / high temperature)

## 2. Notifications

- [x] Rebuild on `Card`: frosted glass + shadow, fixed-size window (no resizing), enter / exit / re-stack animation
- [x] Pop-up lifecycle separate from history (a notification can leave the screen and stay in the history)
- [x] Hover pauses the timeout; visible close button; a thin timeout indicator
- [x] Layer rules: blur + no compositor fade for `quickshell-notifications`

## 3. UI consistency (from the audit)

Done: design tokens, shared `Card`, one radius system, frosted cards + shadows, visible selection and hover,
quiet tiles, the control center's structure.

- [x] Hyprland animations: windows, workspaces and layers on the same speed as the shell (snappy)
- [x] Picker: the selection highlight slides between rows instead of jumping
- [x] Hover / pressed feedback for: sliders, tray icons, the bar's clock area
- [x] One consistent glyph set: all icons are `Theme.glyph*` (FontAwesome symbols in Maple Mono NF); ui-check forbids inline icon characters
- [x] Tray right-click menus: own themed menu (`bar/TrayMenu.qml`, Card, submenus as pages, Esc / click-outside). Arrow-key navigation not done
- [x] `Super + B` slides and fades the bar inside the shell (no compositor fade)
- [x] Type scale: shell stays at 12 px base; kitty set to 10.5 pt by choice (15 px shell and 11.5 pt kitty were tried and looked too big)
- [x] Guard rail: `scripts/ui-check` (static: magic values + Theme vs Hyprland/hyprlock/kitty font; live: open/close timing + leftover layers + log). Screen recording not included

## 3b. Settings window (`Super + I`)

- [x] Settings window with a sidebar: Wi-Fi, Bluetooth, Sound, Display, Wallpaper, Notifications, Power, Appearance
- [x] Control center slimmed to tiles (plain toggles), sliders, media and the power buttons; a gear opens Settings
- [ ] Try by hand: connect to a saved Wi-Fi network and a new one with a password; pair a Bluetooth device; pick the sound
      output / input device; the brightness and warmth sliders; clear the notification history; switch the power profile
- [x] Settings: keyboard navigation (sidebar, Tab / arrows between controls, Enter / Space, Left / Right, scrolling to the focused row)
- [x] Bluetooth pairing: agent (`bt-agent`) that asks in the shell; pairable only while Settings > Bluetooth is open; trusted after pairing
- [x] Paired the Rockerz 650 Pro through the prompt
- [x] Settings: "Forget" for saved Wi-Fi networks, "Remove" for paired Bluetooth devices (hover or focus, two clicks or Delete twice)

## 4. Beyond the shell

- [x] GTK apps: dark, palette, 10 px / 6 px corners, Maple Mono (`home/gtk`), plus appearance settings (now a section of Settings)
      (colour scheme, GTK / icon / cursor theme, cursor size, font and size; like nwg-look)
- [x] Appearance: GTK3 apps follow the light / dark scheme (adw-gtk3 twins + scheme.css); folders in pewter (Carbon icon theme)
- [x] Light theme: one switch (Settings > Appearance, `appearance toggle`) for the shell, window borders,
      kitty, prompt / fzf, Neovim and GTK apps; lock and login screens unchanged (see docs/features.md, "Light and dark")
- [x] Icons: Sway-era launcher entries hidden (`home/applications`); one icon theme (Adwaita + hicolor) and all icons resolve. The packages are still installed (see section 5, Sway)
- [x] hyprlock: same tokens, no card: date and a large light clock at the top, name and a frosted password pill at the
      bottom, over your wallpaper (lightly blurred) instead of a screenshot.
      Fingerprint: not possible, this laptop has no reader
- [x] Login screen (SDDM): "carbon" theme, same layout as the lock screen (`./install.sh sddm`); cursor: Adwaita everywhere
- [x] Login screen: the installed "carbon" theme and its wallpaper stay as they are (`./install.sh sddm` updates it)

## 5. System

- [x] install.sh output: numbered steps, colour-coded status, services grouped with their real on / off state, summary
- [ ] Run `./install.sh` from a clean state (fresh Fedora in a VM) and fix what breaks
- [x] Undocked test: unplug the Samsung; workspaces, bar, panel, indicator and notifications should fall back to the laptop
- [x] Lid closed with the monitor plugged in: laptop screen off, workspaces 8-10 move to the monitor; back on opening (modules/monitors.lua)
- [x] Lid, tried by hand: close and open it docked (works)
- [ ] Lid close / suspend: lock first, wake cleanly; DDC monitor brightness after sleep
- [x] Idle dimming for the external monitor too (`qs ipc call brightness dim / undim`, DDC; laptop verified, monitor path shared with the slider)
- [x] Repo on GitHub (public): https://github.com/ashishreddy-15/dotfiles
- [x] Sway: kept as a fallback session (its packages stay installed; its launcher entries are hidden)

## 6. Things I could not test (no way to press keys or click from here) - please try

- [x] Install the test tools (`wtype`, `wlrctl`) - done; I can now type keys and click from here
- [ ] Keep awake: verify with nothing playing (a playing video holds its own idle inhibitor and hides the effect)
- [ ] Night light: look at the screen when it is on (screenshots can't show the colour filter; hyprsunset reports it applies)
- [x] Keyboard navigation of the control center (tested: arrows, Enter/Space, Right/Left, Backspace, Esc, focus return)
- [ ] Media buttons: play-pause was hit by accident and works; previous / next not tried
- [x] Enter / Esc / arrows in the launcher, clipboard and wallpaper pickers (tested)
- [ ] Keys: `Super + A / D / V / W / I / X / N / Space / B`, `Super + Shift + A / R`, `Super + Ctrl + R`, `Print` (+ Shift / Ctrl), `Super + [` and `]`, the XF86 brightness keys (Hyprland ignores binds from virtual keyboards, so only a physical keypress can test these)
- [x] Control center clicks: clock opens it, tiles, `›` arrow, `‹` back, sliders, mic mute (tested)
- [ ] Power confirmation (lock / logout / suspend / reboot / shutdown): not pressed on purpose
- [ ] Wi-Fi: connect to a saved network, enter a password for a new one (Bluetooth pairing: done, the Rockerz works)
- [ ] Notification actions and click-to-dismiss
- [x] hyprlock: how it looks, unlocking (no fingerprint reader on this laptop)
- [ ] Launching an app from the launcher with Enter (tray: empty now that nm-applet no longer starts)
- [ ] Frosted cards on a light wallpaper (e.g. `cloud-sea`)
- [ ] Light theme: every panel and Settings section by eye; start the shell with the light scheme saved (no dark flash);
      prompt and fzf in a light kitty; a running Neovim following the switch; Nautilus and blueman in light

## 7. Ideas (not committed to)

- [x] Bar: amber coffee cup while Keep awake is on (click to turn off)
- [x] Notification centre (Super + N, bell in the bar with a count; crossed bell while Silence is on), grouped by app
- [x] Notification archive: 7 days on disk, Settings > Notifications with Today / Yesterday / This week / All and search
- [ ] Notification archive: optionally leave chosen apps out of it (for apps that send codes or private messages)
- [x] Neovim config moved in from the swaywm repo (home/nvim), recoloured to Carbon & Pewter; packages/editor.txt
- [x] Neovim first start: 33 plugins, 16 Treesitter parsers, 8 Mason tools, IntelliJ server; checkhealth 0 errors;
      starts in ~40 ms
- [x] Neovim: IntelliJ server EULA accepted
- [ ] Later, when learning Go: `din golang`; gopls then installs by itself on the next Neovim start
- [x] Java 25 (Temurin) and Maven 3.10.0 with SDKMAN (`./install.sh sdkman`, packages/sdkman.txt), no shell slowdown
- [ ] Optional: remove nvim/ from the swaywm repo with a pointer here
- [x] Touchpad: Settings > Touchpad (tap, natural scroll, speed, scroll speed, right click, tap and drag, typing)
- [x] Pen tablet: Settings > Tablet (screen, proportions, orientation, mode, battery, test pad), applied live
- [x] Tablet: pen and pressure confirmed
- [x] ExpressKeys: Settings > Tablet, tablet-keys helper (runs only while the tablet is plugged in)
- [x] ExpressKeys confirmed working in Xournal++ (udev rule installed)
- [x] Handwriting app: Xournal++ (packages/desktop.txt)
- [x] Xournal++ installed; pen and pressure work
- [x] Handwriting input popup (`Super + Shift + W`), built and tested with a fake daemon
- [x] Try the handwriting popup with the real pen and the hw-ocr daemon
- [x] Handwriting strip: opens at the pointer or under the launcher, pad maps onto it, pen button, in-strip
      ExpressKeys, continuous mode (built; see docs/features.md, Handwriting input)
- [ ] Install the pen udev rule (`./install.sh services`) and try the pen's lower button
- [ ] Try the pad mapping on the strip (if the pen lands in the wrong place, the region units in Tablet.qml are off)
- [ ] Try docking under the launcher, and continuous mode typing into a real window
- [ ] Retrain the model with the round-2 prompts and ~/handwriting/usage/
- [ ] Maybe: open the strip by itself on text-field focus (input-method-v2 daemon; see features.md)
- [x] fzf (Ctrl+R / Ctrl+T / Alt+C / **), zoxide (z, zi), bat previews; prompt still ~0.05 ms (zoxide without its
      per-prompt hook)
- [x] Bash: fast prompt (no programs per prompt, ~0.07 ms), dnf aliases din / dup / drm / dse, git / systemd /
      file aliases, history and completion settings (home/bash)
- [x] Apps: Resources from Flathub (installed; Flatpak apps get the palette); Loupe, Papers, Calculator, Disk Usage
      Analyzer added to packages/desktop.txt
- [x] Loupe, Papers, Calculator and Disk Usage Analyzer installed
- [x] App menu on Super + A (icon grid + search); control center moved to Super + D; wallpaper picker removed
      (Settings > Wallpaper)
- [x] Notification bell always at the right end of the bar
- [x] Settings sidebar grouped: Connections (Wi-Fi, Bluetooth), Device (Display, Sound, Power), Personal (Appearance,
      Wallpaper, Notifications), with icons
- [x] Wallpapers: eight Unsplash photos in fog-forest's mood; the generated ones and the other photos are gone
- [x] Control center redesign: a row of round toggles, pill sliders with icons, media card, footer (battery, settings, power)
- [x] Power menu on Super + X (actions shared with the control center: Power.qml)

- Clipboard: image thumbnails, delete an entry, pin entries
- [x] Screenshots that freeze the screen first (Print / Shift+Print / Ctrl+Print), saved and copied
- [x] Screen recording: Super+Shift+R (region / window), Super+Ctrl+R (monitor), "rec" in the bar to stop
- A VPN tile (forgetting a network is done, in Settings)
- Schedules for Do Not Disturb and night light
- A calendar popup from the clock
- [x] Wallpapers: 21 sharp photos (Unsplash and Wikimedia Commons; checked at 100%), dark / darkest / misty / light / daylight; moss-valley is the one soft one (3506 px)
