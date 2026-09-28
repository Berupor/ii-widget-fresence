pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick

/** The card's own circle: a muted loop while it is on screen, a tap restarts it with sound. */
Item {
    id: form
    required property var card

    readonly property real diameter: Math.min(form.width, form.height)

    Item {
        id: circle
        anchors.centerIn: parent
        width: form.diameter
        height: form.diameter

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: circle.width
                height: circle.height
                radius: width / 2
            }
        }

        Rectangle {
            anchors.fill: parent
            color: form.card.tint
        }

        Loader {
            id: video
            anchors.fill: parent

            function load(): void {
                video.setSource(Qt.resolvedUrl("TileClipVideo.qml"), {
                    "card": form.card
                });
            }

            Component.onCompleted: video.load()
        }
    }

    MouseArea {
        anchors.fill: circle
        enabled: video.status === Loader.Ready
        onClicked: video.item.replay()
    }
}
