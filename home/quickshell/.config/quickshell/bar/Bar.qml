import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Mac-style menu bar, one per monitor: thin, edge to edge, translucent
// (Hyprland blurs what's behind it, see hypr/modules/rules.lua).
//
//   [1] 2  3   App name                              (status when it matters)   Sat 14 Nov  12:40
//
// "Quiet" rule: the right side only shows things that need attention.
// Super+B hides/shows the bar.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        screen: modelData

        // Status goes on the main monitor, or on every monitor if the main one is absent.
        readonly property bool mainPresent: Quickshell.screens.some(s => s.name === Theme.mainOutput)
        readonly property bool full: modelData.name === Theme.mainOutput || !mainPresent

        visible: ShellState.barVisible
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        color: Qt.alpha(Theme.bg, Theme.barOpacity)
        WlrLayershell.namespace: "quickshell-bar"

        // Left: workspaces, then the focused app
        Row {
            spacing: 14
            anchors { left: parent.left; leftMargin: Theme.pad; verticalCenter: parent.verticalCenter }

            Workspaces { screen: bar.modelData }
            AppName { screen: bar.modelData }
        }

        // Right: tray and attention-only status (main bar), then the clock
        Row {
            spacing: 16
            anchors { right: parent.right; rightMargin: Theme.pad + 4; verticalCenter: parent.verticalCenter }

            Tray { window: bar; visible: bar.full && hasItems; anchors.verticalCenter: parent.verticalCenter }
            Network { visible: bar.full && attention }
            BluetoothStatus { visible: bar.full && attention }
            Volume { visible: bar.full && attention }
            Battery { visible: bar.full && attention }
            Clock {}
        }
    }
}
