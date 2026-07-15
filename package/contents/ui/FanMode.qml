import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// macOS-style fan: files arc upward from the panel icon, newest nearest.
Item {
    id: fan

    property var files: []
    property int extraCount: 0
    property int iconSize: 64
    property string folderPath: ""
    property bool active: false      // drives the fan-out animation
    property bool up: true           // fan climbs up (false = descends)
    property bool labelsLeft: false

    signal openFile(var url)
    signal openFolder()
    signal closeRequested()

    readonly property int n: files.length
    readonly property real curveAmount: iconSize * 0.55
    readonly property int pad: 16
    readonly property int chipH: 30
    readonly property int chipGap: 14
    readonly property real gapToLabel: 10
    readonly property real labelW: iconSize * 3
    readonly property real iconColStart: labelsLeft ? (pad + labelW + gapToLabel) : pad

    // Spacing between successive icons. The fan grows with the number of files
    // but is capped to the space available on screen: past that point the icons
    // overlap more (smaller gap) so every file stays visible, like macOS.
    readonly property real overhead: pad * 2 + chipH + chipGap
    readonly property real maxHeight: (Screen.desktopAvailableHeight > 0
        ? Screen.desktopAvailableHeight : 1000) * 0.82
    readonly property real baseGap: iconSize * 1.04
    readonly property real gap: {
        if (n <= 1)
            return baseGap;
        var avail = Math.max(iconSize * 0.5, maxHeight - overhead - iconSize);
        var needed = (n - 1) * baseGap;
        return needed > avail ? (avail / (n - 1)) : baseGap;
    }

    property int hoveredIndex: -1

    implicitWidth: pad + labelW + gapToLabel + iconSize + curveAmount + pad
    implicitHeight: overhead + (n > 0 ? (n - 1) * gap + iconSize : iconSize)

    function iconLeft(i) {
        return iconColStart + curveAmount * Math.pow(n > 1 ? i / (n - 1) : 0, 1.5);
    }
    function iconTop(i) {
        if (up) {
            var topIconTop = pad + chipH + chipGap;
            return topIconTop + (n - 1 - i) * gap;   // i=0 (newest) at the bottom
        }
        return pad + i * gap;                         // i=0 (newest) at the top
    }
    function itemScale(i) {
        return 1.0 - 0.10 * (n > 1 ? i / (n - 1) : 0);
    }

    // Click on empty space closes the fan
    MouseArea {
        anchors.fill: parent
        onClicked: fan.closeRequested()
    }

    // "Open Downloads" / "Show all" chip at the far end of the fan
    MouseArea {
        id: chip
        z: 50
        width: chipRow.implicitWidth + 24
        height: fan.chipH
        x: Math.max(fan.pad, Math.min(fan.implicitWidth - fan.pad - width,
               fan.iconLeft(fan.up ? fan.n - 1 : 0) + fan.iconSize / 2 - width / 2))
        y: fan.up ? fan.pad : fan.implicitHeight - fan.pad - fan.chipH
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: fan.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onClicked: fan.openFolder()

        Kirigami.ShadowedRectangle {
            anchors.fill: parent
            radius: height / 2
            color: chip.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            shadow.size: 10
            shadow.color: Qt.rgba(0, 0, 0, 0.3)
            shadow.yOffset: 2
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Kirigami.Icon {
                source: "folder-download"
                width: Kirigami.Units.iconSizes.small
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }
            PlasmaComponents.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: fan.extraCount > 0
                    ? i18n("Show all %1 in Downloads", fan.n + fan.extraCount)
                    : i18n("Open Downloads")
                color: chip.containsMouse ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            }
        }
    }

    PlasmaComponents.Label {
        visible: fan.n === 0
        anchors.centerIn: parent
        opacity: 0.7
        text: i18n("No recent downloads")
    }

    Repeater {
        model: fan.files
        delegate: FileTile {
            required property int index
            required property var modelData

            iconSize: fan.iconSize
            fileName: modelData.name
            fileUrl: modelData.url
            isDir: modelData.isDir
            labelWidth: fan.labelW
            gapToLabel: fan.gapToLabel
            labelOnLeft: fan.labelsLeft
            tileScale: fan.itemScale(index)

            targetX: fan.iconLeft(index)
            targetY: fan.iconTop(index)
            collapsedX: fan.iconLeft(0)
            collapsedY: fan.iconTop(0)

            shown: fan.active
            stagger: index * 24
            hovered: fan.hoveredIndex === index
            z: fan.hoveredIndex === index ? 100 : (fan.n - index)

            onEntered: fan.hoveredIndex = index
            onExited: if (fan.hoveredIndex === index) fan.hoveredIndex = -1
            onClicked: fan.openFile(fileUrl)
        }
    }
}
