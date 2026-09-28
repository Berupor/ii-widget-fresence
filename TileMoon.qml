import qs.modules.common
import QtQuick
import QtQuick.Layouts

/** The moon lit by fill, with the phase text under it. */
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
        id: disc
        objectName: "moonDisc"
        Layout.fillWidth: true
        Layout.fillHeight: true
        readonly property real lit: form.card.hasData ? form.card.fill : 0
        readonly property color ink: form.card.contentColor
        onLitChanged: disc.requestPaint()
        onInkChanged: disc.requestPaint()
        onCanvasSizeChanged: disc.requestPaint()

        onPaint: {
            const ctx = disc.getContext("2d");
            ctx.reset();
            const r = Math.min(disc.width, disc.height) * 0.4;
            const cx = disc.width / 2;
            const cy = disc.height / 2;
            ctx.fillStyle = Qt.rgba(disc.ink.r, disc.ink.g, disc.ink.b, 0.25);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fill();
            const steps = 48;
            ctx.fillStyle = disc.ink;
            ctx.beginPath();
            for (let i = 0; i <= steps; i++) {
                const a = -Math.PI / 2 + Math.PI * i / steps;
                const x = cx + r * Math.cos(a);
                const y = cy + r * Math.sin(a);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            for (let i = steps; i >= 0; i--) {
                const a = -Math.PI / 2 + Math.PI * i / steps;
                ctx.lineTo(cx + r * (1 - 2 * disc.lit) * Math.cos(a), cy + r * Math.sin(a));
            }
            ctx.closePath();
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
