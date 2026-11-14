import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// App tray icons (nm-applet, chat apps...). Left click: open. Right click: menu.
Row {
    id: root

    required property var window   // the bar window, needed to place menus

    spacing: 8
    readonly property bool hasItems: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: entry

            required property var modelData

            width: 16
            height: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: event => {
                if (event.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) {
                        const pos = entry.mapToItem(null, 0, entry.height + 8)
                        modelData.display(root.window, pos.x, pos.y)
                    }
                } else if (event.button === Qt.MiddleButton) {
                    modelData.secondaryActivate()
                } else {
                    modelData.activate()
                }
            }

            IconImage {
                anchors.fill: parent
                source: entry.modelData.icon
                opacity: entry.pressed ? 0.6 : entry.containsMouse ? 1 : 0.8   // quiet at rest, full under the pointer
                scale: entry.pressed ? 0.9 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
            }
        }
    }
}
