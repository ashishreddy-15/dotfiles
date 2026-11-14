import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs

// Small volume / brightness indicator at the bottom-centre of the main monitor.
//   volume:     shown automatically whenever the default output's volume or mute changes
//   brightness: shown when the brightness keys call `qs ipc call osd brightness`
//               (hypridle's dimming doesn't call it, so idle dimming stays silent)
Scope {
    id: root

    property string label: "vol"
    property real value: 0          // 0..1
    property bool muted: false
    property bool shown: false

    function show(newLabel, newValue, newMuted) {
        label = newLabel
        value = Math.max(0, Math.min(1, newValue))
        muted = newMuted
        shown = true
        hideTimer.restart()
    }

    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    // ---- volume ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    // Ignore the readings that arrive at startup / when the output device switches.
    property bool settled: false
    Timer { id: settle; interval: 2000; running: true; onTriggered: root.settled = true }
    onSinkChanged: { settled = false; settle.restart() }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { if (root.settled) root.show("vol", root.sink.audio.volume, root.sink.audio.muted) }
        function onMutedChanged()  { if (root.settled) root.show("vol", root.sink.audio.volume, root.sink.audio.muted) }
    }

    // ---- brightness ----
    Process {
        id: readBrightness
        command: ["brightnessctl", "-m"]   // e.g. "intel_backlight,backlight,3756,12%,30720"
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length >= 5) root.show("bri", Number(f[2]) / Number(f[4]), false)
            }
        }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { readBrightness.running = true }
    }

    // ---- the indicator ----
    PanelWindow {
        screen: ShellState.mainScreen
        visible: root.shown

        anchors.bottom: true                    // bottom only = horizontally centred
        margins.bottom: 80
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 260
        implicitHeight: 38
        color: "transparent"
        mask: Region {}                         // clicks pass straight through
        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            Row {
                anchors.centerIn: parent
                spacing: 12

                StyledText {
                    width: 24
                    text: root.label
                    color: Theme.dim
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 150
                    height: 4
                    radius: 2
                    color: Theme.border
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width * root.value
                        height: parent.height
                        radius: parent.radius
                        color: root.muted ? Theme.dim : Theme.accent
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                }

                StyledText {
                    width: 40
                    text: root.muted ? "muted" : Math.round(root.value * 100)
                    horizontalAlignment: Text.AlignRight
                    color: root.muted ? Theme.dim : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
