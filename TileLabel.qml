import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/** A tile's icon and label, muted, on one line. */
RowLayout {
    id: tileLabel
    required property var card
    property real largestSize: Appearance.font.pixelSize.smaller
    property bool centered: false

    visible: tileLabel.card.labelText.length > 0 || tileLabel.card.labelIcon.length > 0
    spacing: 4

    MaterialSymbol {
        visible: tileLabel.card.labelIcon.length > 0
        Layout.alignment: tileLabel.centered && !labelText.visible ? Qt.AlignHCenter : Qt.AlignLeft
        Layout.fillWidth: tileLabel.centered && !labelText.visible
        horizontalAlignment: Text.AlignHCenter
        text: tileLabel.card.labelIcon
        iconSize: tileLabel.largestSize
        color: tileLabel.card.mutedContentColor
    }
    ShrinkThenWrapText {
        id: labelText
        visible: tileLabel.card.labelText.length > 0
        Layout.fillWidth: true
        horizontalAlignment: tileLabel.centered ? Text.AlignHCenter : Text.AlignLeft
        largestSize: tileLabel.largestSize
        maxLines: 1
        text: tileLabel.card.labelText
        color: tileLabel.card.mutedContentColor
    }
}
