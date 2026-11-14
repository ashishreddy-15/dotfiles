import QtQuick
import Quickshell
import qs
import "../ui"

// Notifications: Silence (Do Not Disturb), and the archive: every notification of the last Notifs.archiveDays days
// (dismissed ones too), grouped by day, read-only. Filter by day, search, or clear it.
// (New notifications you have not dealt with yet are in the notification centre: the bell in the bar.)
Page {
    id: root

    property string range: "today"          // today | yesterday | week | all
    property string query: ""

    // ---- the entries to show, with a heading before each new day ----
    function startOfDay(offset) { const d = new Date(); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() + offset); return d.getTime() }
    function dayName(ms) {
        if (ms >= startOfDay(0)) return "Today"
        if (ms >= startOfDay(-1)) return "Yesterday"
        return Qt.formatDate(new Date(ms), "dddd d MMMM")
    }
    readonly property var shown: {
        const from = range === "today" ? startOfDay(0) : range === "yesterday" ? startOfDay(-1) : range === "week" ? startOfDay(-6) : 0
        const to = range === "yesterday" ? startOfDay(0) : Infinity
        const q = query.trim().toLowerCase()
        const rows = []
        let day = ""
        for (const e of Notifs.archive) {
            if (e.time < from || e.time >= to) continue
            if (q !== "" && !((e.app + " " + e.summary + " " + e.body).toLowerCase().includes(q))) continue
            const d = dayName(e.time)
            if (d !== day) { rows.push({ heading: d }); day = d }
            rows.push({ entry: e })
        }
        return rows
    }

    SettingRow {
        title: "Silence"
        description: "Holds pop-ups back (urgent ones still show). Everything still arrives in the notification centre and here."
        Switch { checked: Modes.dnd; onToggled: Modes.toggleDnd() }
    }

    // ---- filters ----
    Item {
        width: parent.width
        height: 56

        Segmented {
            id: ranges
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            options: [{ label: "Today", value: "today" }, { label: "Yesterday", value: "yesterday" },
                      { label: "This week", value: "week" }, { label: "All", value: "all" }]
            value: root.range
            onPicked: v => root.range = v
        }

        Rectangle {
            id: clearButton
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            property bool confirming: false
            width: clearText.implicitWidth + 24
            height: 32
            radius: Theme.radiusRow
            color: clearArea.containsMouse ? Theme.hover : Theme.clear
            border.width: 1
            border.color: confirming ? Theme.warn : Theme.border
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            // Clearing cannot be undone: ask once more.
            function press() {
                if (!confirming) { confirming = true; forget.restart(); return }
                confirming = false
                Notifs.clearArchive()
            }
            Timer { id: forget; interval: 3000; onTriggered: clearButton.confirming = false }
            activeFocusOnTab: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { clearButton.press(); event.accepted = true }
            }
            onActiveFocusChanged: if (!activeFocus) confirming = false
            StyledText { id: clearText; anchors.centerIn: parent; text: clearButton.confirming ? "Sure?" : "Clear history"; color: clearButton.confirming ? Theme.warn : Theme.text }
            MouseArea { id: clearArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clearButton.press() }
            FocusRing { visible: clearButton.activeFocus; anchors.margins: -3 }
        }

        Rectangle {
            anchors { left: ranges.right; leftMargin: 12; right: clearButton.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            height: 32
            radius: Theme.radiusRow
            color: Theme.hover
            border.width: 1
            border.color: search.activeFocus ? Theme.accent : Theme.clear

            TextInput {
                id: search
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.bright
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBase
                clip: true
                activeFocusOnTab: true
                onTextChanged: root.query = text
                Keys.onEscapePressed: event => { if (text !== "") { text = ""; event.accepted = true } else event.accepted = false }
                StyledText {
                    visible: search.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search"
                    color: Theme.dim
                }
            }
        }
    }

    StyledText {
        visible: root.shown.length === 0
        width: parent.width
        topPadding: 12
        leftPadding: 4
        text: Notifs.archive.length === 0 ? "No notifications in the last " + Notifs.archiveDays + " days."
            : root.query !== "" ? "Nothing matches “" + root.query + "”."
            : "Nothing " + (root.range === "today" ? "today" : root.range === "yesterday" ? "yesterday" : "this week") + "."
        color: Theme.dim
    }

    // ---- the list ----
    Repeater {
        model: root.shown

        Item {
            id: row
            required property var modelData
            readonly property bool isHeading: modelData.heading !== undefined
            readonly property var e: modelData.entry ?? null

            width: root.width
            height: isHeading ? heading.implicitHeight : body.implicitHeight + 16

            GroupLabel {
                id: heading
                visible: row.isHeading
                text: row.isHeading ? row.modelData.heading : ""
            }

            Column {
                id: body
                visible: !row.isHeading
                x: 4
                y: 8
                width: parent.width - 8
                spacing: 2

                Row {
                    spacing: 10
                    StyledText { text: row.e ? Qt.formatTime(new Date(row.e.time), "HH:mm") : ""; color: Theme.dim; font.pixelSize: Theme.fontSmall }
                    StyledText { text: row.e ? row.e.app : ""; color: row.e?.urgency === 2 ? Theme.err : Theme.dim; font.pixelSize: Theme.fontSmall }
                }
                StyledText { width: parent.width; text: row.e ? row.e.summary : ""; color: Theme.bright; elide: Text.ElideRight }
                StyledText {
                    width: parent.width
                    visible: text !== ""
                    text: row.e ? row.e.body : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.dim
                }
            }
            Rectangle {
                visible: !row.isHeading
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: Theme.border
            }
        }
    }
}
