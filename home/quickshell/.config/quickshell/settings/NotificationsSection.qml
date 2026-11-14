import QtQuick
import Quickshell
import qs

// Notifications: Do Not Disturb, and the history (everything that came in and has not been dismissed, newest first).
// Click an entry to dismiss it.
Page {
    id: root

    function ago(ms) {
        const m = Math.floor((Date.now() - ms) / 60000)
        if (m < 1) return "now"
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d"
    }

    SettingRow {
        title: "Do Not Disturb"
        description: "Hides pop-ups. Urgent ones still show, and everything still goes to the history."
        Switch { checked: Modes.dnd; onToggled: Modes.toggleDnd() }
    }

    Item {
        width: parent.width
        height: 46
        StyledText {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: "History"
            color: Theme.dim
            font.pixelSize: Theme.fontSmall
        }
        Rectangle {
            visible: Notifs.count > 0
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: clearText.implicitWidth + 24
            height: 28
            radius: Theme.radiusRow
            color: clearArea.containsMouse ? Theme.hover : Theme.clear
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            StyledText { id: clearText; anchors.centerIn: parent; text: "Clear all"; color: Theme.text }
            MouseArea { id: clearArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
        }
    }

    StyledText {
        visible: Notifs.count === 0
        leftPadding: 12
        topPadding: 4
        text: "Nothing here"
        color: Theme.dim
    }

    Repeater {
        model: Notifs.history

        Item {
            id: entry
            required property int nid
            required property string appName
            required property string summary
            required property string body
            required property double time
            required property int urgency

            width: root.width
            height: col.implicitHeight + 16

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
                onClicked: Notifs.dismiss(entry.nid)
            }

            Column {
                id: col
                x: 12
                y: 8
                width: parent.width - 24
                spacing: 2

                Row {
                    spacing: 8
                    StyledText { text: entry.appName; color: entry.urgency === 2 ? Theme.err : Theme.dim; font.pixelSize: Theme.fontSmall }
                    StyledText { text: root.ago(entry.time); color: Theme.dim; font.pixelSize: Theme.fontSmall }
                }
                StyledText { width: parent.width; text: entry.summary; color: Theme.bright; elide: Text.ElideRight }
                StyledText {
                    width: parent.width
                    visible: text !== ""
                    text: entry.body
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.dim
                }
            }
        }
    }
}
