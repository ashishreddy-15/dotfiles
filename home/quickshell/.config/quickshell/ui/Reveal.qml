import QtQuick
import qs

// Shows or hides one item by opening and closing a gap for it, so whatever sits beside it glides aside instead of
// jumping in one frame. Use it in place of `visible:` on an item in a Row:
//
//   Reveal { shown: net.attention; gapAfter: 16; Network { id: net } }
//
// Showing: the width opens (SmoothMotion) while the item fades in (durBase). Hiding: the item fades out first
// (durFast), then the width closes, so the content never squeezes while it can still be seen.
// The spacing to the neighbour goes inside the animated width (gapBefore / gapAfter), with the Row's own spacing at
// 0: a zero-width item that is still visible would otherwise keep the Row's spacing on both sides.
// Reduce motion: the width jumps, the fade stays.
Item {
    id: root

    property bool shown: true
    property real gapBefore: 0
    property real gapAfter: 0
    default property alias content: holder.data

    readonly property Item child: holder.children.length > 0 ? holder.children[0] : null

    // The width follows `open`, which lags behind `shown` on the way out (see collapse below).
    property bool open: false
    readonly property real fullWidth: child ? gapBefore + child.width + gapAfter : 0
    readonly property real target: open ? fullWidth : 0

    // No glide for what is already there when the bar loads (or reloads): only later changes animate.
    property bool ready: false
    Component.onCompleted: { child?.forceLayout?.(); open = shown; arm.start() }   // a Row child: size it now
    // Wait for children whose width settles a little later (a row of tray icons) before gliding anything.
    Timer { id: arm; interval: Theme.durBase; onTriggered: root.ready = true }

    onShownChanged: {
        if (shown) { collapse.stop(); open = true }
        else collapse.restart()
    }
    Timer { id: collapse; interval: Theme.durFast; onTriggered: root.open = false }

    implicitWidth: target
    implicitHeight: child ? child.height : 0
    SmoothMotion on implicitWidth { active: root.ready }

    // Stay in the Row until the exit has finished; then leave it, so it takes no spacing.
    visible: shown || implicitWidth > 0
    // Clip only while the width is moving: at rest the item's hover and click areas may reach past its edges.
    clip: implicitWidth !== fullWidth

    Item {
        id: holder
        // Keep the gap visible from the first frame: with the gap after the item, pin the item to the right of the
        // opening width (it slides in from the clipped left edge); with a gap before it, pin it to the left.
        // At rest both give the same place.
        x: root.gapAfter > 0 && root.gapBefore === 0 ? root.width - root.gapAfter - width : root.gapBefore
        width: root.child ? root.child.width : 0
        height: root.height
        enabled: root.shown                  // a leaving item takes no clicks (a quick double-click would undo itself)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.shown ? Theme.durBase : Theme.durFast; easing.type: Theme.easeOut } }
    }
}
