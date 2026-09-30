import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** A record sliding out of its sleeve, the title and progress underneath. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property bool tracked: CardLayouts.mediaProgress(form.media, form.card.now) >= 0
    readonly property bool edge: form.card.fullBleed || form.card.edgeToEdge
    readonly property real pad: form.edge ? form.card.tileInset : 0
    readonly property real discShift: 0.42
    readonly property real textHeight: 48
    readonly property real tallMinHeight: 120
    readonly property bool vinylFallback: form.card.height < form.tallMinHeight || form.card.height < form.card.width
    readonly property real sleeveSide: Math.max(0, Math.min((form.width - 2 * form.pad) / (1 + form.discShift), form.height - 2 * form.pad - form.textHeight))

    Loader {
        anchors.fill: parent
        active: form.vinylFallback
        sourceComponent: TileVinyl {
            card: form.card
        }
    }

    ColumnLayout {
        visible: !form.vinylFallback
        anchors.fill: parent
        anchors.margins: form.pad
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: form.sleeveSide

            TileVinyl.Disc {
                x: form.sleeveSide * form.discShift
                width: form.sleeveSide
                height: form.sleeveSide
                card: form.card
                labelGlyph: false
            }

            PresenceArt {
                objectName: "sleeveArt"
                width: form.sleeveSide
                height: form.sleeveSide
                radius: 6
                color: form.card.artPlaceholder
                fallbackColor: form.card.artAccent
                source: form.media?.art_url ?? ""
                media: form.media
                playing: form.card.animating
            }
        }
        Item {
            Layout.fillHeight: true
        }
        MediaTitle {
            Layout.fillWidth: true
            card: form.card
            stateMark: !form.tracked
        }
        MediaTitle.Progress {
            Layout.fillWidth: true
            Layout.topMargin: 6
            visible: form.tracked
            card: form.card
        }
    }
}
