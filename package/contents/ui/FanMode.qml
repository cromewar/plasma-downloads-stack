import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// macOS-style fan: files arc up from the panel icon, newest nearest. The fan
// grows with the number of files up to a screen-based height cap, then scrolls.
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
    readonly property real gap: iconSize * 1.04

    // The shell anchors the popup's near edge to the panel icon, which for a
    // (floating) dock sits a little inside the panel — so keep the files clear of
    // it with an inset on the panel side.
    readonly property real panelInset: Math.round(iconSize * 0.6)
    readonly property real topSpace: up ? (pad + chipH + chipGap) : (pad + panelInset)
    readonly property real botSpace: up ? (pad + panelInset) : (pad + chipH + chipGap)
    readonly property real overhead: topSpace + botSpace

    // The fan grows with the number of files, but its height is capped to the
    // space on screen. Once the files no longer fit, the column scrolls instead
    // of shrinking, so it works for any count.
    readonly property real maxHeight: Math.max(iconSize * 4,
        (Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : 1000) * 0.82)
    readonly property real naturalContentH: n > 0 ? ((n - 1) * gap + iconSize) : iconSize
    readonly property real maxContentH: Math.max(iconSize * 2, maxHeight - overhead)
    readonly property bool needsScroll: naturalContentH > maxContentH
    readonly property real contentVisibleH: needsScroll ? maxContentH : naturalContentH

    property int hoveredIndex: -1

    implicitWidth: pad + labelW + gapToLabel + iconSize + curveAmount + pad
    implicitHeight: overhead + contentVisibleH

    function iconLeft(i) {
        return iconColStart + curveAmount * Math.pow(n > 1 ? i / (n - 1) : 0, 1.5);
    }
    // Vertical position of an icon within the scrolling content (0-based).
    function tileY(i) {
        if (up)
            return naturalContentH - iconSize - i * gap;   // i=0 (newest) at the bottom
        return i * gap;                                     // i=0 (newest) at the top
    }
    function itemScale(i) {
        return 1.0 - 0.10 * (n > 1 ? i / (n - 1) : 0);
    }

    // Keep the newest files in view when the fan (re)opens.
    onActiveChanged: if (active) resetScroll()
    function resetScroll() {
        flick.contentY = up ? Math.max(0, flick.contentHeight - flick.height) : 0;
    }

    // Click on empty space closes the fan
    MouseArea {
        anchors.fill: parent
        onClicked: fan.closeRequested()
    }

    // The scrolling column of files
    Flickable {
        id: flick
        visible: fan.n > 0
        x: 0
        y: fan.topSpace
        width: fan.implicitWidth
        height: fan.contentVisibleH
        contentWidth: width
        contentHeight: fan.naturalContentH
        clip: true
        // A press-drag inside the fan drags a file OUT, so don't flick on drag.
        // Scrolling is handled by the wheel/trackpad handler and the scrollbar.
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        Component.onCompleted: fan.resetScroll()

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
                targetY: fan.tileY(index)
                collapsedX: fan.iconLeft(0)
                collapsedY: fan.tileY(0)

                shown: fan.active
                stagger: Math.min(index, 14) * 24
                hovered: fan.hoveredIndex === index
                z: fan.hoveredIndex === index ? 100 : (fan.n - index)

                onEntered: fan.hoveredIndex = index
                onExited: if (fan.hoveredIndex === index) fan.hoveredIndex = -1
                onClicked: fan.openFile(fileUrl)
            }
        }

        QQC2.ScrollBar.vertical: HoverScrollBar {
            policy: fan.needsScroll ? QQC2.ScrollBar.AlwaysOn : QQC2.ScrollBar.AlwaysOff
        }
    }

    // Scroll with the mouse wheel or a two-finger trackpad gesture, from anywhere
    // over the fan (a Flickable alone misses the trackpad when the pointer is on a
    // draggable tile).
    WheelHandler {
        enabled: fan.needsScroll
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            var dy = event.pixelDelta.y;
            if (dy === 0)
                dy = event.angleDelta.y / 120 * (fan.gap * 0.7);
            var maxY = flick.contentHeight - flick.height;
            flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - dy));
        }
    }

    // "Open Downloads" / "Show all" chip, pinned at the far end of the fan
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
}
