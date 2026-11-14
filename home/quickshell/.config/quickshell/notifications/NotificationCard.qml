import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

Rectangle {
    id: card

    required property var modelData
    readonly property var n: modelData
    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    property int timeout: 5000
    property bool shown: true

    visible: shown
    implicitHeight: shown ? content.implicitHeight + 2 * Theme.padContent : 0
    height: implicitHeight
    radius: Theme.radiusCard
    color: Theme.surface
    border.width: 1
    border.color: critical ? Theme.err : Theme.border

    // Auto-dismiss (not for critical), paused while the mouse is over the card.
    Timer {
        running: card.shown && !card.critical && !hover.hovered
        interval: card.timeout
        onTriggered: card.n?.expire()
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: card.n?.dismiss() }

    RowLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.padContent }
        spacing: 12

        // Picture sent with the notification (album art, contact photo...), if any
        ClippingRectangle {
            visible: card.n?.image !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            radius: Theme.radiusRow
            color: "transparent"
            Image { anchors.fill: parent; source: card.n?.image; fillMode: Image.PreserveAspectCrop }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            StyledText {
                text: card.n?.appName || "Notification"
                color: card.critical ? Theme.err : Theme.dim
                font.pixelSize: Theme.fontSmall
            }
            StyledText {
                Layout.fillWidth: true
                text: card.n?.summary
                font.weight: Font.DemiBold
                color: Theme.bright
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.n?.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // Action buttons, e.g. "Reply", "Open"
            Row {
                visible: card.n?.actions.length > 0
                spacing: 14
                topPadding: 4

                Repeater {
                    model: card.n?.actions
                    StyledText {
                        required property var modelData
                        text: modelData.text
                        color: actHover.hovered ? Theme.bright : Theme.accent
                        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: modelData.invoke() }
                    }
                }
            }
        }
    }
}
