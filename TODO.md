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
- [ ] Battery detail (time to full/empty) and power-profile hint if `performance` is degraded

## 2. Notifications

- [x] Rebuild on `Card`: frosted glass + shadow, fixed-size window (no resizing), enter / exit / re-stack animation
- [x] Pop-up lifecycle separate from history (a notification can leave the screen and stay in the history)
- [x] Hover pauses the timeout; visible close button; a thin timeout indicator
- [x] Layer rules: blur + no compositor fade for `quickshell-notifications`

## 3. UI consistency (from the audit)

Done: design tokens, shared `Card`, one radius system, frosted cards + shadows, visible selection and hover,
quiet tiles, the control center's structure.

- [ ] Hyprland animations: windows, workspaces and layers on the same speed as the shell (snappy)
- [ ] Picker: the selection highlight slides between rows instead of jumping
- [ ] Hover / pressed feedback for: sliders, tray icons, the bar's clock area
- [ ] One consistent glyph set (selection dot, padlock, arrows)
- [ ] Tray right-click menus: check how they look and theme them
- [ ] `Super + B` (hide bar) animated inside the shell instead of a compositor fade
- [ ] Type scale check against kitty (11.5 pt is about 15 px; the shell is 12 px): decide and align
- [ ] Guard rail: `scripts/ui-check` (record + time + leftover check) and a grep for magic numbers outside `Theme.qml`

## 4. Beyond the shell

- [ ] GTK apps (Nautilus, pavucontrol, blueman, file dialogs): force dark, recolour libadwaita to the palette,
      10 px corners, Maple Mono
- [ ] Icons: remove the Sway-era leftovers (Rofi, Foot x3, Xarchiver, Tuned Switcher) and settle on one icon theme
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
