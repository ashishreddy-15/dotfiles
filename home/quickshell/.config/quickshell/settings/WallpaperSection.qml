import QtQuick
import Quickshell
import qs

// Wallpaper: every image found (generated ones, downloaded photos, and anything you put in ~/Pictures/Wallpapers),
// as thumbnails. Click one to use it. The list and the choice live in wallpaper/Wallpaper.qml (through ShellState).
Page {
    id: root

    readonly property int columns: 3
    readonly property int gap: 12
    readonly property real cellWidth: (width - (columns - 1) * gap) / columns
    function baseName(path) { return path.split("/").pop().replace(/\.[^.]+$/, "") }

    Grid {
        columns: root.columns
        spacing: root.gap
        width: root.width

        Repeater {
            model: ShellState.wallpaperFiles

            Item {
                id: cell
                required property string modelData
                readonly property bool on: ShellState.wallpaperCurrent === modelData

                width: root.cellWidth
                height: Math.round(root.cellWidth * 0.62) + 26

                Rectangle {
                    id: thumb
                    width: parent.width
                    height: Math.round(root.cellWidth * 0.62)
                    radius: Theme.radiusRow
                    color: Theme.hover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + cell.modelData
                        sourceSize.width: Math.round(root.cellWidth * 2)       // decode small, these are large photos
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.durBase } }
                    }
                    // Selected: an accent outline over the image; hover: a light wash.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: area.containsMouse && !cell.on ? Theme.hover : Theme.clear
                        border.width: cell.on ? 2 : 0
                        border.color: Theme.accent
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                }
                StyledText {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    text: root.baseName(cell.modelData)
                    color: cell.on ? Theme.bright : Theme.dim
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.wallpaperChosen(cell.modelData)
                }
            }
        }
    }
}
