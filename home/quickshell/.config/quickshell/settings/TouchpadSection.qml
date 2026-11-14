import QtQuick
import Quickshell
import qs

// Touchpad: tapping, scrolling, speed and right-click (Touchpad.qml applies them live).
Page {
    id: root

    StyledText {
        visible: !Touchpad.present
        width: parent.width
        topPadding: 8
        text: "No touchpad found."
        color: Theme.dim
    }

    SettingRow {
        visible: Touchpad.present
        title: "Tap to click"
        description: "A light tap is a click (two fingers: right click, three: middle)."
        Switch { checked: Touchpad.tapToClick; onToggled: Touchpad.set("tapToClick", !Touchpad.tapToClick) }
    }
    SettingRow {
        visible: Touchpad.present
        title: "Natural scrolling"
        description: "Content follows your fingers, like on a phone."
        Switch { checked: Touchpad.naturalScroll; onToggled: Touchpad.set("naturalScroll", !Touchpad.naturalScroll) }
    }
    SettingRow {
        visible: Touchpad.present
        title: "Speed"
        description: "How fast the pointer moves with the touchpad (the mouse is not affected)."
        LevelSlider {
            value: (Touchpad.speed + 1) / 2
            valueText: Math.abs(Touchpad.speed) < 0.025 ? "normal" : (Touchpad.speed > 0 ? "+" : "") + Math.round(Touchpad.speed * 100) + "%"
            textWidth: 64
            onMoved: v => Touchpad.set("speed", Math.round((v * 2 - 1) * 20) / 20)
        }
    }
    SettingRow {
        visible: Touchpad.present
        title: "Scroll speed"
        description: "How far two-finger scrolling moves the page."
        LevelSlider {
            value: (Touchpad.scroll - 0.25) / 1.75
            valueText: Touchpad.scroll.toFixed(2).replace(/0$/, "") + Theme.glyphTimes
            textWidth: 64
            onMoved: v => Touchpad.set("scroll", Math.round((0.25 + v * 1.75) * 20) / 20)
        }
    }
    SettingRow {
        visible: Touchpad.present
        title: "Right click"
        description: "Click with two fingers, or press the bottom-right corner of the touchpad."
        Segmented {
            options: [{ label: "Two fingers", value: true }, { label: "Corner", value: false }]
            value: Touchpad.twoFingerRightClick
            onPicked: v => Touchpad.set("twoFingerRightClick", v)
        }
    }
    SettingRow {
        visible: Touchpad.present
        title: "Tap and drag"
        description: "Tap, then keep the finger down to drag."
        Switch { checked: Touchpad.tapAndDrag; onToggled: Touchpad.set("tapAndDrag", !Touchpad.tapAndDrag) }
    }
    SettingRow {
        visible: Touchpad.present
        title: "Off while typing"
        description: "Ignore the touchpad for a moment after a key press, so a palm does not move the pointer."
        Switch { checked: Touchpad.disableWhileTyping; onToggled: Touchpad.set("disableWhileTyping", !Touchpad.disableWhileTyping) }
    }
    StyledText {
        visible: Touchpad.present
        width: parent.width
        topPadding: 14
        text: "Three fingers left or right: switch workspace."
        color: Theme.dim
        font.pixelSize: Theme.fontSmall
    }
}
