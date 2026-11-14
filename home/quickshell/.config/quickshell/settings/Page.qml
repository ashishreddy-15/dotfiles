import QtQuick
import qs

// The body of one settings section: a column of rows that scrolls when it does not fit.
//   Page { SettingRow { ... } ListRow { ... } }
Flickable {
    id: root

    default property alias content: column.data

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
        id: column
        width: root.width
    }
}
