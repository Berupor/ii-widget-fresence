import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Cover art over the whole tile with the title on a chip along the bottom. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property bool tinted: form.card.mediaTinted
    readonly property color chipColor: form.tinted ? form.card.mediaPalette.fill : Qt.rgba(0, 0, 0, 0.45)
    readonly property color chipContent: form.tinted ? form.card.mediaPalette.content : "white"
    readonly property real chipMargin: form.card.shape === "rounded" ? 6 : CardLayouts.tileInset(form.card.width, form.card.height, form.card.shape)
    readonly property real glyphLift: 24

    PresenceArt {
        anchors.fill: parent
        radius: 0
        color: form.card.artPlaceholder
        fallbackColor: form.card.artAccent
        fallbackLift: form.glyphLift
        source: form.media?.art_url ?? ""
        fallbackIcon: form.media?.kind === "video" ? "smart_display" : "music_note"
        playing: form.card.animating
    }

    Rectangle {
        objectName: "posterChip"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: form.chipMargin
        width: parent.width - 2 * form.chipMargin
        height: chipRow.implicitHeight + 14
        radius: 12
        color: form.chipColor

        RowLayout {
            id: chipRow
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            MediaTitle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                card: form.card
                lines: 1
                color: form.chipContent
                subtleColor: Qt.alpha(form.chipContent, 0.65)
            }
            Row {
                objectName: "posterEqualizer"
                visible: form.media?.playing === true
                Layout.alignment: Qt.AlignVCenter
                height: 12
                spacing: 2

                Repeater {
                    model: [0.55, 1, 0.7]

                    Rectangle {
                        required property real modelData
                        anchors.bottom: parent.bottom
                        width: 3
                        height: 12 * modelData
                        radius: width / 2
                        color: form.chipContent
                    }
                }
            }
            MaterialSymbol {
                visible: form.media?.playing !== true
                Layout.alignment: Qt.AlignVCenter
                iconSize: 16
                color: form.chipContent
                text: "pause"
            }
        }
    }
}
