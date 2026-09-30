import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: form
    required property var card
    spacing: 2
    readonly property real valueMaxSize: 40

    TileLabel {
        Layout.fillWidth: true
        card: form.card
        centered: true
        largestSize: Appearance.font.pixelSize.smallest
    }
    ShrinkThenWrapText {
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        largestSize: form.valueMaxSize
        maxLines: 1
        value: true
        animateChange: true
        text: form.card.shownValueText
        color: form.card.contentColor
    }
}
