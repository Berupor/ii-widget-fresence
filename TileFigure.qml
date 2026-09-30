import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Load as a picture of the part that fills up, by app/shared ui/card/Gauges.kt FigureForm. */
Item {
    id: form
    required property var card
    readonly property string figure: CardLayouts.figureOf(form.card.widget?.source)
    readonly property bool wide: form.width > form.height * 1.5
    readonly property real progress: form.card.hasData ? form.card.fill : 0
    readonly property var aspects: ({
            "chip": 1,
            "stick": 2.6,
            "drive": 1.3,
            "battery": 2
        })
    readonly property real aspect: form.aspects[form.figure] ?? 1
    readonly property real wideFigureHeight: form.height * 0.8
    readonly property real wideValueMaxSize: 22
    readonly property real compactValueMaxSize: 14
    readonly property real trackAlpha: 0.22
    readonly property real pinAlpha: 0.5
    property real shown: form.progress

    Behavior on shown {
        NumberAnimation {
            duration: CardLayouts.fillAnimationMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: CardLayouts.fillEasing
        }
    }

    readonly property color ink: form.card.contentColor

    function repaint(): void {
        figureCanvas.requestPaint();
        compactCanvas.requestPaint();
    }

    onShownChanged: form.repaint()
    onFigureChanged: form.repaint()
    onInkChanged: form.repaint()

    function inkAt(alpha: real): color {
        return Qt.rgba(form.ink.r, form.ink.g, form.ink.b, form.ink.a * alpha);
    }

    function body(ctx, x, y, w, h, radius, upward): void {
        ctx.fillStyle = form.inkAt(form.trackAlpha);
        ctx.beginPath();
        ctx.roundedRect(x, y, w, h, radius, radius);
        ctx.fill();
        ctx.save();
        ctx.beginPath();
        if (upward)
            ctx.rect(x, y + h * (1 - form.shown), w, h * form.shown);
        else
            ctx.rect(x, y, w * form.shown, h);
        ctx.clip();
        ctx.fillStyle = form.inkAt(1);
        ctx.beginPath();
        ctx.roundedRect(x, y, w, h, radius, radius);
        ctx.fill();
        ctx.restore();
    }

    function pin(ctx, x, y, w, h): void {
        ctx.fillStyle = form.inkAt(form.pinAlpha);
        ctx.fillRect(x, y, w, h);
    }

    function drawChip(ctx, ox, oy, side): void {
        const pinSize = side * 0.1;
        const core = side - pinSize * 2;
        const cx = ox + pinSize;
        const cy = oy + pinSize;
        for (let i = 1; i <= 4; i++) {
            const along = core * i / 5 - pinSize * 0.35;
            form.pin(ctx, cx + along, oy, pinSize * 0.7, pinSize);
            form.pin(ctx, cx + along, cy + core, pinSize * 0.7, pinSize);
            form.pin(ctx, ox, cy + along, pinSize, pinSize * 0.7);
            form.pin(ctx, cx + core, cy + along, pinSize, pinSize * 0.7);
        }
        form.body(ctx, cx, cy, core, core, core * 0.14, true);
    }

    function drawStick(ctx, ox, oy, w, h): void {
        const boardHeight = h * 0.78;
        form.body(ctx, ox, oy, w, boardHeight, boardHeight * 0.12, false);
        const pins = 12;
        const pitch = w / pins;
        const notch = Math.floor(pins * 2 / 3);
        for (let i = 0; i < pins; i++) {
            if (i !== notch)
                form.pin(ctx, ox + pitch * (i + 0.2), oy + boardHeight + h * 0.06, pitch * 0.6, h * 0.16);
        }
    }

    function drawDrive(ctx, ox, oy, w, h): void {
        form.body(ctx, ox, oy, w, h, h * 0.12, true);
        ctx.save();
        ctx.globalCompositeOperation = "destination-out";
        ctx.fillStyle = "black";
        ctx.fillRect(ox, oy + h * 0.62, w, h * 0.07);
        ctx.beginPath();
        ctx.arc(ox + w * 0.8, oy + h * 0.82, h * 0.07, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();
    }

    function drawBattery(ctx, ox, oy, w, h): void {
        const nub = w * 0.07;
        form.body(ctx, ox, oy, w - nub, h, h * 0.18, false);
        const nubHeight = h * 0.4;
        ctx.fillStyle = form.inkAt(form.pinAlpha);
        ctx.beginPath();
        ctx.roundedRect(ox + w - nub * 0.8, oy + (h - nubHeight) / 2, nub * 0.8, nubHeight, nub * 0.3, nub * 0.3);
        ctx.fill();
    }

    function paint(ctx, width, height): void {
        ctx.clearRect(0, 0, width, height);
        const w = Math.min(width, height * form.aspect);
        const h = w / form.aspect;
        const ox = (width - w) / 2;
        const oy = (height - h) / 2;
        switch (form.figure) {
        case "chip":
            form.drawChip(ctx, ox, oy, w);
            break;
        case "stick":
            form.drawStick(ctx, ox, oy, w, h);
            break;
        case "drive":
            form.drawDrive(ctx, ox, oy, w, h);
            break;
        case "battery":
            form.drawBattery(ctx, ox, oy, w, h);
            break;
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: form.wide
        spacing: 12

        Canvas {
            id: figureCanvas
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(form.wideFigureHeight * form.aspect, form.width / 2)
            Layout.preferredHeight: form.wideFigureHeight
            onPaint: form.paint(getContext("2d"), width, height)
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
        ColumnLayout {
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
                objectName: "figureValue"
                Layout.fillWidth: true
                largestSize: form.wideValueMaxSize
                maxLines: 1
                animateChange: true
                text: form.card.shownValueText
                color: form.card.contentColor
            }
            ShrinkThenWrapText {
                Layout.fillWidth: true
                visible: form.card.subtext.length > 0
                largestSize: Appearance.font.pixelSize.smaller
                maxLines: 1
                text: form.card.subtext
                color: form.card.mutedContentColor
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: !form.wide
        spacing: 4

        Canvas {
            id: compactCanvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            onPaint: form.paint(getContext("2d"), width, height)
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
        ShrinkThenWrapText {
            objectName: "figureCompact"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            largestSize: form.compactValueMaxSize
            minSize: 10
            maxLines: 1
            value: true
            text: form.card.shortValueText
            color: form.card.contentColor
        }
    }
}
