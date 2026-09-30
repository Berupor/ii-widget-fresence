import qs.modules.common
import QtQuick
import QtQuick.Layouts

/** The moment in local HH:MM, and how far it is from now. */
Item {
    id: form
    required property var card
    readonly property bool hasTime: !isNaN(form.card.valueTimeMs)
    readonly property bool labeled: form.card.labelText.length > 0
    readonly property bool tall: (form.card.widget?.place?.rows ?? 1) > 1
    readonly property real captionSize: 11

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        spacing: 2

        TileLabel {
            shown: form.labeled || form.tall || !form.hasTime
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
            value: true
            animateChange: true
            text: form.hasTime ? Fresence.clockText(form.card.valueTimeMs) : (form.card.value?.text || "-")
            color: form.card.contentColor
        }
        ShrinkThenWrapText {
            objectName: "clockDistance"
            Layout.fillWidth: true
            visible: form.hasTime && form.card.timeDirection !== "" && !(form.labeled && !form.tall)
            horizontalAlignment: Text.AlignHCenter
            largestSize: form.captionSize
            maxLines: 1
            text: !visible ? "" : form.card.timeDirection === "until" ? Fresence.inText(form.card.valueTimeMs) : Fresence.agoText(form.card.valueTimeMs)
            color: form.card.mutedContentColor
        }
    }
}
