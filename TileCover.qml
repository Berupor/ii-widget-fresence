import qs.modules.common
import QtQuick
import QtQuick.Layouts

/** Cover art: beside the title on a wide tile, under it on a tall one, alone on a small one. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property string fallbackIcon: form.media?.kind === "video" ? "smart_display" : "music_note"
    readonly property bool tall: !form.card.wide && form.height >= 100
    readonly property real artSide: form.card.wide ? Math.min(form.height, form.width * 0.42) : (form.tall ? Math.min(form.width, form.height - title.implicitHeight - 6) : Math.min(form.width, form.height))

    RowLayout {
        visible: form.card.wide
        anchors.fill: parent
        spacing: 10

        PresenceArt {
            Layout.preferredWidth: form.artSide
            Layout.preferredHeight: form.artSide
            Layout.alignment: Qt.AlignVCenter
            source: form.media?.art_url ?? ""
            fallbackIcon: form.fallbackIcon
            playing: form.card.animating
        }
        MediaTitle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            card: form.card
        }
    }

    ColumnLayout {
        visible: !form.card.wide
        anchors.fill: parent
        spacing: 6

        PresenceArt {
            Layout.preferredWidth: form.artSide
            Layout.preferredHeight: form.artSide
            Layout.alignment: Qt.AlignHCenter
            source: form.media?.art_url ?? ""
            fallbackIcon: form.fallbackIcon
            playing: form.card.animating
        }
        MediaTitle {
            id: title
            visible: form.tall
            Layout.fillWidth: true
            card: form.card
            lines: 1
        }
    }
}
