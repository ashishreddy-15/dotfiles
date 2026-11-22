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

    // ---- keyboard focus: the sidebar (the card itself has the focus) or a control inside the section ----
    Connections {
        target: ShellState
        function onSettingsOpenChanged() { if (ShellState.settingsOpen) { win.requestActivate(); card.forceActiveFocus() } }
        function onSettingsSectionChanged() { card.forceActiveFocus() }
    }
    function inContent(item) {
        for (let p = item; p; p = p.parent) if (p === content) return true
        return false
    }
    // Into the section: the first control. Between controls: the next / previous one; before the first, the sidebar.
    function moveFocus(forward) {
        const cur = card.Window.activeFocusItem
        const from = inContent(cur) ? cur : content
        const next = from.nextItemInFocusChain(forward)
        if (next && inContent(next) && next !== content) next.forceActiveFocus()
        else if (!forward) card.forceActiveFocus()
    }

    FloatingWindow {
        id: win

        title: "Settings"
        visible: ShellState.settingsOpen
        // Closed by the compositor (Super + Q): keep the shared state in step.
        onVisibleChanged: if (!visible) ShellState.settingsOpen = false
        implicitWidth: root.cardWidth
        implicitHeight: root.cardHeight
        minimumSize: Qt.size(root.minWidth, root.minHeight)
        color: Theme.surface

        Item {
            id: card
            anchors.fill: parent
            readonly property real shown: win.visible ? 1 : 0

            // Keys the controls do not use come up to here (the controls handle Enter, Space and Left / Right themselves).
            focus: true
            Keys.onPressed: event => {
                const inside = root.inContent(card.Window.activeFocusItem)
                if (event.key === Qt.Key_Down) { if (inside) root.moveFocus(true); else root.go(root.index + 1) }
                else if (event.key === Qt.Key_Up) { if (inside) root.moveFocus(false); else root.go(root.index - 1) }
                else if (event.key === Qt.Key_Tab) root.moveFocus(true)
                else if (event.key === Qt.Key_Backtab) root.moveFocus(false)
                else if (!inside && (event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) root.moveFocus(true)
                else if (inside && event.key === Qt.Key_Left) card.forceActiveFocus()
                else return
                event.accepted = true
            }

            Row {
                anchors.fill: parent

                // ---- sidebar ----
                Item {
                    width: root.sidebarWidth
                    height: parent.height

                    Column {
                        anchors { fill: parent; margins: Theme.cardInset + 8 }
                        spacing: 2

                        StyledText {
                            text: "Settings"
                            color: Theme.bright
                            font.pixelSize: Theme.fontLarge
                            height: 44
                            leftPadding: 8
                        }
                        Repeater {
                            model: root.sections
                            Column {
                                required property var modelData
                                required property int index
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
                    width: parent.width - root.sidebarWidth - 1
                    height: parent.height

                    StyledText {
                        id: heading
                        x: root.pad
                        y: root.pad
                        text: root.sections[root.index].label
                        color: Theme.bright
                        font.pixelSize: Theme.fontXL
                    }

                    Loader {
                        id: content
                        anchors { left: parent.left; right: parent.right; top: heading.bottom; bottom: parent.bottom; margins: root.pad; topMargin: 16 }
                        active: win.visible
                        source: root.sections[root.index].file
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
                        FocusRing { visible: closeButton.activeFocus; anchors.margins: -3 }
                    }
                }
            }
        }
    }
}
