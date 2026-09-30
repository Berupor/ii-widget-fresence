import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: form
    required property var card
    spacing: 8

    readonly property real valueMaxSize: 22
    readonly property real labelBottomInset: 2

    Item {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: barValue.implicitHeight

        TileLabel {
            anchors.left: parent.left
            anchors.right: barValue.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: form.labelBottomInset
            card: form.card
        }
        ShrinkThenWrapText {
            id: barValue
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.min(implicitWidth, parent.width)
            largestSize: form.valueMaxSize
            maxLines: 1
            value: true
            animateChange: true
            text: form.card.shownValueText
            color: form.card.contentColor
        }
    }
    WaveBar {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        color: form.card.contentColor
        to: 1
        value: form.card.hasData ? form.card.fill : 0
        wavy: false
        animateWave: false
    }
}
