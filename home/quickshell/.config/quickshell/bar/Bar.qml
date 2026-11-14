import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// One bar per monitor. Created and removed automatically as monitors are plugged in.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        screen: modelData

        // Full bar on the main monitor, or on every monitor if the main one is absent.
        readonly property bool mainPresent: Quickshell.screens.some(s => s.name === Theme.mainOutput)
        readonly property bool full: modelData.name === Theme.mainOutput || !mainPresent

        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        color: Theme.surface

        // Left: workspaces
        Workspaces {
            screen: bar.modelData
            anchors { left: parent.left; leftMargin: Theme.pad; verticalCenter: parent.verticalCenter }
        }

        // Centre: clock (truly centred, whatever is on the sides)
        Clock {
            anchors.centerIn: parent
        }

        // Right: tray + status, text only (main bar only)
        RowLayout {
            visible: bar.full
            spacing: 18
            anchors { right: parent.right; rightMargin: Theme.pad + 4; verticalCenter: parent.verticalCenter }

            Tray { window: bar }
            Network {}
            BluetoothStatus {}
            Volume {}
            Battery {}
        }

        // Hairline under the bar
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.border
        }
    }
}
