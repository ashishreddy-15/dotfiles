import QtQuick
import qs

// One entry in an expanded list (a network, a device, an output), lined up under the Line's value.
Item {
    id: root

    property string text
    property string detail                     // small dim text at the end, e.g. "58%"
    property color color: Theme.text
    property color rightColor: Theme.dim
    property bool marked: false                // the current / connected one

    signal clicked()

    width: parent.width
    height: 28

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: area.containsMouse ? Theme.raised : "transparent"
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    StyledText {
        x: 62
        width: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.marked ? "●" : ""
        color: Theme.accent
    }
    StyledText {
        x: 78
        width: parent.width - 78 - rightText.implicitWidth - 20
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.marked ? Theme.bright : root.color
        elide: Text.ElideRight
    }
    StyledText {
        id: rightText
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.detail
        color: root.rightColor
    }
}
