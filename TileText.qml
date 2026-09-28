import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: form
    required property var card
    spacing: 4

    readonly property bool shaped: form.card.polygonMasked

    TileLabel {
        shown: !form.shaped
        Layout.fillWidth: true
        card: form.card
    }
    ShrinkThenWrapText {
        objectName: "textSubtext"
        visible: !form.shaped && form.card.labelText.length === 0 && form.card.subtext.length > 0
        Layout.fillWidth: true
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: form.card.subtext
        color: form.card.mutedContentColor
    }
    ShrinkThenWrapText {
        objectName: "textValue"
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalAlignment: form.shaped ? Text.AlignHCenter : Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        largestSize: form.shaped ? Appearance.font.pixelSize.larger : Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.3))
        animateChange: true
        text: form.card.shownValueText
        color: form.card.contentColor
    }
}
