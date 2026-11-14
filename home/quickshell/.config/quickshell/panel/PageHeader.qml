import QtQuick
import qs

// The top of a detail page:  ‹ Title                    on
// The ‹ goes back (Esc does too). The optional switch on the right is the same toggle as the tile's.
Item {
    id: root

    property string title
    property string switchText: ""
    property color switchColor: Theme.dim

    signal back()
    signal switched()

    width: parent.width
    height: 36

    Rectangle {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: titleRow.width + 20
        height: 28
        radius: Theme.radiusRow
        color: backArea.containsMouse ? Theme.hover : Theme.clear
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    MouseArea {
        id: backArea
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: titleRow.width + 20
        height: 28
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.back()
    }
    Row {
        id: titleRow
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        StyledText { text: "‹"; color: Theme.dim }
        StyledText { text: root.title; color: Theme.bright }
    }

    StyledText {
        visible: root.switchText !== ""
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.switchText
        color: root.switchColor
        MouseArea {
            anchors { fill: parent; margins: -8 }
            cursorShape: Qt.PointingHandCursor
            onClicked: root.switched()
        }
    }
}
