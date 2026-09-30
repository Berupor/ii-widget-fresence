import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Cover art: a band over the title on a tall tile, the player row on a wide one, a square with a state badge on a small one. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property bool tracked: CardLayouts.mediaProgress(form.media, form.card.now) >= 0
    readonly property bool edge: form.card.fullBleed || form.card.edgeToEdge
    readonly property real pad: form.edge ? form.card.tileInset : 0
    readonly property bool bleeds: form.edge && form.card.shape === "rounded"
    readonly property bool tall: !form.card.wide && form.card.height >= tallMinHeight
    readonly property bool square: !form.card.wide && !form.tall
    readonly property real tallMinHeight: 120
    readonly property real bandTextVertical: 8
    readonly property real badgeSize: 22
    readonly property real badgeMargin: 6
    readonly property real badgeAlpha: 0.45

    Loader {
        anchors.fill: parent
        active: form.card.wide
        sourceComponent: TilePlayer {
            card: form.card
        }
    }

    ColumnLayout {
        visible: form.tall
        anchors.fill: parent
        spacing: 0

        PresenceArt {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 0
            source: form.media?.art_url ?? ""
            media: form.media
            glyphSize: 44
            playing: form.card.animating
            color: form.card.artPlaceholder
            fallbackColor: form.card.artAccent
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: form.pad
            Layout.rightMargin: form.pad
            Layout.topMargin: form.bleeds ? form.bandTextVertical : form.pad
            Layout.bottomMargin: form.bleeds ? form.bandTextVertical : form.pad
            spacing: 6

            MediaTitle {
                Layout.fillWidth: true
                card: form.card
                stateMark: !form.tracked
            }
            MediaTitle.Progress {
                Layout.fillWidth: true
                visible: form.tracked
                card: form.card
            }
        }
    }

    PresenceArt {
        visible: form.square
        anchors.fill: parent
        radius: 0
        source: form.media?.art_url ?? ""
        media: form.media
        glyphSize: 32
        playing: form.card.animating
        color: form.card.artPlaceholder
        fallbackColor: form.card.artAccent
    }

    Rectangle {
        objectName: "coverBadge"
        visible: form.square
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: form.bleeds ? form.badgeMargin : form.pad
        width: form.badgeSize
        height: form.badgeSize
        radius: form.badgeSize / 2
        color: form.card.mediaTinted ? form.card.mediaPalette.fill : Qt.rgba(0, 0, 0, form.badgeAlpha)

        MediaTitle.StateMark {
            anchors.centerIn: parent
            playing: form.media?.playing === true
            color: form.card.mediaTinted ? form.card.mediaPalette.content : "white"
            equalizerHeight: 10
            pauseSize: 14
        }
    }
}
