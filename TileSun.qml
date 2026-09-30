import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** The sun on its arc by the share of daylight gone by, with the next sunset or sunrise under it. */
ColumnLayout {
    id: form
    required property var card
    readonly property var daylight: CardLayouts.daylight(form.card.weather, Fresence.now)
    readonly property real roomyTile: 120
    readonly property bool titled: form.card.height >= form.roomyTile
    spacing: 4

    ShrinkThenWrapText {
        objectName: "sunPlace"
        visible: form.titled && text.length > 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: form.card.weather?.place ?? ""
        color: form.card.mutedContentColor
    }
    Canvas {
        id: arc
        objectName: "sunArc"
        Layout.fillWidth: true
        Layout.fillHeight: true
        readonly property real progress: form.daylight?.progress ?? 0
        readonly property bool shown: form.daylight !== null
        readonly property bool isDay: form.daylight?.isDay ?? false
        readonly property color ink: form.card.contentColor
        property real drawnProgress: arc.progress

        Behavior on drawnProgress {
            NumberAnimation {
                duration: CardLayouts.fillAnimationMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: CardLayouts.fillEasing
            }
        }
        onDrawnProgressChanged: arc.requestPaint()
        onShownChanged: arc.requestPaint()
        onIsDayChanged: arc.requestPaint()
        onInkChanged: arc.requestPaint()
        onCanvasSizeChanged: arc.requestPaint()

        onPaint: {
            const ctx = arc.getContext("2d");
            ctx.reset();
            const r = Math.min(arc.width / 2, arc.height) * 0.9;
            const cx = arc.width / 2;
            const base = arc.height;
            const track = Qt.rgba(arc.ink.r, arc.ink.g, arc.ink.b, 0.22);
            ctx.strokeStyle = track;
            ctx.lineWidth = Math.max(1, r * 0.05);
            ctx.setLineDash([r * 0.08 / ctx.lineWidth, r * 0.08 / ctx.lineWidth]);
            ctx.beginPath();
            ctx.arc(cx, base, r, Math.PI, 2 * Math.PI);
            ctx.stroke();
            ctx.setLineDash([]);
            ctx.lineWidth = Math.max(1, r * 0.03);
            ctx.beginPath();
            ctx.moveTo(0, base);
            ctx.lineTo(arc.width, base);
            ctx.stroke();
            if (!arc.shown)
                return;
            const angle = Math.PI * (1 - arc.drawnProgress);
            const sx = cx + r * Math.cos(angle);
            const sy = base - r * Math.sin(angle);
            ctx.fillStyle = track;
            ctx.beginPath();
            ctx.arc(sx, sy, r * 0.2, 0, 2 * Math.PI);
            ctx.fill();
            if (!arc.isDay)
                return;
            ctx.fillStyle = arc.ink;
            ctx.beginPath();
            ctx.arc(sx, sy, r * 0.12, 0, 2 * Math.PI);
            ctx.fill();
        }
    }
    ShrinkThenWrapText {
        objectName: "sunNext"
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: form.daylight ? Qt.formatTime(new Date(form.daylight.next), "HH:mm") : "-"
        color: form.card.contentColor
    }
}
