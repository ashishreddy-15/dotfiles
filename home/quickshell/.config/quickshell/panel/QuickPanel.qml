import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

// Quick settings: volume + output, brightness, Wi-Fi, Bluetooth, wallpaper and the power actions.
// Opens under the right end of the bar when you click the clock (or press Super+A).
// Esc, or a click anywhere else, closes it.
//
// Like the pickers, the window has a fixed size and only the card inside it grows and shrinks,
// and Hyprland's own fade is switched off for it (hypr/modules/rules.lua).
Scope {
    id: root

    property string expanded: ""        // which list is open: "out", "wifi" or "bt"
    readonly property int panelWidth: 340
    readonly property int maxHeight: 560

    function toggle(name) { expanded = expanded === name ? "" : name }

    IpcHandler {
        target: "panel"
        function toggle(): void { ShellState.togglePanel(Hyprland.focusedMonitor?.name ?? "") }
        function close(): void { ShellState.panelOpen = false }
        // Open with a list already expanded: out, wifi or bt (used for testing).
        function open(section: string): void {
            ShellState.panelScreen = Hyprland.focusedMonitor?.name ?? ""
            ShellState.panelOpen = true
            root.expanded = section          // after opening: opening resets the lists
        }
    }

    Connections {
        target: ShellState
        function onPanelOpenChanged() {
            if (!ShellState.panelOpen) return
            root.expanded = ""
            Brightness.refresh()            // show the real levels, in case something else changed them
        }
    }

    PanelWindow {
        id: win

        screen: Quickshell.screens.find(s => s.name === ShellState.panelScreen) ?? ShellState.mainScreen

        // Stay mapped until the close animation has finished.
        visible: ShellState.panelOpen || card.shown > 0

        anchors { top: true; right: true }
        margins.top: Theme.barHeight + 4
        margins.right: 8
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: root.panelWidth
        implicitHeight: root.maxHeight
        color: "transparent"
        mask: Region { item: card }
        WlrLayershell.namespace: "quickshell-panel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: ShellState.panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            active: ShellState.panelOpen
            windows: [win]
            onCleared: ShellState.panelOpen = false
        }

        Rectangle {
            id: card

            property real shown: ShellState.panelOpen ? 1 : 0
            Behavior on shown { NumberAnimation { duration: ShellState.panelOpen ? 140 : 90; easing.type: Easing.OutCubic } }

            width: parent.width
            height: Math.min(content.implicitHeight + 2 * 8, root.maxHeight)
            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            opacity: shown
            scale: 0.97 + 0.03 * shown
            transformOrigin: Item.TopRight
            y: (1 - shown) * -8

            clip: true
            radius: Theme.radius + 4
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            focus: true
            Keys.onEscapePressed: ShellState.panelOpen = false

            Flickable {
                anchors { fill: parent; margins: 8 }
                contentWidth: width
                contentHeight: content.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: content
                    width: parent.width
                    spacing: 2

                    AudioSection {
                        width: parent.width
                        expanded: root.expanded === "out"
                        onToggleExpanded: root.toggle("out")
                    }
                    BrightnessSection { width: parent.width }
                    WifiSection {
                        width: parent.width
                        expanded: root.expanded === "wifi"
                        onToggleExpanded: root.toggle("wifi")
                    }
                    BluetoothSection {
                        width: parent.width
                        expanded: root.expanded === "bt"
                        onToggleExpanded: root.toggle("bt")
                    }
                    Line {
                        label: "wall"
                        value: ShellState.wallpaperName
                        toggleText: "change"
                        onClicked: { ShellState.panelOpen = false; ShellState.pickWallpaper() }
                        onToggled: { ShellState.panelOpen = false; ShellState.pickWallpaper() }
                    }

                    Item { width: parent.width; height: 9
                        Rectangle { anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 } height: 1; color: Theme.border }
                    }

                    PowerSection {
                        width: parent.width
                        onDone: ShellState.panelOpen = false
                    }
                }
            }
        }
    }
}
