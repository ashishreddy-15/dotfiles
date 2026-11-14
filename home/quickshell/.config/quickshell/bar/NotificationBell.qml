import QtQuick
import qs

// The notification centre's bell: shown while there are notifications you have not dealt with (with how many), or
// while Silence is on (then a crossed bell). Click it to open the centre (Super + N does the same).
Item {
    id: root

    visible: Notifs.count > 0 || Modes.dnd
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 5

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: Modes.dnd ? Theme.glyphSilent : Theme.glyphBell
        }
        BarText {
            visible: Notifs.count > 0
            anchors.verticalCenter: parent.verticalCenter
            text: Notifs.count
        }
    }

    MouseArea {
        anchors { fill: parent; margins: -6 }
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.centerOpen = !ShellState.centerOpen
    }
}
