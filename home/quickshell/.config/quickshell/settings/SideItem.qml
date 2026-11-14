import QtQuick
import qs

// One entry in the sidebar of the Settings window: its icon and its name.
Rectangle {
    id: root

    property string text
    property string glyph
    property bool current: false
    signal clicked()

    width: parent.width
    height: 36
    radius: Theme.radiusRow
    color: current ? Theme.selected : (area.containsMouse ? Theme.hover : Theme.clear)
    Behavior on color { ColorAnimation { duration: Theme.durFast } }

    // The accent mark, as in the pickers.
    Rectangle {
        visible: root.current
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 16
        radius: Theme.radiusMark
        color: Theme.accent
    }

    StyledText {
        x: 16
        width: 18
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: root.current ? Theme.bright : Theme.dim
    }
    StyledText {
        x: 44
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.current ? Theme.bright : Theme.text
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
