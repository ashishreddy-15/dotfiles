import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Notification pop-ups: a stack of cards under the bar, top-centre of the main screen, newest on top.
// The data (and the D-Bus server) live in Notifs.qml. This file is only the window and the stack.
//
// Like the other floating pieces, the window has a fixed size with room for the cards' shadows; the cards
// move inside it. New cards fade and zoom in, leaving ones fade out, and the rest slide to re-stack.
Scope {
    id: root

    readonly property int cardWidth: 400
    readonly property int gap: 8
    readonly property int cardMaxHeight: 150
    // Room for the most cards we ever show, each as tall as allowed.
    readonly property int stackMax: Notifs.maxPopups * cardMaxHeight + (Notifs.maxPopups - 1) * gap

    // Stay mapped a moment after the last card is gone, so its exit animation can finish.
    Timer { id: linger; interval: 350 }
    Connections {
        target: Notifs.popups
        function onCountChanged() { linger.restart() }
    }

    LazyLoader {
        id: loader
        active: Notifs.popups.count > 0 || linger.running

        PanelWindow {
            id: win

            screen: ShellState.mainScreen
            visible: Notifs.popups.count > 0 || linger.running

            readonly property int wantedTop: Theme.barHeight + 4
            anchors.top: true                                    // top only = horizontally centred
            margins.top: Math.max(0, wantedTop - Theme.shadowMargin)
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: root.cardWidth + 2 * Theme.shadowMargin
            implicitHeight: wantedTop + root.stackMax + Theme.shadowMargin
            color: "transparent"
            mask: Region { item: list }                          // only the cards take clicks
            WlrLayershell.namespace: "quickshell-notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            ListView {
                id: list
                x: Theme.shadowMargin
                y: win.wantedTop - win.margins.top
                width: root.cardWidth
                height: Math.min(contentHeight, root.stackMax)
                interactive: false
                spacing: root.gap
                model: Notifs.popups
                delegate: NotificationCard {}

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
                        NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: Theme.durFast; easing.type: Theme.easeOut }
                        NumberAnimation { property: "scale"; to: 0.97; duration: Theme.durFast; easing.type: Theme.easeOut }
                    }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: Theme.durBase; easing.type: Theme.easeOut }
                }
            }
        }
    }
}
