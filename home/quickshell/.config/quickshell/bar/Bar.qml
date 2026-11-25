import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Menu bar, one per monitor: thin, edge to edge, with no background by default,
// so the text looks like part of the wallpaper (Theme.barOpacity). The text colours follow the wallpaper:
// light text on dark ones, dark text on light ones (Theme.barText and friends).
//
//   [1] 2  3   App name                              (status when it matters)   Sat 14  12:40   bell
//
// "Quiet" rule: the right side only shows things that need attention (the battery icon is always there).
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

        // Super+B slides and fades the bar inside the window (ShellState.barShown). The window stays mapped until
        // that has finished, and gives its screen space back at once so windows resize alongside the slide.
        visible: ShellState.barVisible || ShellState.barShown > 0
        exclusiveZone: ShellState.barVisible ? Theme.barHeight : 0
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        color: Qt.alpha(Theme.bg, Theme.barOpacity)
        WlrLayershell.namespace: "quickshell-bar"

        // Keep awake: while on, the compositor does not report "idle", so hypridle does not dim, lock or sleep.
        // (An inhibitor needs a visible window; the bar is always there.)
        IdleInhibitor { window: bar; enabled: Modes.keepAwake }

        Item {
            id: content
            anchors.fill: parent
            opacity: ShellState.barShown
            transform: Translate { y: Theme.reduceMotion ? 0 : (ShellState.barSlide - 1) * Theme.barHeight / 2 }   // reduce motion: fade only

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

                Recording { anchors.verticalCenter: parent.verticalCenter }
                ModeIcons { anchors.verticalCenter: parent.verticalCenter }
                Tray { window: bar; visible: bar.full && hasItems; anchors.verticalCenter: parent.verticalCenter }

                // Status items and the clock: click anywhere here to open the quick-settings panel.
                Item {
                    implicitWidth: statusArea.implicitWidth
                    implicitHeight: statusArea.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: statusArea
                        spacing: 16

                        Network { visible: bar.full && attention }
                        BluetoothStatus { visible: bar.full && attention }
                        Volume { visible: bar.full && attention }
                        Battery { visible: bar.full && present }
                        Clock {}
                    }

                    // Hover / pressed wash behind the status items and clock, in the bar's own text colour so it
                    // reads on both dark and light wallpapers.
                    Rectangle {
                        anchors { fill: parent; leftMargin: -8; rightMargin: -8; topMargin: -4; bottomMargin: -4 }
                        radius: Theme.radiusRow
                        color: Qt.alpha(Theme.barText, area.pressed ? 0.22 : area.containsMouse ? 0.12 : 0)
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }

                    MouseArea {
                        id: area
                        hoverEnabled: true
                        anchors { fill: parent; margins: -6 }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.togglePanel(bar.modelData.name)
                    }
                }

                // The notification centre, at the right end.
                NotificationBell { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
