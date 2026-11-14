import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// The power menu (Super + X): lock, log out, suspend, reboot, shut down, as a row of big choices on a frosted card over
// the dimmed screen. The actions are Power.qml's (the same as the control center's footer).
//   Left / Right or Tab move, Enter or Space picks, or press the letter (L, O, S, R, P); Esc or a click outside closes.
//   Log out, reboot and shut down ask once more ("Reboot?"): press again to go ahead.
Scope {
    id: root

    property bool open: false
    property int current: 0
    property string confirming: ""

    IpcHandler {
        target: "power"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    onOpenChanged: {
        confirming = ""
        if (open) { current = 0; Qt.callLater(() => card.forceActiveFocus()) }
    }

    function activate(i) {
        const a = Power.actions[i]
        current = i
        if (a.ask && confirming !== a.name) { confirming = a.name; forget.restart(); return }
        open = false
        Power.run(a)
    }
    // Forget an unanswered question after a few seconds.
    Timer { id: forget; interval: 4000; onTriggered: root.confirming = "" }

    readonly property int tileSize: 112

    PanelWindow {
        id: win

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
        visible: root.open || card.shown > 0

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "quickshell-power"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // The dimmed screen; a click on it closes the menu.
        Rectangle {
            anchors.fill: parent
            color: Theme.shadow
            opacity: card.shown
            MouseArea { anchors.fill: parent; onClicked: root.open = false }
        }

        Card {
            id: card
            anchors.centerIn: parent
            width: row.implicitWidth + 2 * Theme.cardInset * 3
            open: root.open
            contentHeight: root.tileSize + 2 * Theme.cardInset * 3

            focus: true
            Keys.onPressed: event => {
                const n = Power.actions.length
                const byKey = Power.actions.findIndex(a => a.key === event.key)
                if (event.key === Qt.Key_Escape) root.open = false
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) { root.current = (root.current + 1) % n; root.confirming = "" }
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) { root.current = (root.current - 1 + n) % n; root.confirming = "" }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.current)
                else if (byKey >= 0) root.activate(byKey)
                else return
                event.accepted = true
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: Theme.cardInset

                Repeater {
                    model: Power.actions

                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool selected: root.current === index
                        readonly property bool asking: root.confirming === modelData.name

                        width: root.tileSize
                        height: root.tileSize
                        radius: Theme.radiusRow
                        color: selected ? (area.containsMouse ? Theme.selectedHover : Theme.selected)
                                        : (area.containsMouse ? Theme.hover : Theme.clear)
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }

                        // The accent mark under the chosen one, as in the pickers (here at the bottom edge).
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 5 }
                            width: 18
                            height: 2
                            radius: Theme.radiusMark
                            color: tile.asking ? Theme.warn : Theme.accent
                            opacity: tile.selected ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.glyph
                                color: tile.asking ? Theme.warn : tile.selected ? Theme.bright : Theme.text
                                font.pixelSize: Theme.fontIcon
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.asking ? tile.modelData.label + "?" : tile.modelData.label
                                color: tile.asking ? Theme.warn : tile.selected ? Theme.bright : Theme.text
                            }
                        }

                        // The letter that picks it
                        StyledText {
                            anchors { top: parent.top; right: parent.right; margins: 8 }
                            text: String.fromCharCode(tile.modelData.key).toUpperCase()
                            color: Theme.dim
                            font.pixelSize: Theme.fontSmall
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activate(tile.index)
                        }
                    }
                }
            }
        }
    }
}
