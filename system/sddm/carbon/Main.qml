import QtQuick
import QtQuick.Effects

// The login screen (SDDM), in the same look as the lock screen (hypr/hyprlock.conf): no card, the wallpaper itself
// (lightly blurred); the date and a large light clock near the top; your name and a frosted pill for the password near
// the bottom; the session (Hyprland, Hyprland with uwsm, Sway) and the power buttons small along the bottom edge.
// Enter logs in. Colours are copies of quickshell/Theme.qml's (SDDM cannot read it); scripts/ui-check compares them.
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
    readonly property color glass:    Qt.rgba(0.078, 0.078, 0.078, 0.60)   // the pill: Theme.card, a little more see-through
    readonly property color hair:     Qt.rgba(1, 1, 1, 0.12)               // its outline: Theme.selected
    readonly property color hover:    Qt.rgba(1, 1, 1, 0.07)
    readonly property color selected: Qt.rgba(1, 1, 1, 0.12)
    readonly property int radiusRow:  6
    readonly property int durFast:    90
    readonly property int durBase:    140
    readonly property real springPress:  5.5    // the press-in scale only: the small bounce reads as tactile
    readonly property real dampingPress: 0.36
    readonly property real epsNorm: 0.004
    readonly property real epsPx: 0.4
    readonly property real pressScale: 0.94
    readonly property string font: maple.status === FontLoader.Ready ? maple.font.family : "monospace"
    readonly property string fontLight: mapleLight.status === FontLoader.Ready ? mapleLight.font.family : font

    color: bg
    width: 1920
    height: 1080

    FontLoader { id: maple; source: config.font }
    FontLoader { id: mapleLight; source: config.fontLight }

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
        function onLoginFailed() {
            root.failed = true
            password.text = ""
            password.forceActiveFocus()
            pill.shakeSpring = false
            pill.shakeOffset = -14
            Qt.callLater(() => { pill.shakeSpring = true; pill.shakeOffset = 0 })
        }
    }

    // ---- background: the wallpaper, lightly blurred and a little darker ----
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
        blur: 0.35
        blurMax: 32
        brightness: -0.18
        opacity: wallpaper.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.durBase * 3 } }
    }

    // Everything on top gets a soft shadow, so it reads on light wallpapers too.
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            shadowBlur: 0.6
            shadowVerticalOffset: 2
        }

        // ---- top: the date, then the time ----
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.12 }
            spacing: 0

            Text {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(new Date(), "dddd d MMMM")
                color: root.text
                font.family: root.font
                font.pixelSize: 24
            }
            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(), "HH:mm")
                color: root.bright
                font.family: root.fontLight
                font.pixelSize: 150
            }
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: { clock.text = Qt.formatTime(new Date(), "HH:mm"); date.text = Qt.formatDate(new Date(), "dddd d MMMM") }
            }
        }

        // ---- bottom: who you are, then the password ----
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.14 }
            spacing: 14

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.user
                color: root.text
                font.family: root.font
                font.pixelSize: 18
            }

            // A frosted pill. The outline turns pewter while typing and red after a wrong password.
            Rectangle {
                id: pill
                property real shakeOffset: 0
                property bool shakeSpring: true
                width: 340
                height: 46
                radius: height / 2
                color: root.glass
                border.width: 1
                border.color: root.failed ? root.err : password.activeFocus && password.text !== "" ? root.accent : root.hair
                Behavior on border.color { ColorAnimation { duration: root.durFast } }
                transform: Translate { x: pill.shakeOffset }
                Behavior on shakeOffset {
                    enabled: pill.shakeSpring
                    // Wrong password: a stiffer press spring with low damping, so it rings a few times. Bouncy on purpose.
                    SpringAnimation { spring: root.springPress * 1.5; damping: 0.22; epsilon: root.epsPx }
                }

                TextInput {
                    id: password
                    anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.bright
                    font.family: root.font
                    font.pixelSize: 16
                    focus: true
                    clip: true
                    onAccepted: root.login()
                    onTextChanged: if (text !== "") root.failed = false
                    Keys.onEscapePressed: text = ""

                    Text {
                        visible: password.text === ""
                        anchors.centerIn: parent
                        text: root.failed ? "Wrong password" : "Password"
                        color: root.failed ? root.err : root.text
                        font.family: root.font
                        font.pixelSize: 16
                    }
                }
            }
        }

        // ---- along the bottom edge: the session (left) and the power buttons (right), small ----
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
            scale: chipArea.pressed ? root.pressScale : 1
            Behavior on scale { SpringAnimation { spring: root.springPress; damping: root.dampingPress; epsilon: root.epsNorm } }
            Text { id: chipText; anchors.centerIn: parent; text: chip.label; color: chip.on ? root.bright : root.text; font.family: root.font; font.pixelSize: 13 }
            MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
        }

        Row {
            anchors { left: parent.left; bottom: parent.bottom; margins: 24 }
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
            anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
            spacing: 4
            Chip { label: "suspend";  visible: sddm.canSuspend;  onClicked: sddm.suspend() }
            Chip { label: "reboot";   visible: sddm.canReboot;   onClicked: sddm.reboot() }
            Chip { label: "shutdown"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
        }
    }
}
