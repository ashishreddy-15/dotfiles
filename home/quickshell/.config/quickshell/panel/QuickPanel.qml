import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// Control center: the quick things only (tiles, sliders, media, power buttons); see MainPage.qml.
// Everything else is in Settings (Super + I, or the gear in the header).
// Opens under the right end of the bar when you click the clock (or press Super+A).
// Esc, or a click anywhere else, closes it.
//
// Like the pickers, the window has a fixed size and only the card inside it grows and shrinks,
// and Hyprland's own fade is switched off for it (hypr/modules/rules.lua).
Scope {
    id: root

    readonly property int panelWidth: 340
    readonly property int maxHeight: 700        // the page is about 600 px; a smaller screen scrolls

    IpcHandler {
        target: "panel"
        function toggle(): void { ShellState.togglePanel(Hyprland.focusedMonitor?.name ?? "") }
        function close(): void { ShellState.panelOpen = false }
        function open(): void {
            ShellState.panelScreen = Hyprland.focusedMonitor?.name ?? ""
            ShellState.panelOpen = true
        }
    }

    // Move the keyboard focus to the next (or previous) control on the page.
    function moveFocus(forward) {
        const cur = card.Window.activeFocusItem ?? card
        const next = cur.nextItemInFocusChain(forward)
        if (next) next.forceActiveFocus()
    }

    Connections {
        target: ShellState
        function onPanelOpenChanged() { if (ShellState.panelOpen) Brightness.refresh() }    // show the real levels
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
        // Exclusive while open, like the pickers, so the keyboard works the moment it opens (Esc, arrows, Enter).
        WlrLayershell.keyboardFocus: ShellState.panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
            contentHeight: mainPage.implicitHeight + 2 * Theme.cardInset
            maxHeight: root.maxHeight

            focus: true
            // Keyboard: Esc closes; Up / Down (and Tab) move between controls; each control handles Enter, Space and
            // Left / Right itself.
            Keys.onEscapePressed: ShellState.panelOpen = false
            Keys.onUpPressed: root.moveFocus(false)
            Keys.onDownPressed: root.moveFocus(true)

            Flickable {
                anchors { fill: parent; margins: Theme.cardInset }
                contentWidth: width
                contentHeight: mainPage.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                MainPage {
                    id: mainPage
                    width: parent.width
                    onDone: ShellState.panelOpen = false
                }
            }
        }
    }
}
