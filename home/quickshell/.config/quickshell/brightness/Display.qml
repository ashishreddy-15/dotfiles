import QtQuick
import Quickshell
import Quickshell.Io

// One screen's brightness, over one of two paths:
//   kind "backlight": the laptop panel, through brightnessctl (device = name under /sys/class/backlight)
//   kind "ddc":       an external monitor, through ddcutil (device = the i2c bus number)
//
// `level` (0..1) changes at once when you ask for a change, so sliders and the indicator feel instant.
// The real command follows after a short pause, one at a time, and only ever for the newest wanted value:
// holding a key sends a handful of commands, not dozens. That matters for DDC, where a single command
// takes a fraction of a second.
Scope {
    id: root

    property string name                 // Hyprland output name, e.g. "HDMI-A-1"
    property string kind: "backlight"
    property string device
    property string label: kind === "ddc" ? "monitor" : "laptop"

    property real level: 0
    property bool ready: false           // we have read the real value at least once
    property int maxValue: 100           // DDC: the monitor's own maximum, read from it
    property int wanted: -1              // value (0..maxValue) waiting to be sent, -1 = nothing
    property int sent: -1
    property bool warned: false

    signal userChanged()                 // someone asked for a change (keys, slider)

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    function set(v) {
        level = clamp(v)
        wanted = Math.round(level * maxValue)
        pause.restart()
        userChanged()
    }
    function step(delta) { set(level + delta) }

    // Read the real value again (e.g. when the panel opens). Never while a change is on its way.
    function refresh() {
        if (!reader.running && !writer.running && wanted < 0 && !pause.running) reader.running = true
    }

    // ---- the two paths ----
    readonly property var readCommand: kind === "ddc"
        ? ["ddcutil", "--bus", device, "getvcp", "10", "--brief"]
        : ["brightnessctl", "-e4", "-m", "-d", device]

    function writeCommand(value) {
        return kind === "ddc"
            ? ["ddcutil", "--bus", device, "setvcp", "10", String(value), "--noverify"]
            : ["brightnessctl", "-e4", "-n2", "-d", device, "set", value + "%"]
    }

    // Level (0..1) from a read command's output, or -1 if it did not make sense.
    function parse(text) {
        if (kind === "ddc") {
            // "VCP 10 C 50 100": feature, type, current, maximum
            const m = text.match(/VCP\s+10\s+C\s+(\d+)\s+(\d+)/i)
            if (!m || Number(m[2]) === 0) return -1
            maxValue = Number(m[2])
            return Number(m[1]) / maxValue
        }
        // "intel_backlight,backlight,3756,59%,30720": the percentage is on the -e4 curve
        const f = text.trim().split(",")
        const p = f.length >= 4 ? parseInt(f[3]) : NaN
        return isNaN(p) ? -1 : p / 100
    }

    function flush() {
        if (wanted < 0 || writer.running) return      // writer.onExited sends the newest value when it is done
        sent = wanted
        writer.command = writeCommand(sent)
        writer.running = true
    }

    Timer { id: pause; interval: root.kind === "ddc" ? 150 : 30; onTriggered: root.flush() }

    Process {
        id: reader
        command: root.readCommand
        stdout: StdioCollector {
            onStreamFinished: {
                const l = root.parse(text)
                if (l < 0) return
                root.ready = true
                if (root.wanted < 0 && !pause.running) root.level = l     // don't fight a change in progress
            }
        }
    }

    Process {
        id: writer
        onExited: (code, status) => {
            if (code !== 0 && !root.warned) {
                root.warned = true
                console.warn("brightness:", root.name, "(" + root.kind + ") command failed with code", code)
            }
            if (root.wanted !== root.sent) root.flush()     // something newer was asked for meanwhile
            else root.wanted = -1
        }
    }

    Component.onCompleted: reader.running = true
}
