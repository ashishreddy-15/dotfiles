import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import "../ui"

// One notification pop-up. The fields arrive from the list model (see Notifs.record).
//   click the card   hides the pop-up (it stays in the history)       ×   the same
//   action link      runs the action and dismisses the notification
//   timeout          a thin bar runs down; hovering pauses it. Critical ones stay until clicked.
Item {
    id: root

    required property int nid
    required property string appName
    required property string summary
    required property string body
    required property string image
    required property int urgency
    required property string actionsJson

    readonly property bool critical: urgency === 2
    readonly property var actions: JSON.parse(actionsJson)
    property real remaining: 1                       // the timeout bar: 1 = full, 0 = time is up

    width: ListView.view.width
    height: card.height

    HoverHandler { id: hover }

    NumberAnimation {
        target: root
        property: "remaining"
        from: 1
        to: 0
        duration: root.urgency === 0 ? 3500 : 5000
        running: !root.critical
        paused: hover.hovered
        onFinished: Notifs.hidePopup(root.nid)
    }

    Card {
        id: card
        width: parent.width
        open: true                                   // the list animates it in; see Notifications.qml
        contentHeight: content.implicitHeight + 2 * Theme.padContent

        // Clicking anywhere on the card hides the pop-up. The items above take their own clicks first.
        MouseArea {
            anchors.fill: parent
            onClicked: Notifs.hidePopup(root.nid)
        }

        RowLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.padContent }
            spacing: 12

            // Picture sent with the notification (album art, contact photo...), if any
            ClippingRectangle {
                visible: root.image !== ""
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                radius: Theme.radiusRow
                color: "transparent"
                Image { anchors.fill: parent; source: root.image; fillMode: Image.PreserveAspectCrop }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: root.appName || "Notification"
                        color: root.critical ? Theme.err : Theme.dim
                        font.pixelSize: Theme.fontSmall
                        elide: Text.ElideRight
                    }
                    // Close: hides the pop-up (same as clicking the card, but obvious)
                    StyledText {
                        text: Theme.glyphClose
                        color: closeArea.containsMouse ? Theme.bright : Theme.dim
                        font.pixelSize: Theme.fontLarge
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        MouseArea {
                            id: closeArea
                            anchors { fill: parent; margins: -6 }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.hidePopup(root.nid)
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.summary
                    font.weight: Font.DemiBold
                    color: Theme.bright
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                }

                // Action links, e.g. "Reply", "Open"
                Row {
                    visible: root.actions.length > 0
                    spacing: 14
                    topPadding: 4

                    Repeater {
                        model: root.actions
                        StyledText {
                            required property var modelData
                            text: modelData.text
                            color: actHover.hovered ? Theme.bright : Theme.accent
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                            HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Notifs.invoke(root.nid, modelData.id) }
                        }
                    }
                }
            }
        }

        // The timeout bar along the bottom edge, inside the rounded corners.
        Rectangle {
            visible: !root.critical
            anchors { left: parent.left; bottom: parent.bottom; leftMargin: Theme.radiusCard; bottomMargin: 2 }
            width: (parent.width - 2 * Theme.radiusCard) * root.remaining
            height: 2
            radius: Theme.radiusMark
            color: Theme.accent
            opacity: 0.45
        }
    }
}
