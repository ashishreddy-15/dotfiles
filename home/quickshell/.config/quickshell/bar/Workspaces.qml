import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import "../ui"

// The workspaces that live on this bar's monitor, terminal style:  1 [2] 3
// Click to switch. Every number keeps an invisible pair of brackets as spacers, so nothing shifts; one real pair
// is drawn on top and glides from the old workspace to the new one (HighlightMotion).
Item {
    id: root

    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // The workspace shown on this monitor right now (null if none of ours is, e.g. for a moment while switching).
    readonly property Item currentItem: {
        const items = row.children
        for (let i = 0; i < items.length; i++) if (items[i].current) return items[i]
        return null
    }

    // Where the pair sits. Set from code after the Rows have laid out, never from a binding on the item's x: the
    // workspace list is rebuilt whenever a workspace comes or goes, and a fresh delegate reads x = 0 until its Row
    // lays it out, which would send the pair towards 0 for a frame. With no current workspace the pair keeps its
    // last place and fades.
    property real openX: 0
    property real closeX: 0
    function place() {
        const it = currentItem
        if (!it) return
        for (let i = 0; i < row.children.length; i++) row.children[i].forceLayout?.()
        row.forceLayout()
        openX = it.x
        closeX = it.x + it.width - closeBracket.width
    }

    onCurrentItemChanged: place()

    // No glide for the first placement (at start-up, or when the workspaces arrive): jump there, then let later
    // changes glide. Armed only after a real layout, so the jump lands on the final place, not on 0.
    property bool ready: false
    function settle() {
        place()
        if (currentItem && !ready) Qt.callLater(() => ready = true)
    }

    Row {
        id: row
        spacing: 2
        onPositioningComplete: root.settle()   // a workspace came or went, or a number changed width

        Repeater {
            model: Hyprland.workspaces.values
                .filter(ws => ws.id > 0 && ws.monitor === root.monitor)   // id < 0 are special workspaces
                .sort((a, b) => a.id - b.id)

            Row {
                id: item

                required property var modelData
                readonly property bool current: modelData.active   // shown on this monitor right now

                BarText { text: "["; opacity: 0 }   // spacer: the visible bracket is the travelling pair below
                BarText {
                    text: item.modelData.id
                    color: item.current ? Theme.barBright
                         : item.modelData.urgent ? Theme.barWarn
                         : hover.hovered ? Theme.barText
                         : Theme.barDim
                }
                BarText { text: "]"; opacity: 0 }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: item.modelData.activate() }
            }
        }
    }

    // The travelling pair, in the same place as the current workspace's spacers.
    BarText {
        x: root.openX
        text: "["
        color: Theme.barAccent
        opacity: root.currentItem ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        HighlightMotion on x { active: root.ready }
    }
    BarText {
        id: closeBracket
        x: root.closeX
        text: "]"
        color: Theme.barAccent
        opacity: root.currentItem ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        HighlightMotion on x { active: root.ready }
    }
}
