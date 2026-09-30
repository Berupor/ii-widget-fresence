import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

Item {
    id: form
    required property var card
    readonly property real progress: form.card.hasData ? form.card.fill : 0
    property real shown: form.progress

    Behavior on shown {
        NumberAnimation {
            duration: CardLayouts.fillAnimationMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: CardLayouts.fillEasing
        }
    }

    readonly property real diameter: Math.round(form.wide ? form.height : Math.min(form.width, form.height))
    readonly property bool wide: form.width > form.height * 1.5
    readonly property real innerFraction: 0.72
    readonly property real wideValueMaxSize: 22

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
                value: form.shown
                enableAnimation: false
                lineWidth: Math.max(3, implicitSize * 0.08)
                colPrimary: form.card.contentColor
                colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.78)

                readonly property real innerBox: (ring.implicitSize - 2 * ring.lineWidth) * form.innerFraction

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
