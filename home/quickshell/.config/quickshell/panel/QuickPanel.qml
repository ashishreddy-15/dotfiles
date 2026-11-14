import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// Control center: a first page (status, tiles, display, sound, power) and detail pages (Wi-Fi, Bluetooth,
// sound output, power profile, battery). See MainPage.qml for how controls are arranged.
// Opens under the right end of the bar when you click the clock (or press Super+A).
// Esc, or a click anywhere else, closes it.
//
// Like the pickers, the window has a fixed size and only the card inside it grows and shrinks,
// and Hyprland's own fade is switched off for it (hypr/modules/rules.lua).
Scope {
    id: root

    readonly property int panelWidth: 340
    readonly property int maxHeight: 780        // the first page is about 650 px; longer pages scroll

    IpcHandler {
        target: "panel"
        function toggle(): void { ShellState.togglePanel(Hyprland.focusedMonitor?.name ?? "") }
        function close(): void { ShellState.panelOpen = false }
        // Open on a page: wifi, bt, output, profile, night, notifications, or none for the first page (used for testing).
        function open(page: string): void {
            ShellState.panelScreen = Hyprland.focusedMonitor?.name ?? ""
            ShellState.panelOpen = true
            stage.go(["wifi", "bt", "output", "profile", "night", "notifications", "battery"].includes(page) ? page : "main")
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
            contentHeight: stage.implicitHeight + 2 * Theme.cardInset
            maxHeight: root.maxHeight

            focus: true
            // Keyboard: Esc goes back one page (on the first page it closes the panel), Backspace goes back too,
            // Up / Down (and Tab) move between controls; each control handles Enter, Space and Left / Right itself.
            Keys.onEscapePressed: stage.detail ? stage.go("main") : ShellState.panelOpen = false
            Keys.onUpPressed: root.moveFocus(false)
            Keys.onDownPressed: root.moveFocus(true)
            Keys.onPressed: event => { if (event.key === Qt.Key_Backspace && stage.detail) { stage.go("main"); event.accepted = true } }

            // Start from the first page again once the panel is out of sight.
            onShownChanged: if (shown === 0) stage.reset()

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

                    property var returnItem: null          // the control that had focus before a page opened

                    function go(name) {
                        if (name !== "main") {
                            if (page === "main") returnItem = card.Window.activeFocusItem
                            detailPage = name
                        }
                        page = name
                        // Going back gives the focus to the control you came from; opening a page starts at its top
                        // (the next Down picks its first control).
                        const back = name === "main" ? returnItem : null
                        if (back) Qt.callLater(() => back.forceActiveFocus())
                        else card.forceActiveFocus()
                    }
                    function reset() { returnItem = null; go("main") }

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
                                       : stage.detailPage === "profile" ? profilePage
                                       : stage.detailPage === "battery" ? batteryPage
                                       : stage.detailPage === "night" ? nightPage
                                       : stage.detailPage === "notifications" ? notificationsPage : null
                    }

                    Component { id: wifiPage;    WifiPage      { onBack: stage.go("main") } }
                    Component { id: btPage;      BluetoothPage { onBack: stage.go("main") } }
                    Component { id: outputPage;  OutputPage    { onBack: stage.go("main") } }
                    Component { id: batteryPage; BatteryPage   { onBack: stage.go("main"); onOpen: page => stage.go(page) } }
                    Component { id: profilePage; ProfilePage   { onBack: stage.go("main") } }
                    Component { id: nightPage;   NightPage     { onBack: stage.go("main") } }
                    Component { id: notificationsPage; NotificationsPage { onBack: stage.go("main") } }
                }
            }
        }
    }
}
