pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import "ThumbHash.js" as ThumbHash

/** The card's own clip cropped to the tile shape: a muted loop while it is on screen, a tap turns its sound on and off. */
Item {
    id: form
    required property var card

    readonly property var clip: form.card.state?.clip
    readonly property real expiresAt: Date.parse(form.clip?.expires_at ?? "")

    Item {
        id: frame
        anchors.fill: parent

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: frame.width
                height: frame.height
                radius: form.card.shape === "circle" ? Math.min(width, height) / 2 : form.card.radius
            }
        }

        Rectangle {
            anchors.fill: parent
            color: form.card.tint
        }

        Image {
            anchors.fill: parent
            source: ThumbHash.dataUrl(form.clip?.thumbhash)
            fillMode: Image.PreserveAspectCrop
            smooth: true
            cache: false
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
        anchors.fill: frame
        enabled: video.status === Loader.Ready
        onClicked: video.item.toggleSound()
    }

    PresencePhoto.ExpiryBadge {
        visible: (form.card.widget.place.cols > 1 || form.card.widget.place.rows > 1) && !isNaN(form.expiresAt)
        expiresAt: form.expiresAt
        shape: form.card.shape
        tileInset: form.card.tileInset
    }
}
