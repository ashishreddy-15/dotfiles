import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// "wifi <name>", "eth on", "wifi off" or "net none".
// Quiet: only shown when there is no connection.
StatusItem {
    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected)
    readonly property var wifi:  devices.find(d => d.type === DeviceType.Wifi)
    readonly property var ssid:  wifi?.networks.values.find(n => n.connected)?.name

    label: wired ? "eth" : wifi ? "wifi" : "net"
    value: wired ? "on"
         : !wifi ? "none"
         : !Networking.wifiEnabled ? "off"
         : ssid ? (ssid.length > 16 ? ssid.slice(0, 15) + "…" : ssid)
         : "--"
    valueColor: (wired || ssid) ? Theme.text : Theme.warn
    attention: !(wired || ssid)
}
