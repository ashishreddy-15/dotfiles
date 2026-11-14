import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Wi-Fi: the switch, and the networks around you. A new secured network asks for its password under it.
// Networks are scanned for only while Settings is open on this section.
Page {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var connected: wifi?.networks.values.find(n => n.connected) ?? null

    // Connected first, then saved ones, then by signal strength.
    readonly property var networks: {
        if (!wifi) return []
        return wifi.networks.values.slice().sort((a, b) =>
            (b.connected - a.connected) || ((b.known ? 1 : 0) - (a.known ? 1 : 0)) || (b.signalStrength - a.signalStrength))
    }

    property string askingFor: ""       // name of the secured network we are asking a password for

    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: ShellState.settingsOpen && root.visible
        when: root.wifi !== null
    }

    function activate(n) {
        if (n.connected) { n.disconnect(); return }
        if (n.known || n.security === WifiSecurityType.Open) { n.connect(); return }
        askingFor = (askingFor === n.name) ? "" : n.name
    }

    SettingRow {
        title: "Wi-Fi"
        description: !root.wifi ? "No Wi-Fi adapter" : !Networking.wifiEnabled ? "Off" : root.connected ? "Connected to " + root.connected.name : "Not connected"
        Switch { checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
    }

    GroupLabel { visible: Networking.wifiEnabled; text: "Networks" }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []

        Column {
            id: entry
            required property var modelData
            width: root.width

            readonly property bool secured: modelData.security !== WifiSecurityType.Open
            readonly property bool connecting: modelData.state === ConnectionState.Connecting

            ListRow {
                title: entry.modelData.name
                marked: entry.modelData.connected
                // "connecting…", or the signal strength, with a padlock in front of networks that need a password
                detail: entry.connecting ? "connecting…"
                      : (entry.secured && !entry.modelData.known ? Theme.glyphLock + "  " : "") + Math.round(entry.modelData.signalStrength * 100) + "%"
                detailColor: entry.modelData.connected ? Theme.ok : Theme.dim
                onClicked: root.activate(entry.modelData)
            }

            // Password prompt under the network that needs one
            Item {
                visible: root.askingFor === entry.modelData.name
                width: parent.width
                height: visible ? 44 : 0

                Rectangle {
                    x: 32; y: 4
                    width: parent.width - 32 - 14
                    height: 34
                    radius: Theme.radiusRow
                    color: Theme.hover
                    border.width: 1
                    border.color: pass.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: pass
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.bright
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBase
                        clip: true
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                        onAccepted: { entry.modelData.connectWithPsk(text); root.askingFor = ""; text = "" }
                        Keys.onEscapePressed: root.askingFor = ""

                        StyledText {
                            visible: pass.text === ""
                            text: "Password, then Enter"
                            color: Theme.dim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
