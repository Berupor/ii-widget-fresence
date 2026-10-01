import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Ring form of cpu, memory and disk, by app/shared ui/card/LoadTile.kt LoadForm. */
Item {
    id: form
    required property var card

    readonly property bool wide: form.width > form.height * 1.5
    readonly property string source: form.card.widget?.source ?? ""
    readonly property string figure: ({
            "cpu": "chip",
            "memory": "stick",
            "disk": "drive"
        })[form.source] ?? ""
    readonly property var value: form.card.hasData ? form.card.value : null
    readonly property bool hasFill: form.value?.fill !== undefined
    readonly property real progress: form.hasFill ? Math.max(0, Math.min(1, form.value.fill)) : 0
    readonly property string percentText: form.hasFill ? `${Math.round(form.value.fill * 100)}%` : "-"
    readonly property string customIcon: form.card.icon
    readonly property var cores: form.value?.parts ?? []
    readonly property real usedBytes: form.value?.used_bytes ?? -1
    readonly property real totalBytes: form.value?.total_bytes ?? -1
    readonly property bool hasBytes: form.usedBytes >= 0 && form.totalBytes > 0
    readonly property string sourceName: ({
            "cpu": Translation.tr("CPU"),
            "memory": Translation.tr("Memory"),
            "disk": Translation.tr("Disk")
        })[form.source] ?? form.source
    property real shown: form.progress

    readonly property real trackAlpha: 0.22
    readonly property real pinAlpha: 0.5
    readonly property real strokeFraction: 0.09
    readonly property real valueFraction: 0.62
    readonly property real valueLift: 0.04
    readonly property real gapWidthFraction: 0.46
    readonly property real gapHeightFraction: 0.3
    readonly property real sideGap: 10
    readonly property int maxBars: 16
    readonly property real barsHeight: 20
    readonly property real barMaxWidth: 8
    readonly property real barGap: 3
    readonly property real barGapShare: 0.3
    readonly property real amountMaxSize: 16
    readonly property int dimmPins: 8
    readonly property int dimmNotch: 5
    readonly property real startAngle: 135 * Math.PI / 180
    readonly property real sweepAngle: 270 * Math.PI / 180

    Behavior on shown {
        NumberAnimation {
            duration: CardLayouts.fillAnimationMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: CardLayouts.fillEasing
        }
    }

    function inkAt(alpha: real): color {
        return Qt.rgba(form.card.contentColor.r, form.card.contentColor.g, form.card.contentColor.b, form.card.contentColor.a * alpha);
    }

    function byteSize(bytes: real): string {
        const tera = bytes >= CardLayouts.bytesPerTiB;
        return `${CardLayouts.amount(bytes, tera ? CardLayouts.bytesPerTiB : CardLayouts.bytesPerGiB)} ${tera ? "TB" : "GB"}`;
    }

    function coresText(count: int): string {
        if (Translation.languageCode.startsWith("ru")) {
            const tens = count % 100;
            const ones = count % 10;
            const word = tens >= 11 && tens <= 14 ? "ядер" : ones === 1 ? "ядро" : ones >= 2 && ones <= 4 ? "ядра" : "ядер";
            return `${count} ${word}`;
        }
        return count === 1 ? Translation.tr("%1 core").arg(count) : Translation.tr("%1 cores").arg(count);
    }

    function peaks(levels: var, most: int): var {
        if (levels.length <= most)
            return levels;
        const group = Math.ceil(levels.length / most);
        const out = [];
        for (let i = 0; i < levels.length; i += group)
            out.push(Math.max(...levels.slice(i, i + group)));
        return out;
    }

    function otherText(): string {
        const text = form.value?.text ?? "";
        return text !== "" && text !== form.percentText ? text : "";
    }

    function fillRoundRect(ctx, x, y, w, h, radius): void {
        ctx.beginPath();
        ctx.roundedRect(x, y, w, h, radius, radius);
        ctx.fill();
    }

    function drawChip(ctx, ox, oy, side): void {
        const pin = side * 0.1;
        const core = side - pin * 2;
        const cx = ox + pin;
        const cy = oy + pin;
        ctx.fillStyle = form.inkAt(form.pinAlpha);
        for (let i = 1; i <= 4; i++) {
            const along = core * i / 5 - pin * 0.35;
            ctx.fillRect(cx + along, oy, pin * 0.7, pin);
            ctx.fillRect(cx + along, cy + core, pin * 0.7, pin);
            ctx.fillRect(ox, cy + along, pin, pin * 0.7);
            ctx.fillRect(cx + core, cy + along, pin, pin * 0.7);
        }
        ctx.fillStyle = form.inkAt(1);
        form.fillRoundRect(ctx, cx, cy, core, core, core * 0.14);
    }

    function drawDrive(ctx, ox, oy, w, h): void {
        ctx.fillStyle = form.inkAt(1);
        form.fillRoundRect(ctx, ox, oy, w, h, h * 0.12);
        ctx.save();
        ctx.globalCompositeOperation = "destination-out";
        ctx.fillStyle = "black";
        ctx.fillRect(ox, oy + h * 0.62, w, h * 0.07);
        ctx.beginPath();
        ctx.arc(ox + w * 0.8, oy + h * 0.82, h * 0.07, 0, 2 * Math.PI);
        ctx.fill();
        ctx.restore();
    }

    function drawDimm(ctx, width, height): void {
        const w = Math.min(width, height * 2);
        const h = w / 2;
        const left = (width - w) / 2;
        const top = (height - h) / 2;
        const board = h * 0.64;
        ctx.fillStyle = form.inkAt(1);
        form.fillRoundRect(ctx, left, top, w, board, h * 0.1);
        const chip = board * 0.5;
        const chipGap = (w - chip * 3) / 4;
        ctx.save();
        ctx.globalCompositeOperation = "destination-out";
        ctx.fillStyle = "black";
        for (let i = 0; i < 3; i++)
            ctx.fillRect(left + chipGap + i * (chip + chipGap), top + (board - chip) / 2, chip, chip);
        ctx.restore();
        ctx.fillStyle = form.inkAt(1);
        const pitch = w / form.dimmPins;
        for (let i = 0; i < form.dimmPins; i++) {
            if (i !== form.dimmNotch)
                ctx.fillRect(left + pitch * (i + 0.2), top + board + h * 0.08, pitch * 0.6, h * 0.28);
        }
    }

    function drawPictogram(ctx, width, height): void {
        ctx.clearRect(0, 0, width, height);
        if (form.figure === "stick") {
            form.drawDimm(ctx, width, height);
        } else if (form.figure === "chip") {
            const side = Math.min(width, height);
            form.drawChip(ctx, (width - side) / 2, (height - side) / 2, side);
        } else if (form.figure === "drive") {
            const w = Math.min(width, height * 1.3);
            const h = w / 1.3;
            form.drawDrive(ctx, (width - w) / 2, (height - h) / 2, w, h);
        }
    }

    component Pictogram: Item {
        id: glyph
        MaterialSymbol {
            anchors.centerIn: parent
            visible: form.customIcon.length > 0
            text: form.customIcon
            iconSize: glyph.height
            color: form.card.contentColor
        }
        Canvas {
            id: glyphCanvas
            anchors.fill: parent
            visible: form.customIcon.length === 0
            onPaint: form.drawPictogram(getContext("2d"), width, height)
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: form.card
                function onContentColorChanged() {
                    glyphCanvas.requestPaint();
                }
            }
            Connections {
                target: form
                function onFigureChanged() {
                    glyphCanvas.requestPaint();
                }
            }
        }
    }

    component Arc: Item {
        id: arc
        property bool labelled: false
        readonly property real diameter: Math.min(arc.width, arc.height)
        readonly property bool labelShown: arc.labelled && form.card.labelText.length > 0 && arcLabel.fits

        Canvas {
            id: arcCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const lineWidth = arc.diameter * form.strokeFraction;
                const radius = arc.diameter / 2 - lineWidth / 2;
                ctx.lineWidth = lineWidth;
                ctx.lineCap = "round";
                ctx.strokeStyle = form.inkAt(form.trackAlpha);
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, radius, form.startAngle, form.startAngle + form.sweepAngle);
                ctx.stroke();
                if (form.shown > 0) {
                    ctx.strokeStyle = form.inkAt(1);
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, radius, form.startAngle, form.startAngle + form.sweepAngle * form.shown);
                    ctx.stroke();
                }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: form
                function onShownChanged() {
                    arcCanvas.requestPaint();
                }
            }
            Connections {
                target: form.card
                function onContentColorChanged() {
                    arcCanvas.requestPaint();
                }
            }
        }

        Item {
            id: valueBox
            objectName: "loadArcValue"
            width: arc.diameter * form.valueFraction
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -arc.diameter * form.valueLift

            ShrinkThenWrapText {
                objectName: "loadPercent"
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                largestSize: 18
                minSize: 8
                maxLines: 1
                value: true
                text: form.percentText
                color: form.card.contentColor
            }
        }

        Item {
            id: gap
            width: arc.diameter * form.gapWidthFraction
            height: arc.diameter * form.gapHeightFraction
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            ShrinkThenWrapText {
                id: arcLabel
                objectName: "loadArcLabel"
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                visible: arc.labelShown
                horizontalAlignment: Text.AlignHCenter
                largestSize: 11
                minSize: 8
                maxLines: 1
                text: arc.labelled ? form.card.labelText : ""
                color: form.card.mutedContentColor
            }
            Pictogram {
                objectName: "loadPictogram"
                anchors.fill: parent
                visible: !arc.labelShown
            }
        }
    }

    Arc {
        objectName: "loadArc"
        visible: !form.wide
        anchors.centerIn: parent
        width: Math.min(form.width, form.height)
        height: width
        labelled: true
    }

    RowLayout {
        anchors.fill: parent
        visible: form.wide
        spacing: form.sideGap

        Arc {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: form.height
            Layout.preferredHeight: form.height
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            ShrinkThenWrapText {
                id: nameFit
                objectName: "loadNameLabel"
                readonly property bool shown: form.card.labelText.length > 0 && nameFit.fits
                Layout.fillWidth: true
                Layout.preferredHeight: nameFit.shown ? implicitHeight : 0
                opacity: nameFit.shown ? 1 : 0
                largestSize: 12
                minSize: 10
                maxLines: 1
                text: form.card.labelText
                color: form.card.mutedContentColor
            }
            ShrinkThenWrapText {
                objectName: "loadName"
                Layout.fillWidth: true
                visible: !nameFit.shown
                largestSize: 12
                minSize: 10
                maxLines: 1
                text: form.sourceName
                color: form.card.mutedContentColor
            }

            Canvas {
                id: barsCanvas
                objectName: "loadCoreBars"
                readonly property var levels: form.peaks(form.cores, form.maxBars)
                visible: form.cores.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: form.cores.length > 0 ? form.barsHeight : 0
                onLevelsChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    const count = levels.length;
                    if (count === 0)
                        return;
                    const gapPx = Math.min(form.barGap, width / count * form.barGapShare);
                    const barWidth = Math.min(form.barMaxWidth, (width - gapPx * (count - 1)) / count);
                    for (let i = 0; i < count; i++) {
                        const x = i * (barWidth + gapPx);
                        ctx.fillStyle = form.inkAt(form.trackAlpha);
                        form.fillRoundRect(ctx, x, 0, barWidth, height, barWidth / 3);
                        const barHeight = height * Math.max(0, Math.min(1, levels[i]));
                        if (barHeight > 0) {
                            ctx.fillStyle = form.inkAt(1);
                            form.fillRoundRect(ctx, x, height - barHeight, barWidth, barHeight, barWidth / 3);
                        }
                    }
                }
                Connections {
                    target: form.card
                    function onContentColorChanged() {
                        barsCanvas.requestPaint();
                    }
                }
            }
            ShrinkThenWrapText {
                objectName: "loadDetailCaption"
                Layout.fillWidth: true
                visible: form.cores.length > 0
                largestSize: Appearance.font.pixelSize.smaller
                maxLines: 1
                text: form.coresText(form.cores.length)
                color: form.card.mutedContentColor
            }

            ShrinkThenWrapText {
                objectName: "loadAmount"
                Layout.fillWidth: true
                visible: form.cores.length === 0 && (form.hasBytes || form.otherText() !== "")
                largestSize: form.amountMaxSize
                maxLines: form.hasBytes ? 1 : 2
                value: true
                text: !form.hasBytes ? form.otherText() : form.byteSize(form.source === "disk" ? Math.max(0, form.totalBytes - form.usedBytes) : form.usedBytes)
                color: form.card.contentColor
            }
            ShrinkThenWrapText {
                objectName: "loadAmountCaption"
                Layout.fillWidth: true
                visible: form.cores.length === 0 && form.hasBytes
                largestSize: Appearance.font.pixelSize.smaller
                maxLines: 1
                text: form.source === "disk" ? Translation.tr("free") : Translation.tr("of %1").arg(form.byteSize(form.totalBytes))
                color: form.card.mutedContentColor
            }
        }
    }
}
