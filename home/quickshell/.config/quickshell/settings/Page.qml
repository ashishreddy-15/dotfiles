import QtQuick
import qs

// The body of one settings section: a column of rows that scrolls when it does not fit, and keeps the control that has
// the keyboard focus in view.
//   Page { SettingRow { ... } ListRow { ... } }
Flickable {
    id: root

    default property alias content: column.data

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    function owns(item) {
        for (let p = item; p; p = p.parent) if (p === root) return true
        return false
    }
    function ensureVisible(item) {
        const top = item.mapToItem(contentItem, 0, 0).y
        const bottom = top + item.height
        if (top < contentY) contentY = Math.max(0, top - 8)
        else if (bottom > contentY + height) contentY = Math.min(Math.max(0, contentHeight - height), bottom - height + 8)
    }

    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() {
            const f = root.Window.window?.activeFocusItem
            if (f && f !== root && root.owns(f)) root.ensureVisible(f)
        }
    }

    Column {
        id: column
        width: root.width
    }
}
