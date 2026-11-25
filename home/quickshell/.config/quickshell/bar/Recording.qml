import QtQuick
import Quickshell
import qs

// "● rec 1:23" while the screen is being recorded (home/bin/.local/bin/screenrecord). Click it to stop.
Item {
    id: root

    visible: ShellState.recording
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    property int seconds: 0
    function update() { seconds = Math.max(0, Math.floor(Date.now() / 1000 - ShellState.recordingSince)) }
    Timer { interval: 1000; repeat: true; triggeredOnStart: true; running: ShellState.recording; onTriggered: root.update() }

    Row {
        id: row
        spacing: 6

        // The dot pulses gently, the way a recording light does.
        BarText {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.glyphMark
            color: Theme.barErr
            font.pixelSize: Theme.fontMark
            SequentialAnimation on opacity {
                running: ShellState.recording && !Theme.reduceMotion   // reduce motion: a steady dot
                loops: Animation.Infinite
                onRunningChanged: if (!running) dot.opacity = 1
                NumberAnimation { to: 0.35; duration: Theme.durPulse; easing.type: Theme.easeInOut }
                NumberAnimation { to: 1; duration: Theme.durPulse; easing.type: Theme.easeInOut }
            }
        }
        BarText {
            text: "rec " + Math.floor(root.seconds / 60) + ":" + String(root.seconds % 60).padStart(2, "0")
            color: Theme.barErr
        }
    }

    MouseArea {
        anchors { fill: parent; margins: -6 }
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.stopRecording()
    }
}
