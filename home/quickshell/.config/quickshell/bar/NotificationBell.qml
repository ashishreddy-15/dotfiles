import QtQuick
import qs

// The notification centre's button, at the right end of the bar: a bell, with how many notifications are waiting
// (dim when there are none), or a crossed bell while Silence is on. Click it to open the centre (Super + N too).
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 5

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: Modes.dnd ? Theme.glyphSilent : Theme.glyphBell
            color: Notifs.count > 0 || Modes.dnd ? Theme.barText : Theme.barDim
        }
        BarText {
            visible: Notifs.count > 0
            anchors.verticalCenter: parent.verticalCenter
            text: Notifs.count
        }
    }

    // Hover / pressed wash, the same as the clock area's.
    Rectangle {
        anchors { fill: parent; leftMargin: -8; rightMargin: -8; topMargin: -4; bottomMargin: -4 }
        radius: Theme.radiusRow
        color: Qt.alpha(Theme.barText, area.pressed ? 0.22 : area.containsMouse || ShellState.centerOpen ? 0.12 : 0)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: area
        anchors { fill: parent; margins: -6 }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.centerOpen = !ShellState.centerOpen
    }
}
