import qs.modules.common
import QtQuick
import QtQuick.Layouts

/** A stopwatch running from the moment, or counting down to it. */
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
            objectName: "timerValue"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: Math.max(Appearance.font.pixelSize.huge, Math.round(form.height * 0.4))
            maxLines: 1
            value: true
            text: {
                if (!form.hasTime)
                    return form.card.value?.text || "-";
                if (form.card.timeDirection === "")
                    return "-";
                return Fresence.stopwatchText(Math.abs(form.card.now - form.card.valueTimeMs));
            }
            color: form.card.contentColor
        }
    }
}
