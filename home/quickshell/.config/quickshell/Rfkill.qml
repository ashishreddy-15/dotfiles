pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// The radio on/off switches of the laptop (rfkill). Needed for Bluetooth: while the radio is blocked (the ThinkPad's
// Fn key, or an app switching it off) the adapter may still be listed as "powered", or be removed altogether
// ("no adapter"), and either way Bluetooth does not work and BlueZ cannot switch it on. This says whether the radio is
// blocked, and can unblock it.
Singleton {
    id: root

    property bool bluetoothBlocked: false        // some Bluetooth radio is blocked (by software)
    property bool bluetoothHardBlocked: false    // blocked by a hardware switch: software cannot undo that

    function refresh() { if (!query.running) query.running = true }
    function unblockBluetooth() { unblocker.running = true }

    Process {
        id: query
        command: ["rfkill", "-J"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const bt = JSON.parse(text).rfkilldevices.filter(d => d.type === "bluetooth")
                    root.bluetoothBlocked = bt.some(d => d.soft === "blocked" || d.hard === "blocked")
                    root.bluetoothHardBlocked = bt.some(d => d.hard === "blocked")
                } catch (e) { /* no rfkill: leave as it was */ }
            }
        }
    }

    Process {
        id: unblocker
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: root.refresh()
    }

    // `rfkill event` prints a line whenever a radio is blocked or unblocked (the Fn key, an app, or us): look again.
    Process {
        running: true
        command: ["rfkill", "event"]
        stdout: SplitParser { onRead: root.refresh() }
    }

    // The adapter appears and disappears too on some machines when the radio is blocked: look again.
    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { root.refresh() }
    }

    Component.onCompleted: refresh()
}
