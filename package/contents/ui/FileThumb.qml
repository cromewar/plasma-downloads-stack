import QtQuick
import org.kde.kirigami as Kirigami
import "IconTools.js" as IconTools

// Renders a file as a real image thumbnail when it is an image,
// otherwise as a mime-type icon from the current icon theme.
Item {
    id: thumb

    property string fileName: ""
    property var fileUrl: ""
    property bool isDir: false

    readonly property bool isImage: !isDir && IconTools.isImage(fileName)

    Loader {
        anchors.fill: parent
        sourceComponent: thumb.isImage ? imageComponent : iconComponent
    }

    Component {
        id: iconComponent
        Kirigami.Icon {
            source: IconTools.iconName(thumb.fileName, thumb.isDir)
            active: false
        }
    }

    Component {
        id: imageComponent
        Item {
            Image {
                id: img
                anchors.fill: parent
                source: thumb.fileUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                autoTransform: true
                sourceSize.width: 256
                sourceSize.height: 256
                visible: status === Image.Ready
            }
            // Fallback to a generic image icon while loading or on error
            Kirigami.Icon {
                anchors.fill: parent
                source: "image-x-generic"
                visible: img.status !== Image.Ready
                active: false
            }
        }
    }
}
