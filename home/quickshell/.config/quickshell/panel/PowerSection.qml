import QtQuick
import Quickshell
import qs
import "../ui"

// lock  logout  suspend  reboot  shutdown
// The ones that end your session ask for a second click ("reboot?") before they act.
Row {
    id: root

    property string confirming: ""
    signal done()                       // an action was started; the panel can close

    readonly property var actions: [
        { name: "lock",     ask: false, command: ["loginctl", "lock-session"] },
        { name: "logout",   ask: true,  command: ["uwsm", "stop"] },
        { name: "suspend",  ask: false, command: ["systemctl", "suspend"] },
        { name: "reboot",   ask: true,  command: ["systemctl", "reboot"] },
        { name: "shutdown", ask: true,  command: ["systemctl", "poweroff"] }
    ]

    function activate(a) {
        if (a.ask && confirming !== a.name) { confirming = a.name; reset.restart(); return }
        confirming = ""
        Quickshell.execDetached(a.command)
        done()
    }

    // Forget an unanswered question after a few seconds.
    Timer { id: reset; interval: 4000; onTriggered: root.confirming = "" }

    spacing: 0

    Repeater {
        model: root.actions

        Item {
            id: cell
            required property var modelData
            readonly property bool asking: root.confirming === modelData.name

            width: root.width / root.actions.length
            height: 32

            // Keyboard: Enter or Space presses it.
            activeFocusOnTab: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.activate(cell.modelData); event.accepted = true }
            }

            Rectangle {
                anchors { fill: parent; margins: 2 }
                radius: Theme.radiusRow
                color: area.containsMouse ? Theme.hover : Theme.clear
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activate(cell.modelData)
            }
            StyledText {
                anchors.centerIn: parent
                text: cell.asking ? cell.modelData.name + "?" : cell.modelData.name
                color: cell.asking ? Theme.warn : Theme.dim
            }

            FocusRing { visible: cell.activeFocus }
        }
    }
}
