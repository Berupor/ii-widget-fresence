import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property real mediaProgress: CardLayouts.mediaProgress(form.media, form.card.now)
    readonly property bool hasPosition: form.mediaProgress >= 0
    readonly property real artSide: Math.min(form.height, form.width * 0.4)

    RowLayout {
        anchors.fill: parent
        spacing: 10

        PresenceArt {
            Layout.preferredWidth: form.artSide
            Layout.preferredHeight: form.artSide
            Layout.alignment: Qt.AlignVCenter
            source: form.media?.art_url ?? ""
            fallbackIcon: form.media?.kind === "video" ? "smart_display" : "music_note"
            playing: form.card.animating
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            MediaTitle {
                Layout.fillWidth: true
                card: form.card
                lines: 1
            }
            WaveBar {
                objectName: "waveProgress"
                Layout.fillWidth: true
                color: form.card.contentColor
                to: 1
                value: form.hasPosition ? form.mediaProgress : (form.media?.playing ? 1 : 0)
                wavy: form.media?.playing === true
                animateWave: form.card.animating && form.media?.playing === true
            }
        }
    }
}
