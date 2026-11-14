import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Choose where sound comes out (speakers, headphones, HDMI...).
Column {
    id: root

    signal back()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)

    function name(node) { return node ? (node.nickname || node.description || node.name) : "none" }

    // PipeWire only reports names for nodes something is tracking.
    PwObjectTracker { objects: root.sinks }

    PageHeader { title: "Sound output"; onBack: root.back() }

    Repeater {
        model: root.sinks
        ListItem {
            required property var modelData
            text: root.name(modelData)
            marked: modelData === root.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}
