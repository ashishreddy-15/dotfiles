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
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: entry

            required property var modelData

            width: 16
            height: 16
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

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
                opacity: 0.8   // keep colourful app icons from shouting
            }
        }
    }
}
