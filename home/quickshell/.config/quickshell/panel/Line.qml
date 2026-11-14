import QtQuick
import qs

// A navigation row:  label | value | ›    Click it to open something (a page, the wallpaper picker).
Item {
    id: root

    property string label
    property string value
    property color valueColor: Theme.text
    property bool chevron: true

    signal clicked()

    width: parent.width
    height: 32

    // Keyboard: Enter, Space or Right opens it.
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space || event.key === Qt.Key_Right) { root.clicked(); event.accepted = true }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusRow
        color: area.containsMouse ? Theme.hover : Theme.clear
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
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
        width: Theme.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.dim
    }
    StyledText {
        x: Theme.valueX
        width: parent.width - Theme.valueX - (root.chevron ? 30 : 12)
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.valueColor
        elide: Text.ElideRight
    }
    StyledText {
        visible: root.chevron
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: "›"
        color: Theme.dim
    }

    FocusRing { visible: root.activeFocus }
}
