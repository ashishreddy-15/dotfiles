import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// "vol 62%" / "vol muted". Scroll to change the volume (the panel has the mute switch).
// Quiet: shown only while muted (changes are shown by the OSD at the bottom).
StatusItem {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    label: "vol"
    value: !sink ? "--" : muted ? "muted" : percent + "%"
    valueColor: muted ? Theme.warn : Theme.text
    attention: muted

    // PipeWire only reports volume for nodes something is tracking.
    PwObjectTracker { objects: [root.sink] }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (!root.sink?.audio) return
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
        }
    }
}
