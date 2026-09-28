import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

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

    CircularProgress {
        id: ring
        anchors.centerIn: parent
        implicitSize: Math.round(Math.min(form.width, form.height))
        lineWidth: Math.max(3, implicitSize * 0.08)
        colPrimary: form.card.contentColor
        colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)

        readonly property real innerBox: (ring.implicitSize - 2 * ring.lineWidth) * Math.SQRT1_2

        RingCenterText {
            anchors.centerIn: parent
            card: form.card
            innerBox: ring.innerBox
        }
    }
}
