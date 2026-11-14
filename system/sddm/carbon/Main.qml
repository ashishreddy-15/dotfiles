import QtQuick
import QtQuick.Effects

// The login screen (SDDM), in the same look as the lock screen (hypr/hyprlock.conf) and the shell
// (quickshell/Theme.qml): the wallpaper blurred and darkened, one frosted card with the time, the date, who you are
// and the password; under it the session (Hyprland, Hyprland with uwsm, Sway) and the power buttons.
// Enter logs in. Colours and shapes are copies of Theme.qml's (SDDM cannot read it); scripts/ui-check compares them.
// Try it without logging out:  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/carbon
Rectangle {
    id: root

    // ---- Theme.qml ----
    readonly property color bg:       "#111111"
    readonly property color raised:   "#1b1b1b"
    readonly property color border:   "#262626"
    readonly property color text:     "#adb0b3"
    readonly property color dim:      "#666a6e"
    readonly property color bright:   "#d0d3d6"
    readonly property color accent:   "#6c7f91"
    readonly property color err:      "#a67a7e"
    readonly property color card:     Qt.rgba(0.078, 0.078, 0.078, 0.80)
    readonly property color hover:    Qt.rgba(1, 1, 1, 0.07)
    readonly property color selected: Qt.rgba(1, 1, 1, 0.12)
    readonly property int radiusCard: 10
    readonly property int radiusRow:  6
    readonly property int durFast:    90
    readonly property int durBase:    140
    readonly property string font: maple.status === FontLoader.Ready ? maple.font.family : "monospace"

    color: bg
    width: 1920
    height: 1080

    FontLoader { id: maple; source: config.font }

    property int sessionIndex: sessionModel.lastIndex
    // Who logs in: the last user, or (first boot) the first one on the system.
    property string user: userModel.lastUser
    Repeater {
        model: userModel
        Item {
            required property int index
            required property string name
            Component.onCompleted: if (index === 0 && root.user === "") root.user = name
        }
    }
    property bool failed: false

    function login() {
        failed = false
        sddm.login(user, password.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() { root.failed = true; password.text = ""; password.forceActiveFocus() }
    }

    // ---- background: the wallpaper, blurred and darkened ----
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: -0.25
        opacity: wallpaper.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.durBase * 3 } }
    }

    // ---- the card ----
    RectangularShadow {
        anchors.fill: cardRect
        radius: cardRect.radius
        blur: 28
        offset: Qt.vector2d(0, 8)
        color: Qt.rgba(0, 0, 0, 0.45)
    }
    Rectangle {
        id: cardRect
        anchors.centerIn: parent
        width: 400
        height: column.implicitHeight + 64
        radius: root.radiusCard
        color: root.card
        border.width: 1
        border.color: root.border

        Column {
            id: column
            anchors.centerIn: parent
            width: parent.width - 80
            spacing: 6

            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "HH:mm")
                color: root.bright
                font.family: root.font
                font.pixelSize: 64
                Timer { interval: 1000; running: true; repeat: true; onTriggered: { clock.text = Qt.formatTime(new Date(), "HH:mm"); date.text = Qt.formatDate(new Date(), "ddd d MMM") } }
            }
            Text {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "ddd d MMM")
                color: root.dim
                font.family: root.font
                font.pixelSize: 16
            }

            Item { width: 1; height: 18 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.user
                color: root.text
                font.family: root.font
                font.pixelSize: 15
            }

            // password
            Rectangle {
                width: parent.width
                height: 44
                radius: root.radiusRow
                color: root.raised
                border.width: 1
                border.color: root.failed ? root.err : password.activeFocus ? root.accent : root.border
                Behavior on border.color { ColorAnimation { duration: root.durFast } }

                TextInput {
                    id: password
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.bright
                    font.family: root.font
                    font.pixelSize: 15
                    focus: true
                    clip: true
                    onAccepted: root.login()
                    onTextChanged: if (text !== "") root.failed = false
                    Keys.onEscapePressed: text = ""

                    Text {
                        visible: password.text === ""
                        anchors.centerIn: parent
                        text: root.failed ? "Wrong password" : "Password"
                        color: root.failed ? root.err : root.dim
                        font.family: root.font
                        font.pixelSize: 15
                    }
                }
            }
        }
    }

    // ---- under the card: the session, then the power buttons ----
    component Chip: Rectangle {
        id: chip
        property string label
        property bool on: false
        signal clicked()
        width: chipText.implicitWidth + 24
        height: 30
        radius: root.radiusRow
        color: on ? root.selected : (chipArea.containsMouse ? root.hover : "transparent")
        Behavior on color { ColorAnimation { duration: root.durFast } }
        Text { id: chipText; anchors.centerIn: parent; text: chip.label; color: chip.on ? root.bright : root.text; font.family: root.font; font.pixelSize: 13 }
        MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: cardRect.bottom; topMargin: 24 }
        spacing: 14

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: sessionModel
                Chip {
                    required property int index
                    required property string name
                    label: name
                    on: root.sessionIndex === index
                    onClicked: { root.sessionIndex = index; password.forceActiveFocus() }
                }
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Chip { label: "suspend";  visible: sddm.canSuspend;  onClicked: sddm.suspend() }
            Chip { label: "reboot";   visible: sddm.canReboot;   onClicked: sddm.reboot() }
            Chip { label: "shutdown"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
        }
    }
}
