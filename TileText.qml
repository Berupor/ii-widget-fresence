import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: form
    required property var card
    spacing: 8

    readonly property bool shaped: form.card.polygonMasked
    readonly property bool labeled: !form.shaped && form.card.labelText.length > 0
    readonly property bool anchored: form.labeled || form.shaped
    readonly property real sentenceMaxSize: 20
    readonly property real shapedSentenceMaxSize: 16
    readonly property real badgeSize: 32
    readonly property real badgeAlpha: 0.12
    readonly property real badgeIconSize: 18

    Rectangle {
        visible: !form.anchored && form.card.icon.length > 0
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: form.badgeSize
        implicitHeight: form.badgeSize
        radius: form.badgeSize / 2
        color: ColorUtils.applyAlpha(form.card.contentColor, form.badgeAlpha)

        MaterialSymbol {
            anchors.centerIn: parent
            text: form.card.icon
            iconSize: form.badgeIconSize
            color: form.card.contentColor
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: form.anchored
        Layout.alignment: Qt.AlignVCenter
        spacing: form.labeled ? 4 : 1

        TileLabel {
            shown: form.labeled
            Layout.fillWidth: true
            card: form.card
        }
        ShrinkThenWrapText {
            objectName: "textSubtext"
            visible: !form.anchored && form.card.subtext.length > 0
            Layout.fillWidth: true
            largestSize: Appearance.font.pixelSize.smaller
            maxLines: 1
            text: form.card.subtext
            color: form.card.mutedContentColor
        }
        ShrinkThenWrapText {
            objectName: "textValue"
            value: true
            Layout.fillWidth: true
            Layout.fillHeight: form.anchored
            horizontalAlignment: form.shaped ? Text.AlignHCenter : Text.AlignLeft
            verticalAlignment: form.shaped ? Text.AlignVCenter : form.labeled ? Text.AlignBottom : Text.AlignVCenter
            largestSize: form.shaped ? form.shapedSentenceMaxSize : form.sentenceMaxSize
            animateChange: true
            text: form.card.shownValueText
            color: form.card.contentColor
        }
    }
}
