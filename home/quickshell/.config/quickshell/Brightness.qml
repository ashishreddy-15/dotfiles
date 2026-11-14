pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "brightness"

// Brightness for whichever screen has focus.
//   laptop panel:      brightnessctl (keys work on the lock screen too)
//   external monitors: ddcutil, over DDC/CI. Needs access to /dev/i2c-* (see README) and DDC/CI
//                      switched on in the monitor.
//
//   qs ipc call brightness up | down      change the focused screen (bound to the brightness keys, Super+[ ])
//   qs ipc call brightness dim | undim    every screen down to the idle level and back (hypridle)
//
// Other pieces read `displays` (the screens we can control), call set()/step() on them, and listen to
// `changed` (a person changed a level) and `unavailable` (the focused screen has no control).
Singleton {
    id: root

    property var displays: []              // Display objects, one per controllable screen
    property string backlightDevice: ""    // e.g. "intel_backlight"
    property var ddcScreens: []            // [{ name: "HDMI-A-1", bus: "2" }] found by ddcutil
    // "unknown" (still looking) | "ok" | "none" | "no-access" | "unsupported" | "missing" (ddcutil not installed)
    property string ddcStatus: "unknown"

    // The focused screen. Right after start-up Hyprland may not have announced it yet, so fall back to
    // the monitor list's own "focused" flag.
    readonly property string focusedName: Hyprland.focusedMonitor?.name
        ?? Hyprland.monitors.values.find(m => m.focused)?.name ?? ""

    signal changed(string name, real level)
    signal unavailable(string name)

    function isInternal(name) { return /^(eDP|LVDS|DSI)/.test(name) }

    function displayFor(name) { return displays.find(d => d.name === name) ?? null }

    // Change the focused screen by one step up (+1) or down (-1).
    function adjust(direction) {
        const d = displayFor(focusedName)
        if (!d) { unavailable(focusedName); return }
        d.step(direction * Theme.brightnessStep)
    }

    // Read every real value again (the panel does this when it opens), and look for monitors again if
    // one could not be controlled so far (e.g. after fixing the i2c permission).
    function refresh() {
        for (const d of displays) d.refresh()
        if (ddcStatus !== "ok") redetect.restart()
    }

    // Dim every screen we can control when the computer goes idle, and put each back as it was on activity
    // (hypridle calls these: hypr/hypridle.conf). Screens already darker than the dim level are left alone.
    property var dimmedFrom: ({})          // screen name -> level before dimming; empty when not dimmed
    function dim() {
        if (Object.keys(dimmedFrom).length > 0) return
        const saved = {}
        for (const d of displays) {
            saved[d.name] = d.level
            if (d.level > Theme.idleDimLevel) d.setQuiet(Theme.idleDimLevel)
        }
        dimmedFrom = saved
    }
    function undim() {
        for (const d of displays) if (d.name in dimmedFrom) d.setQuiet(dimmedFrom[d.name])
        dimmedFrom = ({})
    }

    IpcHandler {
        target: "brightness"
        function up(): void { root.adjust(1) }
        function down(): void { root.adjust(-1) }
        function dim(): void { root.dim() }
        function undim(): void { root.undim() }
    }

    // ---- which screens can we control? ----
    readonly property var monitorNames: Hyprland.monitors.values.map(m => m.name)
    readonly property string internalName: monitorNames.find(n => isInternal(n)) ?? ""

    Process {
        id: findBacklight
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n 1"]
        stdout: StdioCollector { onStreamFinished: root.backlightDevice = text.trim() }
    }

    // Parse `ddcutil detect`. A usable monitor is a block that starts with "Display N" and names its
    // I2C bus and DRM connector (card1-HDMI-A-1: the part after "cardN-" is the Hyprland output name).
    function parseDetect(out) {
        const found = []
        for (const block of out.split(/\n(?=Display \d+|Invalid display|Phantom display|Disconnected display)/)) {
            if (!/^Display \d+/.test(block)) continue
            const bus = block.match(/I2C bus:\s+\/dev\/i2c-(\d+)/)
            const conn = block.match(/DRM_connector:\s+card\d+-(\S+)/)
            if (bus && conn) found.push({ name: conn[1], bus: bus[1] })
        }
        ddcScreens = found
        if (found.length > 0) ddcStatus = "ok"
        else if (/not readable and writable|EACCES|Permission denied/i.test(out)) ddcStatus = "no-access"
        else if (/does not support DDC/i.test(out)) ddcStatus = "unsupported"
        else ddcStatus = "none"
    }

    Process {
        id: detect
        command: ["sh", "-c", "ddcutil detect 2>&1"]
        stdout: StdioCollector { onStreamFinished: root.parseDetect(text) }
        onExited: (code, status) => { if (code === 127) root.ddcStatus = "missing" }
    }

    // Look again when screens come or go (not on every change: detection takes a few seconds).
    Timer { id: redetect; interval: 2500; onTriggered: if (!detect.running) detect.running = true }
    Connections {
        target: Hyprland.monitors
        function onValuesChanged() { redetect.restart() }
    }
    Component.onCompleted: { findBacklight.running = true; redetect.start() }

    // ---- one Display object per controllable screen ----
    function collect() {
        const list = []
        for (let i = 0; i < laptop.count; i++) list.push(laptop.objectAt(i))
        for (let i = 0; i < external.count; i++) list.push(external.objectAt(i))
        displays = list
    }

    Instantiator {
        id: laptop
        model: root.backlightDevice !== "" && root.internalName !== ""
            ? [{ name: root.internalName, device: root.backlightDevice }] : []
        delegate: Display {
            required property var modelData
            name: modelData.name
            kind: "backlight"
            device: modelData.device
            onUserChanged: root.changed(name, level)
        }
        onObjectAdded: root.collect()
        onObjectRemoved: root.collect()
    }

    Instantiator {
        id: external
        model: root.ddcScreens.filter(s => root.monitorNames.includes(s.name))
        delegate: Display {
            required property var modelData
            name: modelData.name
            kind: "ddc"
            device: modelData.bus
            onUserChanged: root.changed(name, level)
        }
        onObjectAdded: root.collect()
        onObjectRemoved: root.collect()
    }
}
