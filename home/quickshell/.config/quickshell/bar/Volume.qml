import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// "vol 62%" / "vol muted". Scroll to change, click to mute.
StatusItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    label: "vol"
    value: !sink ? "--" : muted ? "muted" : percent + "%"
    valueColor: (!sink || muted) ? Theme.dim : Theme.text

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
