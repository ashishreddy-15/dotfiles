import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import "../ui"

// The appearance settings: how GTK apps look (colour scheme, GTK / icon / cursor theme, fonts), in a window of its own,
// centred on the focused monitor, laid out like a settings app: a sidebar of sections and the settings of the chosen one.
//   Super + Shift + A      show / hide      (qs ipc call appearance toggle | open | close)
//   Esc, a click outside   close            Up / Down  change section (outside the font search)
// State and the work are in Appearance.qml and the `appearance` script; every change applies at once.
//
// Same build as the pickers: a fixed-size layer window with the Card inside it (see ui/Card.qml and picker/Picker.qml).
Scope {
    id: root

    property bool open: false
    property int page: 0
    readonly property var pages: ["Style", "Icons & cursor", "Fonts"]

    readonly property int cardWidth: 820
    readonly property int cardHeight: 560
    readonly property int sidebarWidth: 210
    readonly property int pad: 28

    IpcHandler {
        target: "appearance"
        function toggle(): void { root.open = !root.open }
        function open(): void   { root.open = true }
        function close(): void  { root.open = false }
    }

    onOpenChanged: if (open) { Appearance.refresh(); page = 0; keys.forceActiveFocus() }
    onPageChanged: {
        if (page !== 2) { keys.forceActiveFocus(); return }
        // The font list: type to search, and start with the current font in view.
        Qt.callLater(() => {
            search.forceActiveFocus()
            fonts.positionViewAtIndex(Math.max(0, fonts.model.indexOf(Appearance.font)), ListView.Center)
        })
    }

    PanelWindow {
        id: win

        // Open on the monitor you are working on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? ShellState.mainScreen
        visible: root.open || card.shown > 0

        // No anchors: the compositor centres the window.
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: root.cardWidth + 2 * Theme.shadowMargin
        implicitHeight: root.cardHeight + 2 * Theme.shadowMargin
        color: "transparent"
        mask: Region { item: card }
        WlrLayershell.namespace: "quickshell-appearance"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            active: root.open
            windows: [win]
            onCleared: root.open = false
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) root.open = false
                else if (event.key === Qt.Key_Down) root.page = Math.min(root.pages.length - 1, root.page + 1)
                else if (event.key === Qt.Key_Up) root.page = Math.max(0, root.page - 1)
                else return
                event.accepted = true
            }
        }

        Card {
            id: card
            x: Theme.shadowMargin
            y: Theme.shadowMargin
            width: root.cardWidth
            open: root.open
            contentHeight: root.cardHeight

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
                            text: "Appearance"
                            color: Theme.bright
                            font.pixelSize: Theme.fontLarge
                            height: 44
                            leftPadding: 8
                        }
                        Repeater {
                            model: root.pages
                            SideItem {
                                required property string modelData
                                required property int index
                                text: modelData
                                current: root.page === index
                                onClicked: root.page = index
                            }
                        }
                    }

                    StyledText {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 20 }
                        text: "Esc to close"
                        color: Theme.dim
                        font.pixelSize: Theme.fontSmall
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
                        text: root.pages[root.page]
                        color: Theme.bright
                        font.pixelSize: Theme.fontXL
                    }

                    // Style
                    Column {
                        visible: root.page === 0
                        anchors { left: parent.left; right: parent.right; top: heading.bottom; margins: root.pad; topMargin: 16 }

                        SettingRow {
                            title: "Colour scheme"
                            description: "Dark or light for GTK4 apps such as Files. GTK3 apps (Bluetooth, file dialogs) stay dark."
                            Segmented {
                                options: [{ label: "dark", value: "prefer-dark" }, { label: "light", value: "prefer-light" }, { label: "system", value: "default" }]
                                value: Appearance.scheme
                                onPicked: v => Appearance.set("color-scheme", v)
                            }
                        }
                        SettingRow {
                            title: "GTK theme"
                            description: Appearance.gtkThemes.length > 1 ? "The look of GTK apps." : "Only Adwaita is installed. Others appear here when installed (for example adw-gtk3-theme)."
                            Segmented {
                                options: Appearance.gtkThemes
                                value: Appearance.gtkTheme
                                onPicked: v => Appearance.set("gtk-theme", v)
                            }
                        }
                    }

                    // Icons & cursor
                    Column {
                        visible: root.page === 1
                        anchors { left: parent.left; right: parent.right; top: heading.bottom; margins: root.pad; topMargin: 16 }

                        SettingRow {
                            title: "Icon theme"
                            description: "The icons in apps and in the launcher."
                            Segmented {
                                options: Appearance.iconThemes
                                value: Appearance.iconTheme
                                onPicked: v => Appearance.set("icon-theme", v)
                            }
                        }
                        SettingRow {
                            title: "Cursor theme"
                            description: "The mouse pointer."
                            Segmented {
                                options: Appearance.cursorThemes
                                value: Appearance.cursorTheme
                                onPicked: v => Appearance.set("cursor-theme", v)
                            }
                        }
                        SettingRow {
                            title: "Cursor size"
                            description: "Takes effect at once in new windows; some open apps need a restart."
                            Stepper {
                                value: Appearance.cursorSize
                                from: 16; to: 48; step: 4
                                suffix: " px"
                                onChanged: v => Appearance.set("cursor-size", v)
                            }
                        }
                    }

                    // Fonts
                    ColumnLayout {
                        visible: root.page === 2
                        anchors { left: parent.left; right: parent.right; top: heading.bottom; bottom: parent.bottom; margins: root.pad; topMargin: 16 }
                        spacing: 0

                        // How the chosen font looks
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: Theme.radiusRow
                            color: Theme.hover
                            StyledText {
                                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                                text: "The quick brown fox jumps over the lazy dog"
                                color: Theme.bright
                                elide: Text.ElideRight
                                font.family: Appearance.font
                                font.pixelSize: Math.round(Appearance.fontSize * 4 / 3)   // points to pixels
                            }
                        }

                        SettingRow {
                            Layout.fillWidth: true
                            title: "Size"
                            description: "Text in GTK apps."
                            Stepper {
                                value: Appearance.fontSize
                                from: 8; to: 16
                                suffix: " pt"
                                onChanged: v => Appearance.set("font-size", v)
                            }
                        }

                        // Family: a search field and the list of every installed family
                        StyledText {
                            Layout.topMargin: 14
                            Layout.bottomMargin: 8
                            text: "Family"
                            color: Theme.bright
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: Theme.radiusRow
                            color: Theme.hover

                            TextInput {
                                id: search
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.bright
                                selectionColor: Theme.border
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBase
                                clip: true
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) { root.open = false; event.accepted = true }
                                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (fonts.count > 0) Appearance.set("font", fonts.model[0])
                                        event.accepted = true
                                    }
                                }
                                StyledText {
                                    visible: search.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search fonts"
                                    color: Theme.dim
                                }
                            }
                        }
                        ListView {
                            id: fonts
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 6
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: {
                                const q = search.text.trim().toLowerCase()
                                return Appearance.fonts.filter(f => q === "" || f.toLowerCase().includes(q))
                            }
                            delegate: Rectangle {
                                id: fontRow
                                required property string modelData
                                readonly property bool on: Appearance.font === modelData
                                width: ListView.view.width
                                height: 30
                                radius: Theme.radiusRow
                                color: on ? Theme.selected : (area.containsMouse ? Theme.hover : Theme.clear)
                                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                                StyledText {
                                    x: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: fontRow.modelData
                                    color: fontRow.on ? Theme.bright : Theme.text
                                }
                                MouseArea {
                                    id: area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Appearance.set("font", fontRow.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
