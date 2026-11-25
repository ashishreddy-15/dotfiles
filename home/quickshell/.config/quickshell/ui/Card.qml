import QtQuick
import QtQuick.Effects
import qs

// The one card every floating piece (panel, pickers, indicator) is built from, so they look and move alike:
//   - a frosted, slightly see-through surface with a hairline border and rounded corners
//   - a soft shadow underneath
//   - the shared enter/exit animation (fade, slight zoom, short slide) and a smooth height change
//
// Use it inside a fixed-size window that leaves Theme.shadowMargin free on every side, put the card at
// (shadowMargin, shadowMargin), set `width`, bind `contentHeight` to the content's natural height, and put
// the content inside. The window must stay mapped until `shown` is back to 0.
Item {
    id: root

    property bool open: false
    property real contentHeight: 0           // natural height of the content; the card animates to it
    property real maxHeight: 100000
    property int origin: Item.Top            // which edge the zoom grows from
    property alias radius: surface.radius
    default property alias content: surface.data

    // 0 = hidden, 1 = fully shown
    property real shown: open ? 1 : 0
    Behavior on shown { NumberAnimation { duration: root.open ? Theme.durBase : Theme.durFast; easing.type: Theme.easeOut } }

    // Physical spring progress for scale and slide so retargeting mid-flight keeps momentum.
    property real spatial: open ? 1 : 0
    Behavior on spatial { SpringAnimation { spring: root.open ? Theme.springSmooth : Theme.springSnappy; damping: root.open ? Theme.dampingSmooth : Theme.dampingExit; epsilon: Theme.epsNorm } }

    height: Math.min(contentHeight, maxHeight)
    Behavior on height { SpringAnimation { spring: Theme.springSmooth; damping: Theme.dampingSmooth; epsilon: Theme.epsPx } }

    opacity: shown
    scale: 0.95 + 0.05 * spatial
    transformOrigin: root.origin
    transform: Translate { y: (1 - root.spatial) * (root.origin === Item.Bottom ? 8 : -8) }

    RectangularShadow {
        anchors.fill: parent
        radius: surface.radius
        blur: Theme.shadowBlur
        offset: Qt.vector2d(0, Theme.shadowOffset)
        color: Theme.shadow
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusCard
        color: Theme.card
        border.width: 1
        border.color: Theme.border
        clip: true                           // rows are revealed as the card grows
    }
}
