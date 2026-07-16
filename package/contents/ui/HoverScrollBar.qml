import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// A modern overlay scrollbar: hidden by default, it fades in while you scroll
// or when the pointer is near it, then fades back out. Draggable like any
// window scrollbar. Attach as `QQC2.ScrollBar.vertical: HoverScrollBar { ... }`.
QQC2.ScrollBar {
    id: control
    interactive: true
    // A slightly wide hit area so "near the bar" reveals it (the handle drawn
    // inside stays thin); the area is hoverable even while fully transparent.
    implicitWidth: 14

    // Reveal briefly on any position change — covers wheel/trackpad scrolling
    // (which moves contentY directly) and dragging the handle.
    property bool scrolling: false
    onPositionChanged: { scrolling = true; hideTimer.restart(); }
    Timer { id: hideTimer; interval: 1200; onTriggered: control.scrolling = false }

    readonly property bool reveal: hovered || pressed || scrolling

    contentItem: Item {
        implicitWidth: 14
        Rectangle {
            width: 7
            height: parent.height
            anchors.right: parent.right
            radius: width / 2
            color: control.pressed ? Kirigami.Theme.highlightColor
                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                          control.hovered ? 0.75 : 0.5)
            opacity: control.reveal ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
    background: Item {
        implicitWidth: 14
        Rectangle {
            width: 7
            height: parent.height
            anchors.right: parent.right
            radius: width / 2
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)
            opacity: control.reveal ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
}
