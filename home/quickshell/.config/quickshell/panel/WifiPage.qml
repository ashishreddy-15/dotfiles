import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Wi-Fi page: the networks around you, and a password prompt for new secured ones.
// Networks are looked for only while this page is open.
Column {
    id: root

    signal back()

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    // Connected first, then saved ones, then by signal strength; the best few.
    readonly property var networks: {
        if (!wifi) return []
        return wifi.networks.values.slice().sort((a, b) =>
            (b.connected - a.connected) || ((b.known ? 1 : 0) - (a.known ? 1 : 0)) || (b.signalStrength - a.signalStrength))
            .slice(0, 8)
    }

    property string askingFor: ""       // name of the secured network we are asking a password for

    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: ShellState.panelOpen
        when: root.wifi !== null
    }

    function activate(n) {
        if (n.connected) { n.disconnect(); return }
        if (n.known || n.security === WifiSecurityType.Open) { n.connect(); return }
        askingFor = (askingFor === n.name) ? "" : n.name      // new and secured: ask for the password
    }

    PageHeader {
        title: "Wi-Fi"
        switchText: Networking.wifiEnabled ? "on" : "off"
        switchColor: Networking.wifiEnabled ? Theme.ok : Theme.dim
        onBack: root.back()
        onSwitched: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    StyledText {
        visible: !Networking.wifiEnabled
        leftPadding: 10
        topPadding: 8
        bottomPadding: 8
        text: "Wi-Fi is off"
        color: Theme.dim
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []

        Column {
            id: entry
            required property var modelData
            width: root.width

            readonly property bool secured: modelData.security !== WifiSecurityType.Open
            readonly property bool connecting: modelData.state === ConnectionState.Connecting

            ListItem {
                text: entry.modelData.name
                marked: entry.modelData.connected
                // "connecting…", or the signal strength, with a padlock in front of networks that need a password
                detail: entry.connecting ? "connecting…"
                      : (entry.secured && !entry.modelData.known ? Theme.glyphLock + "  " : "") + Math.round(entry.modelData.signalStrength * 100) + "%"
                rightColor: entry.modelData.connected ? Theme.ok : Theme.dim
                onClicked: root.activate(entry.modelData)
            }

            // Password prompt under the network that needs one
            Item {
                visible: root.askingFor === entry.modelData.name
                width: parent.width
                height: visible ? 36 : 0

                Rectangle {
                    x: 28; y: 2
                    width: parent.width - 28 - 10
                    height: 30
                    radius: Theme.radiusRow
                    color: Theme.bg
                    border.width: 1
                    border.color: pass.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: pass
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
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
                            text: "password, then Enter"
                            color: Theme.dim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
