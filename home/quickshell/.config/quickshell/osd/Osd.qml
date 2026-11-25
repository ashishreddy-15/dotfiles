import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs
import "../ui"

// Small volume / brightness indicator at the bottom-centre of a monitor: the one you are using for
// volume, the one being adjusted for brightness.
//   volume:     shown automatically whenever the default output's volume or mute changes
//   brightness: shown when Brightness reports a change (keys, panel slider), on that screen;
//               "no control" if the focused screen can't be adjusted.
//               (hypridle's dimming doesn't go through Brightness, so idle dimming stays silent)
Scope {
    id: root

    property string label: "vol"
    property real value: 0          // 0..1
    property bool muted: false
    property bool shown: false
    property bool mounted: false
    onShownChanged: if (shown) mounted = true; else if (!loader.item || !loader.item.alive) mounted = false
    property string screenName: ""  // which monitor shows it
    property string note: ""        // text instead of the number, e.g. "no control"

    function show(newLabel, newValue, newMuted, onScreen, newNote) {
        label = newLabel
        value = Math.max(0, Math.min(1, newValue))
        muted = newMuted
        screenName = onScreen ?? Hyprland.focusedMonitor?.name ?? ""
        note = newNote ?? ""
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
    Connections {
        target: Brightness
        function onChanged(name, level) { root.show("bri", level, false, name) }
        function onUnavailable(name) { root.show("bri", 0, false, name, "no control") }
    }

    // ---- the indicator ----
    LazyLoader {
        id: loader
        active: root.shown || root.mounted

        PanelWindow {
            id: win

            property bool ready: false
            readonly property bool alive: card.shown > 0
            Component.onCompleted: Qt.callLater(() => ready = true)
            onAliveChanged: if (!alive && !root.shown) Qt.callLater(() => { if (!root.shown && (!loader.item || !loader.item.alive)) root.mounted = false })

            screen: Quickshell.screens.find(s => s.name === root.screenName) ?? ShellState.mainScreen
            visible: root.shown || card.shown > 0    // stay mapped until the exit animation is done

            anchors.bottom: true                    // bottom only = horizontally centred
            margins.bottom: 80 - Theme.shadowMargin
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 260 + 2 * Theme.shadowMargin
            implicitHeight: 38 + 2 * Theme.shadowMargin
            color: "transparent"
            mask: Region {}                         // clicks pass straight through
            WlrLayershell.namespace: "quickshell-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            Card {
                id: card
                x: Theme.shadowMargin
                y: Theme.shadowMargin
                width: 260
                open: root.shown && win.ready
                origin: Item.Bottom
                contentHeight: 38

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    StyledText {
                        width: 24
                        text: root.label
                        color: Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // The level (bar and number) and the note ("no control") share one place and cross-fade,
                    // so switching between a screen that has a control and one that has none does not pop.
                    Item {
                        width: 150 + 12 + 40
                        height: Math.max(level.implicitHeight, noteText.implicitHeight)
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            id: level
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            opacity: root.note === "" ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }

                            Rectangle {
                                width: 150
                                height: 4
                                radius: Theme.radiusSmall
                                color: Theme.border
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: parent.width * (root.note === "" ? root.value : 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: root.muted ? Theme.dim : Theme.accent
                                    ValueMotion on width {}
                                }
                            }

                            StyledText {
                                width: 40
                                text: root.muted ? "muted" : Math.round(root.value * 100)
                                horizontalAlignment: Text.AlignRight
                                color: root.muted ? Theme.dim : Theme.text
                                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            id: noteText
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            // Keeps the last note while it fades out (root.note is already "" by then).
                            Binding on text { when: root.note !== ""; value: root.note; restoreMode: Binding.RestoreNone }
                            color: Theme.warn
                            opacity: root.note !== "" ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
                        }
                    }
                }
            }
        }
    }
}
