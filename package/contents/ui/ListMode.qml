import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "IconTools.js" as IconTools

// A compact list, one file per row with its icon, name and kind.
Item {
    id: list

    property var files: []
    property int extraCount: 0
    property int iconSize: 64
    property string folderPath: ""
    property bool active: false

    signal openFile(var url)
    signal openFolder()
    signal closeRequested()

    readonly property int n: files.length
    readonly property real rowIconSize: Math.min(iconSize, Kirigami.Units.iconSizes.medium)
    readonly property real rowH: rowIconSize + Kirigami.Units.smallSpacing * 3
    readonly property int pad: Kirigami.Units.largeSpacing
    readonly property real maxListH: rowH * 9

    implicitWidth: Kirigami.Units.gridUnit * 17
    implicitHeight: header.height + Kirigami.Units.smallSpacing
                    + (n > 0 ? Math.min(n * rowH, maxListH) : Kirigami.Units.gridUnit * 4)
                    + pad * 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: list.pad
        spacing: Kirigami.Units.smallSpacing

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
                text: list.extraCount > 0 ? i18n("Show all (%1)", list.n + list.extraCount) : i18n("Open folder")
                display: PlasmaComponents.AbstractButton.TextBesideIcon
                onClicked: list.openFolder()
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        PlasmaComponents.Label {
            visible: list.n === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: 0.7
            text: i18n("No recent downloads")
        }

        ListView {
            id: listView
            visible: list.n > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: list.files
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            reuseItems: true

            delegate: FileDragItem {
                id: row
                required property int index
                required property var modelData
                width: ListView.view.width
                height: list.rowH
                fileUrl: modelData.url
                fileName: modelData.name
                isDir: modelData.isDir

                opacity: list.active ? 1.0 : 0.0
                Behavior on opacity { SequentialAnimation {
                    PauseAnimation { duration: list.active ? Math.min(index, 12) * 18 : 0 }
                    NumberAnimation { duration: 150 }
                } }

                onClicked: list.openFile(modelData.url)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Kirigami.Units.smallSpacing
                    color: Kirigami.Theme.highlightColor
                    opacity: row.hovered ? 0.18 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    FileThumb {
                        Layout.preferredWidth: list.rowIconSize
                        Layout.preferredHeight: list.rowIconSize
                        Layout.alignment: Qt.AlignVCenter
                        fileName: modelData.name
                        fileUrl: modelData.url
                        isDir: modelData.isDir
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: modelData.name
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: i18n(IconTools.kindOf(modelData.name, modelData.isDir))
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            opacity: 0.65
                            font: Kirigami.Theme.smallFont
                        }
                    }
                    Kirigami.Icon {
                        source: "document-open-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.alignment: Qt.AlignVCenter
                        opacity: row.hovered ? 0.7 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                }
            }
        }
    }
}
