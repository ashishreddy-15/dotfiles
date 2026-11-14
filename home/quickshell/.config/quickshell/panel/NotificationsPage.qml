import QtQuick
import Quickshell
import qs

// Notification history: everything that came in and has not been dismissed, newest first.
// Click an entry to dismiss it. "clear all" dismisses everything.
Column {
    id: root

    signal back()

    function ago(ms) {
        const m = Math.floor((Date.now() - ms) / 60000)
        if (m < 1) return "now"
        if (m < 60) return m + "m"
        const h = Math.floor(m / 60)
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d"
    }

    PageHeader {
        title: "Notifications"
        switchText: Notifs.count > 0 ? "clear all" : ""
        onBack: root.back()
        onSwitched: Notifs.clearAll()
    }

    StyledText {
        visible: Notifs.count === 0
        leftPadding: 10
        topPadding: 8
        bottomPadding: 8
        text: "nothing here"
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
            height: col.implicitHeight + 14

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
                x: 10
                y: 7
                width: parent.width - 20
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
