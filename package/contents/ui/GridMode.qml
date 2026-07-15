import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// A tidy grid of thumbnails with names underneath.
Item {
    id: grid

    property var files: []
    property int extraCount: 0
    property int iconSize: 64
    property int columns: 3
    property string folderPath: ""
    property bool active: false

    signal openFile(var url)
    signal openFolder()
    signal closeRequested()

    readonly property int n: files.length
    readonly property int cols: Math.max(1, Math.min(columns, Math.max(1, n)))
    readonly property real cellW: Math.max(iconSize + Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 5.5)
    readonly property real cellH: iconSize + Kirigami.Units.gridUnit * 2.8
    readonly property int pad: Kirigami.Units.largeSpacing

    implicitWidth: Math.max(cols * cellW, header.implicitWidth) + pad * 2
    implicitHeight: header.height + (n > 0 ? Math.ceil(n / cols) * cellH : Kirigami.Units.gridUnit * 4) + pad * 2 + Kirigami.Units.smallSpacing

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: grid.pad
        spacing: Kirigami.Units.smallSpacing

        // Header: title + open-folder button
        RowLayout {
            id: header
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: "folder-download"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            Kirigami.Heading {
                level: 4
                text: i18n("Downloads")
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            PlasmaComponents.ToolButton {
                icon.name: "folder-open-symbolic"
                text: grid.extraCount > 0 ? i18n("Show all (%1)", grid.n + grid.extraCount) : i18n("Open folder")
                display: PlasmaComponents.AbstractButton.TextBesideIcon
                onClicked: grid.openFolder()
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        PlasmaComponents.Label {
            visible: grid.n === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: 0.7
            text: i18n("No recent downloads")
        }

        Grid {
            id: theGrid
            visible: grid.n > 0
            Layout.alignment: Qt.AlignHCenter
            columns: grid.cols
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: grid.files
                delegate: FileDragItem {
                    id: cell
                    required property int index
                    required property var modelData
                    width: grid.cellW
                    height: grid.cellH
                    fileUrl: modelData.url
                    fileName: modelData.name
                    isDir: modelData.isDir

                    opacity: grid.active ? 1.0 : 0.0
                    scale: grid.active ? 1.0 : 0.85
                    Behavior on opacity { SequentialAnimation {
                        PauseAnimation { duration: grid.active ? index * 20 : 0 }
                        NumberAnimation { duration: 160 }
                    } }
                    Behavior on scale { SequentialAnimation {
                        PauseAnimation { duration: grid.active ? index * 20 : 0 }
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    } }

                    onClicked: grid.openFile(modelData.url)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing / 2
                        radius: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.highlightColor
                        opacity: cell.hovered ? 0.18 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing
                        FileThumb {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: grid.iconSize
                            Layout.preferredHeight: grid.iconSize
                            fileName: modelData.name
                            fileUrl: modelData.url
                            isDir: modelData.isDir
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: modelData.name
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignTop
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            font: Kirigami.Theme.smallFont
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
