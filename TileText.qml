import qs.modules.common
import qs.modules.common.widgets
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
        objectName: "textValue"
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.3))
        animateChange: true
        text: form.card.shownValueText
        color: form.card.contentColor
    }
}
