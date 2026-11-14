import QtQuick
import qs

// A row of choices where exactly one is on (a segmented control).
//   Segmented { options: [{ label: "dark", value: "prefer-dark" }, ...]; value: current; onPicked: v => ... }
// Plain strings work too: options: ["Adwaita", "AdwaitaLegacy"].
Rectangle {
    id: root

    property var options: []
    property var value
    signal picked(var value)

    implicitWidth: row.implicitWidth + 2 * Theme.segmentInset
    implicitHeight: 32
    radius: Theme.radiusRow
    color: Theme.clear
    border.width: 1
    border.color: Theme.border

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options

            Rectangle {
                id: seg
                required property var modelData
                readonly property string label: typeof modelData === "string" ? modelData : modelData.label
                readonly property var val: typeof modelData === "string" ? modelData : modelData.value
                readonly property bool on: root.value === val

                width: text.implicitWidth + 24
                height: root.implicitHeight - 2 * Theme.segmentInset
                radius: Theme.radiusSmall
                color: on ? (area.containsMouse ? Theme.selectedHover : Theme.selected) : (area.containsMouse ? Theme.hover : Theme.clear)
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                StyledText {
                    id: text
                    anchors.centerIn: parent
                    text: seg.label
                    color: seg.on ? Theme.bright : Theme.text
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.val)
                }
            }
        }
    }
}
