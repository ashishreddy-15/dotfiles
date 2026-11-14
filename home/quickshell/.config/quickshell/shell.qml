//@ pragma UseQApplication

// Entry point. Each piece of the desktop lives in its own folder and is listed here.
// Quickshell reloads automatically when any of these files is saved.
// Logs: journalctl --user -u quickshell -f

import Quickshell
import "bar"
import "notifications"
import "osd"

ShellRoot {
    Bar {}
    Notifications {}
    Osd {}
}
