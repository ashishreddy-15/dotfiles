pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth pairings started from Settings, and what to do when each one ends: on success trust the device (so it can
// reconnect by itself later) and connect; on failure remember it, so the list can say "failed, try again".
// This lives here, not in the rows of the device list: the list re-sorts (and rebuilds its rows) the moment a device
// becomes paired, and it is gone altogether when Settings closes, so a row cannot be trusted to still be there.
Singleton {
    id: root

    property var pending: []        // addresses of devices we are pairing
    property var failed: []         // addresses whose last pairing did not work
    property bool sectionOpen: false
    readonly property bool needAgent: sectionOpen || pending.length > 0

    // bt-agent (Python/PyGObject, ~31 MiB) only needs to run while Settings > Bluetooth is open or a pairing is in flight.
    onNeedAgentChanged: {
        if (needAgent) {
            stopAgent.stop()
            Quickshell.execDetached(["systemctl", "--user", "start", "bt-agent.service"])
        } else {
            stopAgent.restart()
        }
    }
    Timer {
        id: stopAgent
        interval: 5000
        onTriggered: if (!root.needAgent) Quickshell.execDetached(["systemctl", "--user", "stop", "bt-agent.service"])
    }

    function start(device) {
        failed = failed.filter(a => a !== device.address)
        if (!pending.includes(device.address)) pending = pending.concat([device.address])
        device.pair()
    }
    function hasFailed(device) { return failed.includes(device.address) }

    function settle(device) {
        if (!pending.includes(device.address) || device.pairing) return
        pending = pending.filter(a => a !== device.address)
        if (device.paired) {
            device.trusted = true
            if (!device.connected) device.connect()
        } else {
            failed = failed.concat([device.address])
        }
    }

    Instantiator {
        model: Bluetooth.devices
        delegate: Connections {
            required property var modelData
            target: modelData
            function onPairedChanged() { root.settle(modelData) }
            function onPairingChanged() { root.settle(modelData) }
        }
    }
}
