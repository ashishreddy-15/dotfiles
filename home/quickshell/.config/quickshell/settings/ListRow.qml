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
    // Optional second action, e.g. "Forget": a small button that shows while the row is hovered or focused. It asks
    // once more before acting ("Sure?"), since what it removes (a saved password, a pairing) is not easy to get back.
    property string actionText: ""

    signal clicked()
    signal action()

    property bool confirming: false
    function pressAction() {
        if (actionText === "") return
        if (!confirming) { confirming = true; confirmTimeout.restart(); return }
        confirming = false
        action()
    }
    Timer { id: confirmTimeout; interval: 3000; onTriggered: root.confirming = false }
    onActiveFocusChanged: if (!activeFocus) confirming = false
    HoverHandler { id: hover }

    // Keyboard: Enter or Space picks it.
    // Keyboard: Enter or Space picks it; Delete presses the action ("Forget"), twice to confirm.
    activeFocusOnTab: clickable
    Keys.onPressed: event => {
        if (clickable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) root.clicked()
        else if (actionText !== "" && (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace)) root.pressAction()
        else return
        event.accepted = true
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
    Rectangle {
        id: actionButton
        visible: root.actionText !== "" && (hover.hovered || root.activeFocus || root.confirming)
        anchors { right: detailText.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        width: visible ? actionLabel.implicitWidth + 20 : 0
        height: 26
        radius: Theme.radiusSmall
        color: actionArea.containsMouse ? Theme.hover : Theme.clear
        border.width: 1
        border.color: root.confirming ? Theme.warn : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        StyledText {
            id: actionLabel
            anchors.centerIn: parent
            text: root.confirming ? "Sure?" : root.actionText
            color: root.confirming ? Theme.warn : Theme.text
            font.pixelSize: Theme.fontSmall
        }
        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pressAction()
        }
    }

    Column {
        anchors { left: parent.left; right: actionButton.visible ? actionButton.left : detailText.left; verticalCenter: parent.verticalCenter; leftMargin: 32; rightMargin: 12 }
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
