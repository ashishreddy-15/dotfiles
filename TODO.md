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
- [ ] Pair the Rockerz 650 Pro for real (needs the headset in pairing mode)
- [ ] Settings: a "forget network" action; Bluetooth: forget / remove a device

## 4. Beyond the shell

- [x] GTK apps: dark, palette, 10 px / 6 px corners, Maple Mono (`home/gtk`), plus appearance settings (now a section of Settings)
      (colour scheme, GTK / icon / cursor theme, cursor size, font and size; like nwg-look)
- [ ] Appearance: folder icons stay Adwaita blue (not recoloured by the palette); GTK3 apps stay dark in the light scheme;
      `adw-gtk3-theme` is not installed, so the GTK theme list has only Adwaita; icon / cursor list has one real choice each
- [x] Icons: Sway-era launcher entries hidden (`home/applications`); one icon theme (Adwaita + hicolor) and all icons resolve. The packages are still installed (see section 5, Sway)
- [ ] hyprlock: same tokens, frosted input card, your wallpaper instead of a blurred screenshot; fingerprint
- [ ] Login screen (SDDM) theme and a matching cursor theme (optional)

## 5. System

- [ ] Run `./install.sh` from a clean state (fresh Fedora in a VM) and fix what breaks
- [ ] Undocked test: unplug the Samsung; workspaces, bar, panel, indicator and notifications should fall back to the laptop
- [ ] Lid close / suspend: lock first, wake cleanly; DDC monitor brightness after sleep
- [ ] Idle dimming for the external monitor too (today only the laptop dims)
- [ ] Put the repo on a remote (GitHub) so the setup is backed up
- [ ] Decide what to do with Sway: keep as a fallback session, or remove it and its packages

## 6. Things I could not test (no way to press keys or click from here) - please try

- [x] Install the test tools (`wtype`, `wlrctl`) - done; I can now type keys and click from here
- [ ] Keep awake: verify with nothing playing (a playing video holds its own idle inhibitor and hides the effect)
- [ ] Night light: look at the screen when it is on (screenshots can't show the colour filter; hyprsunset reports it applies)
- [x] Keyboard navigation of the control center (tested: arrows, Enter/Space, Right/Left, Backspace, Esc, focus return)
- [ ] Media buttons: play-pause was hit by accident and works; previous / next not tried
- [x] Enter / Esc / arrows in the launcher, clipboard and wallpaper pickers (tested)
- [ ] Keys: `Super + A / V / W / Space / B`, `Super + [` and `]`, the XF86 brightness keys (Hyprland ignores binds from virtual keyboards, so only a physical keypress can test these)
- [x] Control center clicks: clock opens it, tiles, `›` arrow, `‹` back, sliders, mic mute (tested)
- [ ] Power confirmation (lock / logout / suspend / reboot / shutdown): not pressed on purpose
- [ ] Wi-Fi: connect to a saved network, enter a password for a new one; Bluetooth: pair and connect a device
- [ ] Notification actions and click-to-dismiss
- [ ] hyprlock: how it looks, unlocking, fingerprint
- [ ] Tray right-click menu; launching an app from the launcher with Enter
- [ ] Frosted cards on a light wallpaper (e.g. `misty-ridges`)

## 7. Ideas (not committed to)

- Clipboard: image thumbnails, delete an entry, pin entries
- Screenshot and screen-record UI (wf-recorder is installed)
- Wi-Fi: forget a network, a VPN tile
- Schedules for Do Not Disturb and night light
- A calendar popup from the clock
