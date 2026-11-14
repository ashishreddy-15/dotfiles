import QtQuick
import qs

// Small icons for modes that are easy to forget, shown only while they are on (the bar's "quiet" rule):
//   coffee cup      Keep awake: the screen will not lock or sleep (amber: it matters for security)
//   crossed bell    Silence (Do Not Disturb): pop-ups are held back
// Click one to turn that mode off.
Row {
    id: root

    spacing: 12
    visible: Modes.keepAwake || Modes.dnd

    component ModeIcon: BarText {
        id: icon
        property bool on: false
        signal turnOff()
        visible: on
        anchors.verticalCenter: parent.verticalCenter
        opacity: area.containsMouse ? 0.7 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        MouseArea {
            id: area
            anchors { fill: parent; margins: -6 }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: icon.turnOff()
        }
    }

    ModeIcon { text: Theme.glyphAwake; color: Theme.barWarn; on: Modes.keepAwake; onTurnOff: Modes.toggleAwake() }
    ModeIcon { text: Theme.glyphSilent; color: Theme.barText; on: Modes.dnd; onTurnOff: Modes.toggleDnd() }
}
