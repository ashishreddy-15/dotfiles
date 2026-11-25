# The shell (Quickshell)

How the desktop shell in `home/quickshell/.config/quickshell/` is put together.

- [Working on it](#working-on-it)
- [The pieces](#the-pieces)
- [The bar](#the-bar)
- [Design rules](#design-rules)
- [External monitor brightness](#external-monitor-brightness-ddcutil)

## Working on it

It runs as `quickshell.service` (Hyprland sessions only) and reloads when a file is saved in place. If a change does not
show up (some tools replace the file instead of writing it), restart it. After adding a new file run
`./install.sh link` first, because stow links file by file.

```sh
systemctl --user restart quickshell      # restart
journalctl --user -u quickshell -f       # logs and QML errors
scripts/ui-check                         # no magic values, palette parity, every popup opens and closes cleanly
```

Singletons (`Tablet`, `Touchpad`, ...) are created on first use, so `shell.qml` references the ones that must run in the
background.

## The pieces

| Path | What it is |
|---|---|
| `Theme.qml` | colours, fonts, sizes, motion, glyphs, which monitor is main. The only place a value may be written |
| `shell.qml` | entry point: lists each piece |
| `ShellState.qml` | on/off switches reachable from keybinds (`qs ipc call bar toggle`) and state shared between pieces |
| `bar/` | the bar on every monitor (below) |
| `Notifs.qml` + `notifications/` | Quickshell **is** the notification daemon (dunst is kept out of Hyprland by a systemd drop-in). Keeps the history and the pop-ups |
| `osd/` | small volume / brightness indicator, bottom-centre of the main monitor |
| `picker/Picker.qml` | the shared search-field-plus-list window that the launcher and clipboard history are built on |
| `launcher/` | app launcher (`Super + Space`): matches name, then description / keywords, then letters in order. IPC: `toggle`, `search <text>` (opens it), `setQuery <text>` (only if open), `activate` (the selected result). It publishes `ShellState.launcherSearchRect` and honours `ShellState.launcherKeepOpen` for the handwriting strip |
| `apps/` | the app menu (`Super + A`): every app as an icon, with a search |
| `clipboard/` | clipboard history (`Super + V`) from `cliphist`, fed by `wl-paste --watch` in `autostart.lua` |
| `wallpaper/` | the wallpaper on every monitor (see [features](features.md#wallpapers)) |
| `Brightness.qml` + `brightness/` | brightness of the focused screen |
| `panel/` | the control center (`Super + D`) |
| `settings/` | the Settings window (`Super + I`) |
| `Handwriting.qml` + `handwriting/` | the handwriting popup (`Super + Shift + W`): ink canvas, link to the `hw-ocr` daemon, delivery of the text |
| `power/` | the power menu (`Super + X`) |
| `bluetooth/`, `Pairing.qml` | the pairing prompt and its state |
| `Modes.qml` | Do Not Disturb, night light, keep awake |
| `Tablet.qml`, `Touchpad.qml`, `Appearance.qml`, `Power.qml`, `Rfkill.qml`, `Apps.qml` | state behind the matching Settings sections |
| `ui/` | shared building blocks: `Card`, `FocusRing`, ... |

**Notifications.** Pop-ups are frosted cards under the bar, top-centre of the main monitor, newest on top, up to 4 at
once; each runs a thin timeout bar (5 s, paused while hovered; critical ones stay). Click a card or its `×` to hide the
pop-up (it stays in the history); an action link runs the action. Do Not Disturb hides pop-ups except critical ones.

**Pickers.** Up / Down or Tab move, Enter chooses, Esc or a click outside closes; lists longer than eight rows scroll
(arrows, Page Up / Down or the wheel) with a `3/12` counter. The window has a fixed size and only the card inside grows
and shrinks, and Hyprland's own fade is switched off for these windows (`rules.lua`): resizing the window per keystroke
made the first version smear. New pickers should reuse `Picker`.

**Brightness.** The laptop panel goes through `brightnessctl`; an external monitor through `ddcutil` (DDC/CI). Keys:
the brightness keys or `Super + [` / `]` (5% steps, held keys repeat). A change shows in the on-screen indicator on
that screen, or "no control" if it cannot be adjusted. Changes appear instantly and the real command follows a moment
later, one at a time (DDC is slow).

**Control center** (click the clock or `Super + D`; Esc or a click outside closes). Three bands: round **toggles**
(Wi-Fi, Bluetooth, Silence, Night light, Keep awake; filled when on), thick **pill sliders** with the icon inside (a
brightness per screen, volume, mic; click the icon to mute) and the **media** card while something plays. The footer has
the battery (opens Settings > Power), Settings and the power menu. Keyboard: Up / Down or Tab move, Left / Right move
along the toggles and adjust a slider, Enter / Space press.

**Settings window.** `SettingsWindow.qml` is the window and sidebar; every section is a file (`WifiSection.qml`,
`BluetoothSection.qml`, ...) built from the same rows (`SettingRow`, `ListRow`, `Segmented`, `Switch`, `Stepper`) and
loaded only while it shows, so Wi-Fi and Bluetooth scan only while their section is open. `qs ipc call settings open
<section>` opens it on a section.

**Modes.** Do Not Disturb, night light (`hyprsunset -t <kelvin>`, 2500-6500 K) and keep awake (an idle inhibitor held
by the bar). Do Not Disturb and night light are remembered in `~/.local/state/dotfiles/modes.json`.
`qs ipc call modes toggleDnd | toggleNight | toggleAwake | setWarmth <kelvin>`.

## The bar

A menu bar on every monitor with no background of its own, so its text sits directly on the wallpaper (`barOpacity` in
`Theme.qml`; raise it for a solid strip). Left: workspaces (`[1] 2 3`) and the focused app's name. Right: the date and
clock, and the notification bell at the very end. It is **quiet**: status appears on the main monitor only when it needs
attention.

| Item | Shown when |
|---|---|
| `bat` | 30% or less, or charging |
| `vol` | muted |
| `wifi` / `net` | there is no connection |
| `bt` | a device is connected |
| coffee cup | Keep awake is on (click to turn off) |
| red `rec 0:12` | a recording is running (click to stop) |

`Super + B` hides or shows the bar. If the main monitor is unplugged, the laptop's bar takes over the status area.

## Design rules

Everything about how the shell looks comes from `Theme.qml`; no colour, size, spring or duration is written anywhere else
(`scripts/ui-check` enforces it).

- **Shape.** Windows and floating cards have radius 10 (`radiusCard`; Hyprland's `rounding` matches). A row or button
  inside a card has radius 6 (`radiusRow`): the card radius minus the 4 px gap to its edge (`cardInset`), so the curves
  stay parallel. Small marks use `radiusSmall`.
- **One card.** The panel, the pickers and the indicator are all built from `ui/Card.qml`: frosted glass (a slightly
  see-through surface that Hyprland blurs, see the `blur-cards` rule in `hypr/modules/rules.lua`), a hairline border, a
  soft shadow and the shared enter / exit animation (`springSmooth` on entrance and dynamic height; on exit the zoom
  and slide run on the fade's own `durFast` / `easeOut`, so the card visibly shrinks while it fades). A card lives in a fixed-size window that leaves `shadowMargin` free on each side; only the card
  resizes, never the window (resizing a layer window makes the compositor smear the old frame).
- **Hover and selection** are a light wash over the card (`hover`, `selected`); the selected row in a list also gets an
  accent mark. Colour washes fade in `durFast`, while sliding selection highlights move with `springSnappy`. An "on" tile
  uses the same sign (wash + accent mark); an "off" tile is only a hairline outline. Solid accent fills are avoided: they
  shout over the text.
- **Type.** Sizes come from `fontSmall` 11, `fontBase` 12 (also the bar), `fontLarge` 14, `fontXL` 16.
- **Motion.**
  - Spatial properties (`x`, `y`, `width`, `height`, `scale`) use `SpringAnimation` with `Theme.epsNorm` / `Theme.epsPx`
    settling thresholds so animations preserve velocity when interrupted and terminate cleanly: `Theme.springSnappy` /
    `Theme.dampingSnappy` for tactile controls and sliding highlights (`Picker`, `AppMenu`, `Segmented`, `PowerMenu`,
    `Switch`, sliders), and `Theme.springSmooth` / `Theme.dampingSmooth` for `Card` entrance and dynamic height, bar
    slide in, and notification stack `add` and `displaced` transitions. In `AppMenu` the view follows the highlight's
    spring (it scrolls just enough each frame to keep it in view) instead of jumping with `positionViewAtIndex`.
  - Non-spatial properties (`opacity`, `color`) and dismissals never overshoot: they use `durFast` 90 ms, `durBase`
    140 ms, `durSlow` 240 ms, `durAmbient` 400 ms (wallpaper and bar colours) with `easeOut` (`easeInOut` for
    cross-fades). An exit moves on the same `durFast` / `easeOut` as its fade (`Card`, bar slide out, `windowsOut`), so
    the motion is seen before the item is gone.
  - Notifications leave in order: the dismissed card fades, shrinks and drifts `exitDrift` aside, and `removeDisplaced`
    waits `durFast` before the stack closes the gap. A `ListView` with transitions must keep a fixed height (never
    `min(contentHeight, ...)`): one that shrinks at the moment of a removal drops the removed item at once and blanks
    for a frame. Size a separate item for the input mask instead.
  - The wallpaper changes by fading only the incoming image in on top of the outgoing one, which stays opaque; fading
    both at once shows the background through them (a 25% dip halfway).
  - Hyprland (`hypr/modules/look.lua`) uses matched native `type = "spring"` curves (`springSmooth` for windows,
    `springFluid` for workspaces and the scratchpad drawer). A spring leaf ignores `speed` (it is still required, so it
    stays as documentation). `scripts/ui-check` compares the spring physics (damping ratio and frequency) of QML and
    Hyprland, checks every shell layer namespace is `no_anim`, and bans inline spring numbers.
- **Icons** come from `Theme.glyph*`, never typed inline.
- **New pieces** should use `Card`, the tokens and the Hyprland rules above, so they match without extra work.
- **Check animations** by recording (`wf-recorder`, constant frame rate) and measuring frame to frame. Compare direct
  `grim` screenshots to look for leftovers: video compression adds noise on detailed images.

## External monitor brightness (ddcutil)

Needs two things:

1. **Access to `/dev/i2c-*`.** The ddcutil package's udev rule grants it, but devices that existed before the package was
   installed need the rules re-applied (a logout does not do it; a reboot does): `./install.sh services`, or
   `sudo udevadm trigger --subsystem-match=i2c-dev && sudo udevadm settle`.
2. **DDC/CI switched on in the monitor's own on-screen menu.** Some monitors ship with it off; some ports do not support
   it.

Check with `ddcutil detect`: the monitor should appear as "Display 1". The control center says `no DDC access`,
`DDC/CI off or unsupported` or `ddcutil not installed` for a monitor it cannot reach, and looks again each time it opens.
