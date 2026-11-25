import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// The Bluetooth pairing prompt: BlueZ's questions while a device pairs, put to you. The agent (home/bin/.local/bin/bt-agent)
// shows it with `qs ipc call bluetooth ask <id> <kind> <device> <value>` and waits; your answer goes back to the agent
// over the session bus. Nothing is accepted without a click (or Enter) here. Esc, Cancel or a click outside declines.
//   kind  confirm    check that the code on the device matches          (value: the code)
//         authorize  a device asks to pair
//         service    a device asks to connect
//         pin        type the PIN (pre-filled with 0000, what headsets use)
//         passkey    type the number shown on the device
//         show       type this code on the device (nothing to answer)
Scope {
    id: root

    property bool open: false
    property bool mounted: false
    onOpenChanged: if (open) mounted = true; else if (!loader.item || !loader.item.alive) mounted = false
    property int requestId: 0
    property string kind: ""
    property string device: ""
    property string value: ""
    property string initialInput: ""

    readonly property bool needsInput: kind === "pin" || kind === "passkey"
    readonly property string title: kind === "service" ? "Allow " + device + "?"
                                  : kind === "show" ? "Pairing with " + device
                                  : kind === "pin" ? "PIN for " + device
                                  : kind === "passkey" ? "Passkey for " + device
                                  : "Pair with " + device + "?"
    readonly property string body: kind === "confirm" ? "Pair only if " + device + " shows this code too."
                                 : kind === "authorize" ? device + " wants to pair with this computer."
                                 : kind === "service" ? device + " wants to connect to this computer."
                                 : kind === "pin" ? "Headsets and speakers usually use 0000."
                                 : kind === "passkey" ? "Type the number shown on " + device + "."
                                 : "Type this code on " + device + "."
    readonly property string acceptText: kind === "service" ? "Allow" : kind === "show" ? "OK" : "Pair"

    IpcHandler {
        target: "bluetooth"
        function ask(id: int, kind: string, device: string, value: string): void {
            root.requestId = id
            root.kind = kind
            root.device = device
            root.value = value
            root.initialInput = kind === "pin" ? value : ""
            if (loader.item) loader.item.setInput(root.initialInput)
            root.open = true
        }
        // BlueZ gave up (timeout, or the device went away).
        function cancel(): void { root.open = false }
    }

    function answer(accept, typed) {
        if (!open) return
        open = false
        if (kind === "show" || requestId === 0) return          // nothing is waiting
        reply.command = ["gdbus", "call", "--session", "--dest", "dev.dotfiles.BluetoothAgent",
                         "--object-path", "/dev/dotfiles/BluetoothAgent", "--method", "dev.dotfiles.BluetoothAgent.Answer",
                         String(requestId), accept ? "true" : "false", needsInput ? (typed ?? "") : ""]
        reply.running = true
    }
    Process { id: reply }

    LazyLoader {
        id: loader
        active: root.open || root.mounted

        PanelWindow {
            id: win

            property bool ready: false
            readonly property bool alive: card.shown > 0
            function setInput(t) { input.text = t }
            onAliveChanged: if (!alive && !root.open) Qt.callLater(() => { if (!root.open && (!loader.item || !loader.item.alive)) root.mounted = false })

            Component.onCompleted: Qt.callLater(() => { ready = true; (root.needsInput ? input : card).forceActiveFocus() })
            Connections {
                target: root
                function onOpenChanged() { if (root.open) Qt.callLater(() => (root.needsInput ? input : card).forceActiveFocus()) }
            }

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
            visible: root.open || card.shown > 0

            // No anchors: centred.
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 440 + 2 * Theme.shadowMargin
            implicitHeight: 260 + 2 * Theme.shadowMargin
            color: "transparent"
            mask: Region { item: card }
            WlrLayershell.namespace: "quickshell-pairing"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                active: root.open
                windows: [win]
                onCleared: root.answer(false, input.text)
            }

            Card {
                id: card
                x: Theme.shadowMargin
                y: Theme.shadowMargin
                width: 440
                open: root.open && win.ready
                contentHeight: column.implicitHeight + 2 * 24

                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.answer(false, input.text)
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.answer(true, input.text)
                    else return
                    event.accepted = true
                }

                Column {
                    id: column
                    x: 24
                    y: 24
                    width: parent.width - 48
                    spacing: 12

                    StyledText {
                        width: parent.width
                        text: root.title
                        color: Theme.bright
                        font.pixelSize: Theme.fontLarge
                        elide: Text.ElideRight
                    }
                    StyledText {
                        width: parent.width
                        text: root.body
                        color: Theme.dim
                        wrapMode: Text.Wrap
                    }

                    // The code to compare or to type on the device
                    StyledText {
                        visible: root.kind === "confirm" || root.kind === "show"
                        text: root.value
                        color: Theme.bright
                        font.pixelSize: Theme.fontXL
                        font.letterSpacing: 4
                    }

                    // PIN or passkey
                    Rectangle {
                        visible: root.needsInput
                        width: parent.width
                        height: 34
                        radius: Theme.radiusRow
                        color: Theme.hover
                        border.width: 1
                        border.color: input.activeFocus ? Theme.accent : Theme.border

                        TextInput {
                            id: input
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.initialInput
                            color: Theme.bright
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBase
                            inputMethodHints: Qt.ImhDigitsOnly
                            clip: true
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) { root.answer(false, input.text); event.accepted = true }
                                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.answer(true, input.text); event.accepted = true }
                            }
                        }
                    }

                    // Buttons: Cancel, then the one that accepts
                    Item {
                        width: parent.width
                        height: 34

                        component Button: Rectangle {
                            id: btn
                            property string text
                            property bool primary: false
                            signal clicked()
                            width: label.implicitWidth + 32
                            height: 34
                            radius: Theme.radiusRow
                            color: primary ? (area.containsMouse ? Theme.selectedHover : Theme.selected)
                                           : (area.containsMouse ? Theme.hover : Theme.clear)
                            border.width: 1
                            border.color: primary ? Theme.accent : Theme.border
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                            StyledText { id: label; anchors.centerIn: parent; text: btn.text; color: btn.primary ? Theme.bright : Theme.text }
                            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
                        }

                        Row {
                            anchors.right: parent.right
                            spacing: 8
                            Button { visible: root.kind !== "show"; text: "Cancel"; onClicked: root.answer(false, input.text) }
                            Button { text: root.acceptText; primary: true; onClicked: root.answer(true, input.text) }
                        }
                    }
                }
            }
        }
    }
}
