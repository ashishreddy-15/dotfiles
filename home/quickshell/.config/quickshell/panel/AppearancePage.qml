import QtQuick
import Quickshell
import qs

// Appearance of GTK apps (Nautilus, pavucontrol...), like nwg-look: colour scheme, GTK / icon / cursor theme,
// font and sizes. State and the work live in Appearance.qml and the `appearance` script.
Column {
    id: root

    signal back()
    signal done()                 // close the panel (the font picker opens over the desktop)

    readonly property var schemes: [
        { name: "dark",   value: "prefer-dark" },
        { name: "light",  value: "prefer-light" },
        { name: "system", value: "default" }
    ]

    Component.onCompleted: Appearance.refresh()

    PageHeader { title: "Appearance"; onBack: root.back() }

    Heading { text: "colour scheme" }
    Repeater {
        model: root.schemes
        ListItem {
            required property var modelData
            text: modelData.name
            marked: Appearance.scheme === modelData.value
            onClicked: Appearance.set("color-scheme", modelData.value)
        }
    }

    Heading { text: "gtk theme" }
    Repeater {
        model: Appearance.gtkThemes
        ListItem {
            required property string modelData
            text: modelData
            marked: Appearance.gtkTheme === modelData
            onClicked: Appearance.set("gtk-theme", modelData)
        }
    }

    Heading { text: "icons" }
    Repeater {
        model: Appearance.iconThemes
        ListItem {
            required property string modelData
            text: modelData
            marked: Appearance.iconTheme === modelData
            onClicked: Appearance.set("icon-theme", modelData)
        }
    }

    Heading { text: "cursor" }
    Repeater {
        model: Appearance.cursorThemes
        ListItem {
            required property string modelData
            text: modelData
            marked: Appearance.cursorTheme === modelData
            onClicked: Appearance.set("cursor-theme", modelData)
        }
    }
    SliderRow {
        label: "size"
        value: (Appearance.cursorSize - 16) / 32
        valueText: Appearance.cursorSize + " px"
        onMoved: v => {
            const n = 16 + Math.round(v * 8) * 4          // 16 .. 48 in steps of 4
            if (n !== Appearance.cursorSize) Appearance.set("cursor-size", n)
        }
    }

    Heading { text: "font" }
    Line {
        label: "family"
        value: Appearance.font
        onClicked: { root.done(); ShellState.pickFont() }
    }
    SliderRow {
        label: "size"
        value: (Appearance.fontSize - 8) / 8
        valueText: Appearance.fontSize + " pt"
        onMoved: v => {
            const n = 8 + Math.round(v * 8)               // 8 .. 16
            if (n !== Appearance.fontSize) Appearance.set("font-size", n)
        }
    }
}
