import QtQuick
import qs

// One row of the panel:  label | value | [on/off switch] [▸]
// Click the row (e.g. to expand it); the on/off text has its own click.
Item {
    id: root

    property string label
    property string value
    property color valueColor: Theme.text
    property string toggleText: ""            // "on" / "off"; empty = no switch
    property color toggleColor: Theme.dim
    property bool expandable: false
    property bool expanded: false

    signal clicked()
    signal toggled()

    width: parent.width
    height: 32

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
        x: 10
        width: 64
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.dim
    }
    StyledText {
        x: 78
        width: parent.width - 78 - tail.width - 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.valueColor
        elide: Text.ElideRight
    }
    Row {
        id: tail
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 12

        StyledText {
            visible: root.toggleText !== ""
            text: root.toggleText
            color: root.toggleColor
            MouseArea {
                anchors { fill: parent; margins: -6 }
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggled()
            }
        }
        StyledText {
            visible: root.expandable
            text: root.expanded ? "▾" : "▸"
            color: Theme.dim
        }
    }
}
