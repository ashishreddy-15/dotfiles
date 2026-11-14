import QtQuick
import qs

// An on / off switch.   Switch { checked: thing.on; onToggled: thing.on = !thing.on }
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.accent : Theme.clear
    border.width: 1
    border.color: checked ? Theme.clear : Theme.border
    Behavior on color { ColorAnimation { duration: Theme.durFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

    Rectangle {
        width: parent.height - 8
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Theme.bg : Theme.dim
        Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        anchors { fill: parent; margins: -4 }
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
