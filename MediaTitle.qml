import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/** Title and artist, or channel for a video, of what a media tile plays. */
ColumnLayout {
    id: title
    required property var card
    property int lines: 2
    property color color: title.card.contentColor
    property color subtleColor: title.card.mutedContentColor
    readonly property var media: title.card.media
    spacing: 1

    StyledText {
        objectName: "mediaTitle"
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: title.lines
        elide: Text.ElideRight
        textFormat: Text.PlainText
        font.pixelSize: Appearance.font.pixelSize.normal
        text: title.media?.title ?? ""
        color: title.color
    }
    StyledText {
        objectName: "mediaSubtitle"
        Layout.fillWidth: true
        visible: text.length > 0
        elide: Text.ElideRight
        textFormat: Text.PlainText
        font.pixelSize: Appearance.font.pixelSize.smaller
        text: title.media?.artist ?? ""
        color: title.subtleColor
    }
}
