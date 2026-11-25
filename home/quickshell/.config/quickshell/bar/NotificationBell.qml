import QtQuick
import qs
import "../ui"

// The notification centre's button, at the right end of the bar: a bell, with how many notifications are waiting
// (dim when there are none), or a crossed bell while Silence is on. Click it to open the centre (Super + N too).
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: Modes.dnd ? Theme.glyphSilent : Theme.glyphBell
            color: Notifs.count > 0 || Modes.dnd ? Theme.barText : Theme.barDim
        }
        // The count pops in when the first notification arrives: the gap opens (with the 5 px space to the bell
        // inside it), and the number fades in while it grows from the press-in scale.
        Reveal {
            id: badge
            shown: Notifs.count > 0
            gapBefore: Theme.barGapTight
            anchors.verticalCenter: parent.verticalCenter
            BarText {
                // Keep the last number while it fades out, rather than flashing a "0".
                property int held: Math.max(1, Notifs.count)
                readonly property int count: Notifs.count
                onCountChanged: if (count > 0) held = count
                text: held
                scale: badge.shown ? 1 : Theme.pressScale
                PressMotion on scale {}
            }
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
