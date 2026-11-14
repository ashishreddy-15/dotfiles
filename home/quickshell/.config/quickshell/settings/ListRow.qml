import QtQuick
import qs
import "../ui"

// A row in a list of things you can pick or connect to (a network, a device, a sound output).
//   ListRow { title: "Home"; detail: "82%"; marked: connected; onClicked: ... }
Item {
    id: root

    property string title
    property string subtitle
    property string detail                      // dim text at the end, e.g. "82%" or "paired"
    property color detailColor: Theme.dim
    property bool marked: false                 // the current / connected one
    property bool clickable: true

    signal clicked()

    // Keyboard: Enter or Space picks it.
    activeFocusOnTab: clickable
    Keys.onPressed: event => {
        if (clickable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) { root.clicked(); event.accepted = true }
    }

    width: parent.width
    height: subtitle !== "" ? 52 : 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusRow
        color: root.marked ? Theme.selected : (area.containsMouse && root.clickable ? Theme.hover : Theme.clear)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    StyledText {
        visible: root.marked
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.glyphMark
        color: Theme.accent
        font.pixelSize: Theme.fontMark
    }
    Column {
        anchors { left: parent.left; right: detailText.left; verticalCenter: parent.verticalCenter; leftMargin: 32; rightMargin: 12 }
        spacing: 1
        StyledText { width: parent.width; text: root.title; color: root.marked ? Theme.bright : Theme.text; elide: Text.ElideRight }
        StyledText { visible: root.subtitle !== ""; width: parent.width; text: root.subtitle; color: Theme.dim; font.pixelSize: Theme.fontSmall; elide: Text.ElideRight }
    }
    StyledText {
        id: detailText
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: root.detail
        color: root.detailColor
    }

    FocusRing { visible: root.activeFocus }
}
