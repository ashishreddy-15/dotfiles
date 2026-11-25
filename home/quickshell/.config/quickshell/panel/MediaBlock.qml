import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import "../ui"

// What is playing (any player: a browser tab, mpv, Spotify...) with previous / play-pause / next, on a soft card.
// Not shown at all when nothing is running.
Rectangle {
    id: root

    radius: Theme.radiusCard
    color: Theme.hover

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    visible: player !== null
    height: visible ? 56 : 0

    Item {
        anchors.fill: parent

        Column {
            anchors { left: parent.left; right: buttons.left; verticalCenter: parent.verticalCenter; leftMargin: 16; rightMargin: 8 }
            spacing: 2
            StyledText {
                width: parent.width
                text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                color: Theme.text
                elide: Text.ElideRight
            }
            StyledText {
                width: parent.width
                text: root.player ? (root.player.trackArtist || root.player.identity) : ""
                color: Theme.dim
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
        }

        Row {
            id: buttons
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 2

            component Button: Item {
                id: btn
                property string glyph
                property bool enabled: true
                signal clicked()
                width: 32
                height: 32
                opacity: enabled ? 1 : 0.35

                // Keyboard: Enter or Space presses it.
                activeFocusOnTab: enabled
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { btn.clicked(); event.accepted = true }
                }

                Pressable {
                    anchors.fill: parent
                    enabled: btn.enabled
                    onClicked: btn.clicked()
                    StyledText { anchors.centerIn: parent; text: btn.glyph; color: Theme.text }
                }
                FocusRing { shown: btn.activeFocus }
            }

            Button { glyph: Theme.glyphPrev; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }
            Button { glyph: root.player?.isPlaying ? Theme.glyphPause : Theme.glyphPlay; enabled: root.player?.canTogglePlaying ?? false; onClicked: root.player.togglePlaying() }
            Button { glyph: Theme.glyphForward; enabled: root.player?.canGoNext ?? false; onClicked: root.player.next() }
        }
    }
}
