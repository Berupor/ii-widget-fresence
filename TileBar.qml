import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: form
    required property var card
    spacing: 4

    TileLabel {
        Layout.fillWidth: true
        card: form.card
    }
    ShrinkThenWrapText {
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.3))
        maxLines: 1
        animateChange: true
        text: form.card.shownValueText
        color: form.card.contentColor
    }
    WaveBar {
        Layout.fillWidth: true
        color: form.card.contentColor
        to: 1
        value: form.card.hasData ? form.card.fill : 0
        wavy: false
        animateWave: false
    }
}
