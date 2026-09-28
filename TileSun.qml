import qs.modules.common
import QtQuick
import QtQuick.Layouts

/** The sun on its arc, fill being the share of the day gone by. */
ColumnLayout {
    id: form
    required property var card
    readonly property bool titled: form.height >= 100
    spacing: 4

    TileLabel {
        visible: form.titled && (form.card.labelText.length > 0 || form.card.labelIcon.length > 0)
        Layout.fillWidth: true
        card: form.card
        centered: true
    }
    Canvas {
        id: arc
        objectName: "sunArc"
        Layout.fillWidth: true
        Layout.fillHeight: true
        readonly property real progress: form.card.hasData ? form.card.fill : 0
        readonly property color ink: form.card.contentColor
        onProgressChanged: arc.requestPaint()
        onInkChanged: arc.requestPaint()
        onCanvasSizeChanged: arc.requestPaint()

        onPaint: {
            const ctx = arc.getContext("2d");
            ctx.reset();
            const r = Math.min(arc.width / 2, arc.height) * 0.9;
            const cx = arc.width / 2;
            const base = arc.height;
            const track = Qt.rgba(arc.ink.r, arc.ink.g, arc.ink.b, 0.25);
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
            const angle = Math.PI * (1 - arc.progress);
            const sx = cx + r * Math.cos(angle);
            const sy = base - r * Math.sin(angle);
            ctx.fillStyle = track;
            ctx.beginPath();
            ctx.arc(sx, sy, r * 0.2, 0, 2 * Math.PI);
            ctx.fill();
            ctx.fillStyle = arc.ink;
            ctx.beginPath();
            ctx.arc(sx, sy, r * 0.12, 0, 2 * Math.PI);
            ctx.fill();
        }
    }
    ShrinkThenWrapText {
        visible: form.card.hasData && form.card.value?.text
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        largestSize: Appearance.font.pixelSize.smaller
        maxLines: 1
        text: form.card.value?.text ?? ""
        color: form.card.contentColor
    }
}
