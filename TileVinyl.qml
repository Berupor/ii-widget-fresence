import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property real mediaProgress: CardLayouts.mediaProgress(form.media, form.card.now)
    readonly property bool hasPosition: form.mediaProgress >= 0
    readonly property real progress: Math.max(0, form.mediaProgress)
    readonly property int turnDurationMs: 9000
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
        visible: form.hasPosition
        anchors.centerIn: parent
        implicitSize: Math.round(Math.min(form.width, form.height))
        lineWidth: Math.max(3, implicitSize * 0.06)
        colPrimary: form.card.contentColor
        colSecondary: ColorUtils.transparentize(form.card.contentColor, 0.75)
    }

    Item {
        id: cover
        anchors.centerIn: parent
        width: Math.round(Math.min(form.width, form.height) * 0.68)
        height: cover.width

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: cover.width
                height: cover.height
                radius: cover.width / 2
            }
        }

        PresenceArt {
            anchors.fill: parent
            source: form.media?.art_url ?? ""
            fallbackIcon: form.media?.kind === "video" ? "smart_display" : "music_note"
            playing: form.card.animating
        }

        RotationAnimation on rotation {
            running: form.media?.playing === true
            paused: running && !form.card.animating
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: form.turnDurationMs
        }
    }
}
