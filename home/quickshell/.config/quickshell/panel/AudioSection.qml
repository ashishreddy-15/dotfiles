import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Volume slider (+ mute) and the choice of output device.
Column {
    id: root

    property bool expanded: false
    signal toggleExpanded()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    function name(node) { return node ? (node.nickname || node.description || node.name) : "none" }

    // PipeWire only reports volume and names for nodes something is tracking.
    PwObjectTracker { objects: root.sinks }

    // Volume: click the label to mute.
    Item {
        width: parent.width
        height: 32

        MouseArea {
            x: 0; width: 78; height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
            StyledText {
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "muted" : "vol"
                color: root.muted ? Theme.warn : Theme.dim
            }
        }
        Slider {
            x: 78
            width: parent.width - 78 - 54
            height: parent.height
            value: root.volume
            muted: root.muted
            onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
        }
        StyledText {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.dim : Theme.text
        }
    }

    // Output device
    Line {
        label: "out"
        value: root.name(root.sink)
        expandable: root.sinks.length > 1
        expanded: root.expanded
        onClicked: root.toggleExpanded()
    }
    Repeater {
        model: root.expanded ? root.sinks : []
        ListItem {
            required property var modelData
            text: root.name(modelData)
            marked: modelData === root.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}
