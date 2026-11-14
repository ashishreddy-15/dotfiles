import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// Control center: a first page (status, tiles, display, sound, power) and detail pages (Wi-Fi, Bluetooth,
// sound output, power profile). See MainPage.qml for how controls are arranged.
// Opens under the right end of the bar when you click the clock (or press Super+A).
// Esc, or a click anywhere else, closes it.
//
// Like the pickers, the window has a fixed size and only the card inside it grows and shrinks,
// and Hyprland's own fade is switched off for it (hypr/modules/rules.lua).
Scope {
    id: root

    readonly property int panelWidth: 340
    readonly property int maxHeight: 560

    IpcHandler {
        target: "panel"
        function toggle(): void { ShellState.togglePanel(Hyprland.focusedMonitor?.name ?? "") }
        function close(): void { ShellState.panelOpen = false }
        // Open on a page: wifi, bt, output, profile, or none for the first page (used for testing).
        function open(page: string): void {
            ShellState.panelScreen = Hyprland.focusedMonitor?.name ?? ""
            ShellState.panelOpen = true
            stage.go(["wifi", "bt", "output", "profile"].includes(page) ? page : "main")
        }
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
            contentHeight: stage.implicitHeight + 2 * Theme.cardInset
            maxHeight: root.maxHeight

            focus: true
            // Esc goes back one page; on the first page it closes the panel.
            Keys.onEscapePressed: stage.detail ? stage.go("main") : ShellState.panelOpen = false

            // Start from the first page again once the panel is out of sight.
            onShownChanged: if (shown === 0) stage.go("main")

            Flickable {
                anchors { fill: parent; margins: Theme.cardInset }
                contentWidth: width
                contentHeight: stage.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                // Two layers: the first page and the detail page. Switching slides them a short way and
                // cross-fades; the card animates to the new page's height.
                Item {
                    id: stage
                    width: parent.width
                    implicitHeight: detail ? detailLoader.implicitHeight : mainPage.implicitHeight
                    clip: true

                    property string page: "main"
                    property string detailPage: ""             // kept while the page slides out
                    readonly property bool detail: page !== "main"
                    property real t: detail ? 1 : 0            // 0 = first page, 1 = detail page
                    Behavior on t { NumberAnimation { duration: Theme.durBase; easing.type: Theme.easeOut } }
                    onTChanged: if (t === 0) detailPage = ""

                    function go(name) {
                        if (name !== "main") detailPage = name
                        page = name
                    }

                    MainPage {
                        id: mainPage
                        width: parent.width
                        x: -stage.t * 24
                        opacity: 1 - stage.t
                        visible: stage.t < 1
                        onOpen: page => stage.go(page)
                        onDone: ShellState.panelOpen = false
                    }

                    Loader {
                        id: detailLoader
                        width: parent.width
                        x: (1 - stage.t) * 24
                        opacity: stage.t
                        visible: stage.t > 0
                        sourceComponent: stage.detailPage === "wifi" ? wifiPage
                                       : stage.detailPage === "bt" ? btPage
                                       : stage.detailPage === "output" ? outputPage
                                       : stage.detailPage === "profile" ? profilePage : null
                    }

                    Component { id: wifiPage;    WifiPage      { onBack: stage.go("main") } }
                    Component { id: btPage;      BluetoothPage { onBack: stage.go("main") } }
                    Component { id: outputPage;  OutputPage    { onBack: stage.go("main") } }
                    Component { id: profilePage; ProfilePage   { onBack: stage.go("main") } }
                }
            }
        }
    }
}
