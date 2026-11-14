import QtQuick
import Quickshell
import qs
import "../picker"

// Choose the font of GTK apps from every installed family (Picker, like the wallpaper picker).
// Opened from the control center's appearance page (ShellState.pickFont()).
Scope {
    id: root

    Picker {
        id: picker
        namespace: "quickshell-fonts"
        placeholder: "Choose font"
        maxResults: 10
        items: {
            const q = picker.query.trim().toLowerCase()
            return Appearance.fonts
                .filter(f => q === "" || f.toLowerCase().includes(q))
                .map(f => ({ title: f, subtitle: f === Appearance.font ? "current" : "" }))
        }
        onActivated: item => Appearance.set("font", item.title)
    }

    Connections {
        target: ShellState
        function onPickFont() { Appearance.refresh(); later.restart() }
    }
    // Open once the control center has finished closing: while it is still mapped it holds the keyboard focus,
    // and a picker opened at the same moment would never get it.
    Timer { id: later; interval: Theme.durFast + 130; onTriggered: picker.open = true }
}
