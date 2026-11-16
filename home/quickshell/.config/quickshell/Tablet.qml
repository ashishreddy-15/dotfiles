pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Pen tablets: what is connected, your choices for them, and applying those choices to Hyprland, live.
// Choices are kept in ~/.local/state/dotfiles/tablet.json:
//   screen        "current" (the screen you are working on), a monitor's name, or "all"
//   keepRatio     trim the tablet's active area to the screen's shape, so circles stay round
//   orientation   0, 90, 180 or 270 degrees (180 = left-handed)
//   mode          "pen" (the pen's position is the pointer's) or "mouse" (it moves the pointer, like a mouse)
//   expressKeys   the action of each ExpressKey (the tablet-keys helper reads this file at every press)
// They are applied with `hyprctl eval 'hl.device({...})'` per tablet: whenever a choice changes, a tablet is plugged in,
// you move to another screen (the area depends on that screen's shape) or Hyprland reloads its config.
// hypr/modules/tablet.lua holds the default for when the shell is not running.
Singleton {
    id: root

    // The tablet's active area in millimetres (Wacom Intuos BT S, CTL-4100: 152 x 95, the same 16:10 shape as the
    // laptop's screen). Other tablets: put their size here.
    readonly property real areaWidth: 152
    readonly property real areaHeight: 95

    property var tablets: []            // Hyprland's names for the connected tablets' pens
    readonly property bool present: tablets.length > 0
    readonly property string model: present ? "Wacom Intuos BT S" : ""

    property string screen: "current"
    property bool keepRatio: true
    property int orientation: 0
    property string mode: "pen"
    // The ExpressKeys: an action id per key (left to right), done by the tablet-keys helper (home/bin/.local/bin).
    property var expressKeys: ["undo", "redo", "pen", "eraser"]
    property var actions: []            // [{ id, label }] the helper offers (`tablet-keys --actions`)
    // The ExpressKeys need the udev rule (system/udev, installed by ./install.sh services).
    property bool keysReady: false
    Process {
        id: rulesCheck
        running: true
        command: ["test", "-f", "/etc/udev/rules.d/70-tablet-pad.rules"]
        onExited: code => root.keysReady = code === 0
    }

    property int battery: -1            // percent, -1 = unknown
    property string batteryState: ""    // "Charging", "Discharging", "Full"...

    // ---- your choices, on disk ----
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/tablet.json"
    FileView {
        id: saved
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }
    Process {
        id: writer
        property string json
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.stateFile, json]
    }
    function save() {
        writer.json = JSON.stringify({ screen: screen, keepRatio: keepRatio, orientation: orientation, mode: mode, expressKeys: expressKeys })
        writer.running = true
    }
    function setKey(index, action) {
        const keys = expressKeys.slice()
        keys[index] = action
        expressKeys = keys
        save()                          // the helper reads the file at every press: nothing else to do
    }
    Process {
        id: actionLister
        running: true
        command: [Quickshell.env("HOME") + "/.local/bin/tablet-keys", "--actions"]
        stdout: StdioCollector {
            onStreamFinished: root.actions = text.trim().split("\n").filter(l => l.includes("\t"))
                .map(l => ({ id: l.split("\t")[0], label: l.split("\t")[1] }))
        }
    }

    function set(key, value) {
        root[key] = value
        save()
        apply()
    }

    // ---- what is connected ----
    function refresh() {
        if (!lister.running) lister.running = true
        if (!batteryFinder.running) batteryFinder.running = true
        if (!rulesCheck.running) rulesCheck.running = true
    }
    Process {
        id: lister
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const names = JSON.parse(text).tablets.map(t => t.name).filter(n => n && n !== "")
                    const changed = JSON.stringify(names) !== JSON.stringify(root.tablets)
                    root.tablets = names
                    if (changed) root.apply()
                } catch (e) { root.tablets = [] }
            }
        }
    }
    // The battery is in /sys (the tablet reports it over USB and Bluetooth).
    Process {
        id: batteryFinder
        command: ["sh", "-c", 'for d in /sys/class/power_supply/wacom_battery_*; do [ -r "$d/capacity" ] && echo "$(cat "$d/capacity") $(cat "$d/status")" && break; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/^(\d+)\s+(\S+)/)
                root.battery = m ? Number(m[1]) : -1
                root.batteryState = m ? m[2] : ""
            }
        }
    }
    // Plugged in or out: look again every few seconds (cheap: one small hyprctl call).
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }

    // ---- applying ----
    function monitorFor(name) { return Hyprland.monitors.values.find(m => m.name === name) ?? null }
    // The shape (width / height) of the screen area the tablet covers.
    function targetRatio() {
        const mons = Hyprland.monitors.values
        if (screen === "all" && mons.length > 0) {
            const minX = Math.min(...mons.map(m => m.x)), minY = Math.min(...mons.map(m => m.y))
            const maxX = Math.max(...mons.map(m => m.x + m.width / m.scale)), maxY = Math.max(...mons.map(m => m.y + m.height / m.scale))
            return (maxX - minX) / (maxY - minY)
        }
        const m = screen === "current" ? Hyprland.focusedMonitor : monitorFor(screen)
        return m ? m.width / m.height : areaWidth / areaHeight
    }
    // While the handwriting strip is open the whole pad covers the strip: { screen, x, y, w, h } in that screen's logical
    // pixels, or null. Hyprland 0.57 keys used: output + region_position / region_size (the mapped rectangle of the screen,
    // absolute_region_position = false: relative to the screen) + active_area_size / active_area_position (the pad trimmed to
    // the rectangle's shape, so writing is not stretched). Not used in mouse mode (the pen then moves the pointer relatively).
    property var mapRect: null
    readonly property bool mapped: mapRect !== null
    function mapToRect(screenName, x, y, w, h) {
        if (w <= 0 || h <= 0) return
        mapRect = { screen: screenName, x: x, y: y, w: w, h: h }
        apply()
    }
    function restore() {
        if (mapRect === null) return
        mapRect = null
        apply()
    }

    function apply() {
        if (!present) return
        const turned = orientation === 90 || orientation === 270
        // The tablet as you hold it: turned 90 degrees, its long side runs up and down.
        const W = turned ? areaHeight : areaWidth, H = turned ? areaWidth : areaHeight
        const rect = mode === "mouse" ? null : mapRect
        let w = W, h = H
        if (rect || keepRatio) {
            const r = rect ? rect.w / rect.h : targetRatio()
            if (W / H > r) w = H * r; else h = W / r
        }
        // Hyprland measures the active area on the tablet itself (not turned).
        const aw = turned ? h : w, ah = turned ? w : h
        const ax = ((turned ? H : W) - aw) / 2, ay = ((turned ? W : H) - ah) / 2
        const output = rect ? rect.screen : screen === "current" ? "current" : screen === "all" ? "" : screen
        // Always send the region too (zero size = none), so leaving the strip really restores the whole screen.
        const region = rect
            ? ', region_position = { ' + Math.round(rect.x) + ', ' + Math.round(rect.y) + ' }, region_size = { ' + Math.round(rect.w) + ', ' + Math.round(rect.h) + ' }'
            : ', region_position = { 0, 0 }, region_size = { 0, 0 }'
        const lua = tablets.map(n => 'hl.device({ name = "' + n + '", output = "' + output + '", transform = ' + (orientation / 90) +
            ', relative_input = ' + (mode === "mouse") +
            ', active_area_size = { ' + aw.toFixed(1) + ', ' + ah.toFixed(1) + ' }' +
            ', active_area_position = { ' + ax.toFixed(1) + ', ' + ay.toFixed(1) + ' }' + region +
            ', absolute_region_position = false })').join("; ")
        lastApplied = lua
        Quickshell.execDetached(["hyprctl", "eval", lua])     // detached: two quick calls (map, restore) never drop one
    }

    // What was applied last, to check: `qs ipc call tablet status`.
    property string lastApplied: ""
    IpcHandler {
        target: "tablet"
        function status(): string { return root.present ? root.lastApplied : "no tablet connected" }
        function apply(): void { root.refresh(); root.apply() }
    }

    // The area depends on the screen's shape: follow the screen you are on.
    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() { if (root.screen === "current" && root.keepRatio) root.apply() }
        function onRawEvent(event) { if (event.name === "configreloaded") root.apply() }
    }

    Component.onCompleted: {
        try {
            const d = JSON.parse(saved.text())
            if (d.screen) screen = d.screen
            if (d.keepRatio !== undefined) keepRatio = !!d.keepRatio
            if ([0, 90, 180, 270].includes(d.orientation)) orientation = d.orientation
            if (d.mode === "mouse" || d.mode === "pen") mode = d.mode
            if (Array.isArray(d.expressKeys) && d.expressKeys.length > 0) expressKeys = d.expressKeys
        } catch (e) { /* first run: the defaults */ }
        refresh()
    }
}
