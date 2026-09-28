import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: form
    required property var card
    readonly property real progress: form.card.hasData ? form.card.fill : 0
    readonly property real smallestAnimatedStep: 0.05

    function showProgress(): void {
        ring.enableAnimation = Math.abs(form.progress - ring.value) >= form.smallestAnimatedStep;
        ring.value = form.progress;
    }
    onProgressChanged: form.showProgress()
    Component.onCompleted: {
        ring.enableAnimation = false;
        ring.value = form.progress;
    }

    readonly property real diameter: Math.round(form.wide ? form.height : Math.min(form.width, form.height))
    readonly property bool wide: form.width > form.height * 1.5

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: !form.wide
            Layout.preferredWidth: form.diameter
            Layout.preferredHeight: form.diameter

            CircularProgress {
                id: ring
                anchors.centerIn: parent
                implicitSize: form.diameter
                lineWidth: Math.max(3, implicitSize * 0.08)
                colPrimary: form.card.contentColor
                colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)

                readonly property real innerBox: (ring.implicitSize - 2 * ring.lineWidth) * Math.SQRT1_2

                RingCenterText {
                    anchors.centerIn: parent
                    card: form.card
                    icon: form.card.ringIcon
                    innerBox: ring.innerBox
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
                objectName: "wideRingValue"
                Layout.fillWidth: true
                largestSize: Math.max(Appearance.font.pixelSize.large, Math.round(form.height * 0.3))
                maxLines: 1
                animateChange: true
                text: form.card.shownValueText
                color: form.card.contentColor
            }
        }
    }
}
