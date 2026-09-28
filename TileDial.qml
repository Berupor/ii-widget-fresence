import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: form
    required property var card
    readonly property real progress: form.card.hasData ? form.card.fill : 0
    readonly property real smallestAnimatedStep: 0.05
    readonly property real waveDepthFraction: 0.35
    readonly property real waveLengthFraction: 0.4
    readonly property int minWaves: 5

    function showProgress(): void {
        dial.enableAnimation = Math.abs(form.progress - dial.value) >= form.smallestAnimatedStep;
        dial.value = form.progress;
    }
    onProgressChanged: form.showProgress()
    Component.onCompleted: {
        dial.enableAnimation = false;
        dial.value = form.progress;
    }

    WavyRing {
        id: dial
        anchors.centerIn: parent
        implicitSize: Math.round(Math.min(form.width, form.height))
        lineWidth: Math.max(3, implicitSize * 0.08)
        waveAmplitude: dial.lineWidth * form.waveDepthFraction
        waveLength: 2 * Math.PI * dial.baseRadius / dial.waveCount
        colPrimary: form.card.contentColor
        colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)
        animateWave: form.card.animating

        readonly property real baseRadius: dial.implicitSize / 2 - dial.lineWidth - dial.waveAmplitude
        readonly property int waveCount: Math.max(form.minWaves, Math.round(2 * Math.PI * dial.baseRadius / (dial.implicitSize * form.waveLengthFraction)))
        readonly property real innerBox: 2 * dial.arcRadius * Math.SQRT1_2

        RingCenterText {
            anchors.centerIn: parent
            card: form.card
            innerBox: dial.innerBox
        }
    }
}
