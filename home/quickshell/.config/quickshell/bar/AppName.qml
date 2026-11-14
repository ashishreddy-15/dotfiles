import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Name of the focused app, shown on the bar of the monitor it is on (like the macOS menu bar).
BarText {
    required property var screen

    readonly property var win: Hyprland.activeToplevel
    readonly property bool here: win?.monitor === Hyprland.monitorFor(screen)
    readonly property string appId: win?.wayland?.appId ?? ""

    font.weight: Font.Medium
    visible: here && appId !== ""
    // Prefer the app's proper name ("Files") over its id ("org.gnome.Nautilus").
    text: DesktopEntries.heuristicLookup(appId)?.name ?? appId
}
