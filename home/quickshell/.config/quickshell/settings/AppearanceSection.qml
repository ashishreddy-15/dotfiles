import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Appearance: how GTK apps look. Three tabs: Style (colour scheme, GTK theme), Icons & cursor, Fonts.
// State and the work are in Appearance.qml and the `appearance` script; every change applies at once.
Item {
    id: root

    property string tab: "style"

    Component.onCompleted: Appearance.refresh()

    onTabChanged: {
        if (tab !== "fonts") return
        // The font list: type to search, and start with the current font in view.
        Qt.callLater(() => {
            search.forceActiveFocus()
            fonts.positionViewAtIndex(Math.max(0, fonts.model.indexOf(Appearance.font)), ListView.Center)
        })
    }

    Segmented {
        id: tabs
        options: [{ label: "Style", value: "style" }, { label: "Icons & cursor", value: "icons" }, { label: "Fonts", value: "fonts" }]
        value: root.tab
        onPicked: v => root.tab = v
    }

    // Style
    Page {
        visible: root.tab === "style"
        anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; topMargin: 8 }

        SettingRow {
            title: "Colour scheme"
            description: "Dark or light. Applies to the shell, window borders, the terminal and GTK apps."
            Segmented {
                options: [{ label: "dark", value: "prefer-dark" }, { label: "light", value: "prefer-light" }]
                value: Appearance.scheme === "prefer-dark" ? "prefer-dark" : "prefer-light"
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
    Page {
        visible: root.tab === "icons"
        anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; topMargin: 8 }

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
        visible: root.tab === "fonts"
        anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; topMargin: 12 }
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
                onTextChanged: fonts.currentIndex = 0
                // Keyboard: Up / Down move through the list, Enter chooses the marked family.
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) fonts.currentIndex = Math.min(fonts.count - 1, fonts.currentIndex + 1)
                    else if (event.key === Qt.Key_Up) fonts.currentIndex = Math.max(0, fonts.currentIndex - 1)
                    else if (event.key === Qt.Key_PageDown) fonts.currentIndex = Math.min(fonts.count - 1, fonts.currentIndex + 8)
                    else if (event.key === Qt.Key_PageUp) fonts.currentIndex = Math.max(0, fonts.currentIndex - 8)
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { if (fonts.count > 0) Appearance.set("font", fonts.model[fonts.currentIndex]) }
                    else return
                    event.accepted = true
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
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
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
                color: on ? Theme.selected : (area.containsMouse || (ListView.isCurrentItem && search.activeFocus) ? Theme.hover : Theme.clear)
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
