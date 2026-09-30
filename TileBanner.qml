import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

/** Icon badge, label and a sentence beside it. */
RowLayout {
    id: form
    required property var card
    readonly property real badgeSize: Math.min(form.height, 32)
    readonly property real sentenceMaxSize: 20
    spacing: 8

    Rectangle {
        visible: form.card.icon.length > 0
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: form.badgeSize
        implicitHeight: form.badgeSize
        radius: form.badgeSize / 2
        color: ColorUtils.transparentize(form.card.contentColor, 0.88)

        MaterialSymbol {
            anchors.centerIn: parent
            text: form.card.icon
            iconSize: Math.round(form.badgeSize * 0.56)
            color: form.card.contentColor
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        ShrinkThenWrapText {
            Layout.fillWidth: true
            visible: text.length > 0
            largestSize: Appearance.font.pixelSize.smaller
            maxLines: 1
            text: form.card.labelText || form.card.subtext
            color: form.card.mutedContentColor
        }
        ShrinkThenWrapText {
            objectName: "bannerValue"
            Layout.fillWidth: true
            largestSize: form.sentenceMaxSize
            maxLines: 2
            animateChange: true
            text: form.card.shownValueText
            color: form.card.contentColor
        }
    }
}
