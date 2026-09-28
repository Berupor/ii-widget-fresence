import qs.modules.common
import QtQuick
import QtQuick.Layouts

/** The moment in local HH:MM, and how far it is from now. */
Item {
    id: form
    required property var card
    readonly property bool hasTime: !isNaN(form.card.valueTimeMs)

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        TileLabel {
            Layout.fillWidth: true
            card: form.card
            centered: true
            largestSize: Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.15))
        }
        ShrinkThenWrapText {
            objectName: "clockValue"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.4))
            maxLines: form.hasTime ? 1 : 2
            animateChange: true
            text: form.hasTime ? Fresence.clockText(form.card.valueTimeMs) : (form.card.value?.text || "-")
            color: form.card.contentColor
        }
        ShrinkThenWrapText {
            objectName: "clockDistance"
            Layout.fillWidth: true
            visible: form.hasTime && form.card.timeDirection !== ""
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.14))
            maxLines: 1
            text: !visible ? "" : form.card.timeDirection === "until" ? Fresence.inText(form.card.valueTimeMs) : Fresence.agoText(form.card.valueTimeMs)
            color: form.card.mutedContentColor
        }
    }
}
