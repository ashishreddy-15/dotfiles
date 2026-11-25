import QtQuick
import qs

// One press state for anything you click: a hover wash behind it, a press-in scale (Theme.pressScale) on what is
// inside it, and the pointing-hand cursor. A MouseArea, so `onClicked`, `pressed`, `containsMouse` and `enabled`
// work as usual; keyboard handling (activeFocusOnTab, Keys) is left to the caller, as before.
//   Pressable { width: 34; height: 34; radius: height / 2; onClicked: ...; StyledText { anchors.centerIn: parent } }
// The children go in a content item that fills it and scales; the wash (and its `border`) stays put, so a
// button's outline does not shrink. `selected` washes it in Theme.selected (Theme.selectedHover under the pointer).
MouseArea {
    id: root

    property bool selected: false
    property real pressedScale: Theme.pressScale   // Theme.pressScaleRow for full-width rows
    property alias radius: wash.radius
    property alias border: wash.border
    default property alias content: body.data

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        id: wash
        anchors.fill: parent
        radius: Theme.radiusRow
        readonly property bool hovered: root.containsMouse && root.enabled
        color: root.selected ? (hovered ? Theme.selectedHover : Theme.selected) : (hovered ? Theme.hover : Theme.clear)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Item {
        id: body
        anchors.fill: parent
        scale: root.pressed ? root.pressedScale : 1
        PressMotion on scale {}
    }
}
