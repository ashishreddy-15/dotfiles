import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "../ui"

// Settings: Wi-Fi, Bluetooth, sound, display, wallpaper, notifications, power and appearance, in a window of its own
// (an ordinary floating window, not a pop-up) laid out like a settings app: a sidebar of sections and the settings of the chosen one.
// It stays until you close it: with the x at its top right, Super + I, or the compositor's close (Super + Q). Clicking
// elsewhere or pressing Esc does not close it, so it can sit beside other windows and dialogs (the wallpaper folder dialog).
// (The control center keeps only quick toggles, sliders, media and the power buttons.)
//
//   Super + I              show / hide      (qs ipc call settings toggle)
//   Super + Shift + A      Appearance       (qs ipc call settings toggleSection appearance | open <section>)
//   the x button           close
// Keyboard: it opens with the focus on the sidebar: Up / Down change section, Right / Enter / Tab go into the section.
// Inside a section Tab (or Up / Down) moves between the controls, Enter and Space press, Left / Right adjust (
// choices, steppers, sliders). Left on a plain row, or Shift+Tab / Up from the first control, goes back to the sidebar.
// Sections: wifi, bluetooth, display, sound, power, touchpad, tablet, about, appearance, wallpaper, notifications. Each one is a file in this folder;
// it is loaded only while it is showing (so scanning for networks and devices stops when Settings is closed).
//
// Hyprland floats and centres it by class and title (hypr/modules/rules.lua).
Scope {
    id: root

    // The sidebar, in three groups: how you connect, the machine itself, and how it looks and talks to you.
    readonly property var sections: [
        { id: "wifi",          group: "Connections", label: "Wi-Fi",         glyph: Theme.glyphWifi,      file: "WifiSection.qml" },
        { id: "bluetooth",     group: "Connections", label: "Bluetooth",     glyph: Theme.glyphBluetooth, file: "BluetoothSection.qml" },
        { id: "display",       group: "Device",      label: "Display",       glyph: Theme.glyphBright,    file: "DisplaySection.qml" },
        { id: "sound",         group: "Device",      label: "Sound",         glyph: Theme.glyphVolume,    file: "SoundSection.qml" },
        { id: "power",         group: "Device",      label: "Power",         glyph: Theme.glyphBattery,   file: "BatterySection.qml" },
        { id: "touchpad",      group: "Device",      label: "Touchpad",      glyph: Theme.glyphTouchpad,  file: "TouchpadSection.qml" },
        { id: "tablet",        group: "Device",      label: "Tablet",        glyph: Theme.glyphPen,       file: "TabletSection.qml" },
        { id: "about",         group: "Device",      label: "About",         glyph: Theme.glyphInfo,      file: "AboutSection.qml" },
        { id: "appearance",    group: "Personal",    label: "Appearance",    glyph: Theme.glyphBrush,     file: "AppearanceSection.qml" },
        { id: "wallpaper",     group: "Personal",    label: "Wallpaper",     glyph: Theme.glyphImage,     file: "WallpaperSection.qml" },
        { id: "notifications", group: "Personal",    label: "Notifications", glyph: Theme.glyphBell,      file: "NotificationsSection.qml" }
    ]
    readonly property int index: Math.max(0, sections.findIndex(s => s.id === ShellState.settingsSection))

    readonly property int cardWidth: 900
    readonly property int cardHeight: 620
    readonly property int minWidth: 720
    readonly property int minHeight: 480
    readonly property int sidebarWidth: 210
    readonly property int pad: 28

    IpcHandler {
        target: "settings"
        function toggle(): void { ShellState.toggleSettings("") }
        function toggleSection(section: string): void { ShellState.toggleSettings(section) }
        function open(section: string): void { ShellState.openSettings(section) }
        function close(): void { ShellState.settingsOpen = false }
    }

    function go(i) { ShellState.settingsSection = sections[Math.max(0, Math.min(sections.length - 1, i))].id }

    LazyLoader {
        id: loader
        active: ShellState.settingsOpen

        FloatingWindow {
            id: win

            title: "Settings"
            visible: true
            // Closed by the compositor (Super + Q): keep the shared state in step.
            onVisibleChanged: if (!visible) ShellState.settingsOpen = false
            implicitWidth: root.cardWidth
            implicitHeight: root.cardHeight
            minimumSize: Qt.size(root.minWidth, root.minHeight)
            color: Theme.surface

            // ---- keyboard focus: the sidebar (the card itself has the focus) or a control inside the section ----
            Component.onCompleted: Qt.callLater(() => card.forceActiveFocus())
            Connections {
                target: ShellState
                function onSettingsSectionChanged() { card.forceActiveFocus() }
            }
            function inContent(item) {
                for (let p = item; p; p = p.parent) if (p === content) return true
                return false
            }
            // Into the section: the first control. Between controls: the next / previous one; before the first, the sidebar.
            function moveFocus(forward) {
                if (swap.running) swap.complete()     // land on the new page first, or the key press is lost
                const cur = card.Window.activeFocusItem
                const from = inContent(cur) ? cur : content
                const next = from.nextItemInFocusChain(forward)
                if (next && inContent(next) && next !== content) next.forceActiveFocus()
                else if (!forward) card.forceActiveFocus()
            }

            Item {
                id: card
                anchors.fill: parent
                readonly property real shown: win.visible ? 1 : 0

                // Keys the controls do not use come up to here (the controls handle Enter, Space and Left / Right themselves).
                focus: true
                Keys.onPressed: event => {
                    const inside = win.inContent(card.Window.activeFocusItem)
                    if (event.key === Qt.Key_Down) { if (inside) win.moveFocus(true); else root.go(root.index + 1) }
                    else if (event.key === Qt.Key_Up) { if (inside) win.moveFocus(false); else root.go(root.index - 1) }
                    else if (event.key === Qt.Key_Tab) win.moveFocus(true)
                    else if (event.key === Qt.Key_Backtab) win.moveFocus(false)
                    else if (!inside && (event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) win.moveFocus(true)
                    else if (inside && event.key === Qt.Key_Left) card.forceActiveFocus()
                    else return
                    event.accepted = true
                }

                Row {
                    anchors.fill: parent

                    // ---- sidebar ----
                    Item {
                        id: sidebar
                        width: root.sidebarWidth
                        height: parent.height

                        // The selection: one pill (the selected wash and the accent mark) that slides to the current entry.
                        // Its y is the current entry's, mapped into the sidebar. It does not slide in when Settings opens:
                        // the motion is armed only once the sidebar's layout has settled (no re-positioning for durFast;
                        // the nested group columns lay out over a few passes, so the first pass is too early).
                        property bool pillReady: false
                        Timer { id: pillArm; interval: Theme.durFast; onTriggered: sidebar.pillReady = true }
                        readonly property Item currentEntry: { sideRepeater.count; return sideRepeater.itemAt(root.index) }
                        Rectangle {
                            id: pill
                            visible: sidebar.currentEntry !== null
                            x: sideColumn.x
                            y: sidebar.currentEntry ? sideColumn.y + sidebar.currentEntry.y + sidebar.currentEntry.entry.y : 0
                            width: sideColumn.width
                            height: sidebar.currentEntry ? sidebar.currentEntry.entry.height : 0
                            radius: Theme.radiusRow
                            color: Theme.selected
                            HighlightMotion on y { active: sidebar.pillReady }

                            // The accent mark, as in the pickers.
                            Rectangle {
                                x: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: 16
                                radius: Theme.radiusMark
                                color: Theme.accent
                            }
                        }

                        Column {
                            id: sideColumn
                            anchors { fill: parent; margins: Theme.cardInset + 8 }
                            spacing: 2
                            onPositioningComplete: if (!sidebar.pillReady) pillArm.restart()

                            StyledText {
                                text: "Settings"
                                color: Theme.bright
                                font.pixelSize: Theme.fontLarge
                                height: 44
                                leftPadding: 8
                            }
                            Repeater {
                                id: sideRepeater
                                model: root.sections
                                Column {
                                    required property var modelData
                                    required property int index
                                    readonly property alias entry: sideEntry
                                    width: parent.width

                                    // A small heading where a group starts
                                    StyledText {
                                        visible: index === 0 || root.sections[index - 1].group !== modelData.group
                                        leftPadding: 8
                                        topPadding: index === 0 ? 4 : 16
                                        bottomPadding: 6
                                        text: modelData.group
                                        color: Theme.dim
                                        font.pixelSize: Theme.fontSmall
                                    }
                                    SideItem {
                                        id: sideEntry
                                        text: modelData.label
                                        glyph: modelData.glyph
                                        current: ShellState.settingsSection === modelData.id
                                        onClicked: { ShellState.settingsSection = modelData.id; card.forceActiveFocus() }
                                    }
                                }
                            }
                        }

                    }

                    Rectangle { width: 1; height: parent.height; color: Theme.border }

                    // ---- the settings of the chosen section ----
                    Item {
                        id: pane
                        width: parent.width - root.sidebarWidth - 1
                        height: parent.height

                        // A new section changes in place: the page showing (and its heading) fades out, then the new one is
                        // loaded and fades in while settling Theme.pageShift px from the right (fades only for reduce motion).
                        // `shown` is the section on screen, which trails root.index by the fade-out. Each change restarts
                        // the sequence from wherever it is, and its swap step reads root.index then, so rapid clicks always
                        // end on the latest section, fully opaque. Settings opens straight on its section (no fade).
                        property int shown: -1
                        property real fade: 1
                        property real shift: 0
                        readonly property int wanted: root.index
                        Component.onCompleted: shown = wanted
                        onWantedChanged: if (shown >= 0) swap.restart()

                        SequentialAnimation {
                            id: swap
                            NumberAnimation { target: pane; property: "fade"; to: 0; duration: Theme.durFast; easing.type: Theme.easeOut }
                            ScriptAction {
                                script: {
                                    // The control with the focus is about to go with its page: give the focus back to the sidebar.
                                    if (win.inContent(card.Window.activeFocusItem)) card.forceActiveFocus()
                                    pane.shown = pane.wanted
                                    pane.shift = Theme.reduceMotion ? 0 : Theme.pageShift
                                }
                            }
                            ParallelAnimation {
                                NumberAnimation { target: pane; property: "fade"; to: 1; duration: Theme.durBase; easing.type: Theme.easeOut }
                                NumberAnimation { target: pane; property: "shift"; to: 0; duration: Theme.durBase; easing.type: Theme.easeOut }
                            }
                        }

                        StyledText {
                            id: heading
                            x: root.pad
                            y: root.pad
                            text: pane.shown >= 0 ? root.sections[pane.shown].label : ""
                            color: Theme.bright
                            font.pixelSize: Theme.fontXL
                            opacity: pane.fade
                            transform: Translate { x: pane.shift }
                        }

                        Loader {
                            id: content
                            anchors { left: parent.left; right: parent.right; top: heading.bottom; bottom: parent.bottom; margins: root.pad; topMargin: 16 }
                            active: win.visible
                            source: pane.shown >= 0 ? root.sections[pane.shown].file : ""
                            opacity: pane.fade
                            transform: Translate { x: pane.shift }
                        }

                        // Close: an x at the top right of the window.
                        Rectangle {
                            id: closeButton
                            anchors { top: parent.top; right: parent.right; margins: 14 }
                            width: 32
                            height: 32
                            radius: Theme.radiusRow
                            color: closeArea.pressed ? Theme.selected : closeArea.containsMouse ? Theme.hover : Theme.clear
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                            activeFocusOnTab: true
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { ShellState.settingsOpen = false; event.accepted = true }
                            }
                            StyledText { anchors.centerIn: parent; text: Theme.glyphTimes; color: closeArea.containsMouse ? Theme.bright : Theme.dim; font.pixelSize: Theme.fontXL }
                            MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ShellState.settingsOpen = false }
                            FocusRing { shown: closeButton.activeFocus; anchors.margins: -3 }
                        }
                    }
                }
            }
        }
    }
}
