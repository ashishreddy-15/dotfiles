import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs

// Notification daemon + pop-ups. Pop-ups drop down from the top-centre of the main monitor.
// Normal: fade after 5 s (paused while hovered). Critical: stay until clicked.
// Click a pop-up to dismiss it; click an action to run it.
Scope {
    id: root

    readonly property int normalTimeout: 5000
    readonly property int maxVisible: 4

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => { n.tracked = true }
    }

    PanelWindow {
        screen: ShellState.mainScreen
        visible: server.trackedNotifications.values.length > 0

        anchors.top: true                       // top only = horizontally centred
        margins.top: Theme.barHeight + 6
        exclusionMode: ExclusionMode.Ignore     // don't push windows down
        implicitWidth: 400
        implicitHeight: column.implicitHeight
        color: "transparent"
        WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        // A ListView keeps existing cards (and their timers) when another card closes.
        // Bottom-to-top puts the newest notification at the top.
        ListView {
            id: column
            width: parent.width
            implicitHeight: contentHeight
            height: contentHeight
            interactive: false
            spacing: 8
            verticalLayoutDirection: ListView.BottomToTop
            model: server.trackedNotifications

            delegate: NotificationCard {
                required property int index
                width: column.width
                timeout: root.normalTimeout
                // Only the newest few are shown; older ones wait until these close.
                shown: index >= column.count - root.maxVisible
            }
        }
    }
}
