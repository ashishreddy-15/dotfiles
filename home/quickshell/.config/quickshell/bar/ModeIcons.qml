import QtQuick
import qs
import "../ui"

// Small icons for modes that are easy to forget, shown only while they are on (the bar's "quiet" rule):
//   coffee cup      Keep awake: the screen will not lock or sleep (amber: it matters for security)
// Click it to turn that mode off. (Silence shows as a crossed bell in NotificationBell.qml.)
// Each icon is a Reveal, so turning a mode on or off glides the bar aside instead of shoving it.
Row {
    id: root

    property real gap: Theme.barGap   // space after each icon; the bar sets its own spacing here (it goes inside each reveal)

    component ModeIcon: Reveal {
        id: icon
        property bool on: false
        property alias text: glyph.text
        property alias color: glyph.color
        signal turnOff()
        shown: on
        anchors.verticalCenter: parent.verticalCenter

        BarText {
            id: glyph
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
    }

    ModeIcon { gapAfter: root.gap; text: Theme.glyphAwake; color: Theme.barWarn; on: Modes.keepAwake; onTurnOff: Modes.toggleAwake() }
}
