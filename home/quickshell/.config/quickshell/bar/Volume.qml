import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// "vol 62%" / "vol muted". Scroll to change, click to mute.
// Quiet: shown while muted, and for a moment after the volume changes.
StatusItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    label: "vol"
    value: !sink ? "--" : muted ? "muted" : percent + "%"
    valueColor: muted ? Theme.warn : Theme.text
    attention: muted || flash.running

    // Flash on change, but not for the first readings after startup.
    onPercentChanged: if (settled) flash.restart()
    property bool settled: false
    Timer { interval: 3000; running: true; onTriggered: root.settled = true }
    Timer { id: flash; interval: 1500 }

    // PipeWire only reports volume for nodes something is tracking.
    PwObjectTracker { objects: [root.sink] }

    TapHandler {
        onTapped: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
    }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (!root.sink?.audio) return
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
        }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
