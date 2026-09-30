import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    property string caption: form.card.labelText
    property string value: form.card.valueText
    readonly property real valueMaxSize: 40

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        ShrinkThenWrapText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.min(Appearance.font.pixelSize.smaller, Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.15)))
            text: form.caption
            color: form.card.mutedContentColor
        }
        ShrinkThenWrapText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: form.valueMaxSize
            maxLines: 1
            value: true
            animateChange: true
            text: form.card.hasData ? form.value : "-"
            color: form.card.contentColor
        }
    }
}
