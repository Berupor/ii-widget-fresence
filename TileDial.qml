import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property real progress: form.card.hasData ? form.card.fill : 0
    readonly property real waveDepthFraction: 0.35
    readonly property real waveLengthFraction: 0.4
    readonly property real innerFraction: 0.72
    readonly property real wideValueMaxSize: 22
    readonly property int minWaves: 5
    readonly property bool wide: form.width > form.height * 1.5
    readonly property real diameter: Math.round(form.wide ? form.height : Math.min(form.width, form.height))

    Component.onCompleted: {
        dial.enableAnimation = false;
        dial.value = form.progress;
        dial.enableAnimation = true;
    }
    onProgressChanged: dial.value = form.progress

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: !form.wide
            Layout.preferredWidth: form.diameter
            Layout.preferredHeight: form.diameter

            WavyRing {
                id: dial
                anchors.centerIn: parent
                implicitSize: form.diameter
                lineWidth: Math.max(3, implicitSize * 0.08)
                waveAmplitude: dial.lineWidth * form.waveDepthFraction
                waveLength: 2 * Math.PI * dial.arcRadius / dial.waveCount
                colPrimary: form.card.contentColor
                colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.78)

                readonly property int waveCount: Math.max(form.minWaves, Math.round(2 * Math.PI * dial.arcRadius / (dial.implicitSize * form.waveLengthFraction)))
                readonly property real innerBox: (dial.implicitSize - 2 * dial.lineWidth) * form.innerFraction

                RingCenterText {
                    anchors.centerIn: parent
                    card: form.card
                    innerBox: dial.innerBox
                    showText: !form.wide
                }
            }
        }
        ColumnLayout {
            visible: form.wide
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            ShrinkThenWrapText {
                Layout.fillWidth: true
                visible: form.card.labelText.length > 0
                largestSize: Appearance.font.pixelSize.smaller
                maxLines: 1
                text: form.card.labelText
                color: form.card.mutedContentColor
            }
            ShrinkThenWrapText {
                objectName: "wideDialValue"
                Layout.fillWidth: true
                largestSize: form.wideValueMaxSize
                maxLines: 1
                value: true
                animateChange: true
                text: form.card.shownValueText
                color: form.card.contentColor
            }
        }
    }
}
