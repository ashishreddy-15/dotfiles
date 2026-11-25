import QtQuick
import qs

// One entry in the sidebar of the Settings window: its icon and its name.
// The selected wash and accent mark are not drawn here: SettingsWindow.qml draws one pill that slides to the current entry.
Rectangle {
    id: root

    property string text
    property string glyph
    property bool current: false
    signal clicked()

    width: parent.width
    height: 36
    radius: Theme.radiusRow
    // Only the hover wash (the current entry already sits on the pill).
    color: area.containsMouse && !current ? Theme.hover : Theme.clear
    Behavior on color { ColorAnimation { duration: Theme.durFast } }

    StyledText {
        x: 16
        width: 18
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: root.current ? Theme.bright : Theme.dim
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    StyledText {
        x: 44
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.current ? Theme.bright : Theme.text
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
