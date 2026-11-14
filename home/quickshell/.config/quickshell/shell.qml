//@ pragma UseQApplication

// Entry point. Each piece of the desktop lives in its own folder and is listed here.
// Quickshell reloads automatically when any of these files is saved.
// Logs: journalctl --user -u quickshell -f

import Quickshell
import "bar"
import "notifications"
import "osd"
import "launcher"
import "clipboard"
import "wallpaper"
import "panel"
import "settings"
import "bluetooth"
import "power"

ShellRoot {
    Bar {}
    Notifications {}
    NotificationCenter {}
    Osd {}
    Launcher {}
    Clipboard {}
    Wallpaper {}
    QuickPanel {}
    SettingsWindow {}
    PairingPrompt {}
    PowerMenu {}
}
