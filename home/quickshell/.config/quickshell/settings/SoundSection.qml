import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import "../panel"

// Sound: volume and mute for the output and the microphone, and which device each one uses.
Page {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    function name(node) { return node ? (node.nickname || node.description || node.name) : "none" }

    // PipeWire only reports names and levels for nodes something is tracking.
    PwObjectTracker { objects: root.sinks.concat(root.sources).concat([root.sink, root.source]) }

    SettingRow {
        title: "Output volume"
        description: root.name(root.sink)
        Row {
            spacing: 14
            Slider {
                width: 200
                value: root.sink?.audio?.volume ?? 0
                muted: root.sink?.audio?.muted ?? false
                onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
            }
            StyledText { width: 44; height: 32; horizontalAlignment: Text.AlignRight; text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%" }
        }
    }
    SettingRow {
        title: "Mute output"
        Switch { checked: root.sink?.audio?.muted ?? false; onToggled: { if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted } }
    }
    SettingRow {
        title: "Microphone volume"
        description: root.name(root.source)
        Row {
            spacing: 14
            Slider {
                width: 200
                value: root.source?.audio?.volume ?? 0
                muted: root.source?.audio?.muted ?? false
                onMoved: v => { if (root.source?.audio) root.source.audio.volume = v }
            }
            StyledText { width: 44; height: 32; horizontalAlignment: Text.AlignRight; text: Math.round((root.source?.audio?.volume ?? 0) * 100) + "%" }
        }
    }
    SettingRow {
        title: "Mute microphone"
        Switch { checked: root.source?.audio?.muted ?? false; onToggled: { if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted } }
    }

    GroupLabel { text: "Output device" }
    Repeater {
        model: root.sinks
        ListRow {
            required property var modelData
            title: root.name(modelData)
            marked: modelData === root.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    GroupLabel { visible: root.sources.length > 0; text: "Input device" }
    Repeater {
        model: root.sources
        ListRow {
            required property var modelData
            title: root.name(modelData)
            marked: modelData === root.source
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
}
