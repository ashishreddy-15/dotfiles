pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The shell's on/off modes: Do Not Disturb, night light, keep awake.
//   Do Not Disturb  pop-ups stay hidden (critical ones still show); everything still goes to the history
//   night light     warms the screen colour with hyprsunset (2500 K warm .. 6500 K neutral)
//   keep awake      stops the screen from locking or sleeping (an idle inhibitor held by the bar, see Bar.qml)
// Do Not Disturb and night light are remembered across restarts; keep awake always starts off.
//
//   qs ipc call modes toggleDnd | toggleNight | toggleAwake | setWarmth <kelvin>
Singleton {
    id: root

    property bool dnd: false
    property bool nightLight: false
    property int kelvin: 4000
    property bool keepAwake: false

    readonly property int kelvinMin: 2500
    readonly property int kelvinMax: 6500

    function toggleDnd()   { dnd = !dnd; save() }
    function toggleAwake() { keepAwake = !keepAwake }
    function toggleNight() { nightLight = !nightLight; save() }
    function setWarmth(k) {
        kelvin = Math.max(kelvinMin, Math.min(kelvinMax, Math.round(k / 100) * 100))
        save()
        if (nightLight) restart.restart()          // apply the new value (after the slider stops moving)
    }

    IpcHandler {
        target: "modes"
        function toggleDnd(): void { root.toggleDnd() }
        function toggleNight(): void { root.toggleNight() }
        function toggleAwake(): void { root.toggleAwake() }
        function setWarmth(kelvin: int): void { root.setWarmth(kelvin) }
    }

    // ---- remember dnd / night light ----
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/modes.json"

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
        writer.json = JSON.stringify({ dnd: dnd, nightLight: nightLight, kelvin: kelvin })
        writer.running = true
    }

    Component.onCompleted: {
        try {
            const d = JSON.parse(saved.text())
            dnd = !!d.dnd
            kelvin = Number(d.kelvin) || 4000
            nightLight = !!d.nightLight
        } catch (e) { /* first run: defaults */ }
    }

    // ---- night light: hyprsunset runs while it is on ----
    Process {
        id: sunset
        command: ["hyprsunset", "-t", String(root.kelvin)]
    }
    onNightLightChanged: sunset.running = nightLight

    // hyprsunset takes its temperature on the command line, so a new value means starting it again.
    Timer {
        id: restart
        interval: 300
        onTriggered: { sunset.running = false; again.start() }
    }
    Timer { id: again; interval: 200; onTriggered: if (root.nightLight) sunset.running = true }
}
