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

    // Keyboard: Enter or Space picks it.
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.clicked(); event.accepted = true }
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
        width: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.marked ? Theme.glyphMark : ""
        color: Theme.accent
        font.pixelSize: Theme.fontMark
    }
    StyledText {
        x: 28
        width: parent.width - 28 - rightText.implicitWidth - 20
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

    FocusRing { visible: root.activeFocus }
}
