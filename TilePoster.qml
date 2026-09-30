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
    readonly property real glyphLift: 48
    readonly property real glyphSize: 48
    readonly property real tallMinHeight: 120
    readonly property bool coverFallback: form.card.height < form.tallMinHeight || form.card.height < form.card.width

    Loader {
        anchors.fill: parent
        active: form.coverFallback
        sourceComponent: TileCover {
            card: form.card
        }
    }

    PresenceArt {
        visible: !form.coverFallback
        anchors.fill: parent
        radius: 0
        color: form.card.artPlaceholder
        fallbackColor: form.card.artAccent
        fallbackLift: form.glyphLift
        glyphSize: form.glyphSize
        source: form.media?.art_url ?? ""
        media: form.media
        playing: form.card.animating
    }

    Rectangle {
        objectName: "posterChip"
        visible: !form.coverFallback
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
                color: form.chipContent
                subtleColor: Qt.alpha(form.chipContent, 0.65)
                stateMark: true
            }
        }
    }
}
