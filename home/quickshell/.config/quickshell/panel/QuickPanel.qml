import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

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

        // Where the card sits: just under the bar, a little in from the right edge. The window itself is
        // larger (room for the shadow) and never changes size; the card is placed inside it.
        readonly property int wantedTop: Theme.barHeight + 4
        readonly property int wantedRight: 8
        anchors { top: true; right: true }
        margins.top: Math.max(0, wantedTop - Theme.shadowMargin)
        margins.right: Math.max(0, wantedRight - Theme.shadowMargin)
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: root.panelWidth + 2 * Theme.shadowMargin
        implicitHeight: wantedTop + root.maxHeight + Theme.shadowMargin
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

        Card {
            id: card
            x: win.width - root.panelWidth - (win.wantedRight - win.margins.right)
            y: win.wantedTop - win.margins.top
            width: root.panelWidth
            open: ShellState.panelOpen
            origin: Item.TopRight
            contentHeight: content.implicitHeight + 2 * Theme.cardInset
            maxHeight: root.maxHeight

            focus: true
            Keys.onEscapePressed: ShellState.panelOpen = false

            Flickable {
                anchors { fill: parent; margins: Theme.cardInset }
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
