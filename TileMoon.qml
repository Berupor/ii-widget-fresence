import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** The moon phase for the viewer's clock, with the lit share under it. */
ColumnLayout {
    id: form
    required property var card
    readonly property var phase: CardLayouts.moonPhase(Fresence.now)
    spacing: 4

    Canvas {
        id: disc
        objectName: "moonDisc"
        Layout.fillWidth: true
        Layout.fillHeight: true
        readonly property real lit: form.phase.illumination
        readonly property real litSide: form.phase.waxing ? 1 : -1
        readonly property color ink: form.card.contentColor
        property real drawnLit: disc.lit

        Behavior on drawnLit {
            NumberAnimation {
                duration: CardLayouts.fillAnimationMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: CardLayouts.fillEasing
            }
        }
        onDrawnLitChanged: disc.requestPaint()
        onLitSideChanged: disc.requestPaint()
        onInkChanged: disc.requestPaint()
        onCanvasSizeChanged: disc.requestPaint()

        onPaint: {
            const ctx = disc.getContext("2d");
            ctx.reset();
            const r = Math.min(disc.width, disc.height) * 0.4;
            const cx = disc.width / 2;
            const cy = disc.height / 2;
            ctx.fillStyle = Qt.rgba(disc.ink.r, disc.ink.g, disc.ink.b, 0.22);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fill();
            const steps = 48;
            ctx.fillStyle = disc.ink;
            ctx.beginPath();
            for (let i = 0; i <= steps; i++) {
                const a = -Math.PI / 2 + Math.PI * i / steps;
                const x = cx + disc.litSide * r * Math.cos(a);
                const y = cy + r * Math.sin(a);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            for (let i = steps; i >= 0; i--) {
                const a = -Math.PI / 2 + Math.PI * i / steps;
                ctx.lineTo(cx + disc.litSide * r * (1 - 2 * disc.drawnLit) * Math.cos(a), cy + r * Math.sin(a));
            }
            ctx.closePath();
            ctx.fill();
        }
    }
    ShrinkThenWrapText {
        objectName: "moonLit"
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: `${Math.round(form.phase.illumination * 100)}%`
        color: form.card.contentColor
    }
}
