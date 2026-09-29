import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** The rating with its history chart; mirrors RatingForm in ChessTiles.kt. */
Item {
    id: form
    required property var card
    readonly property var chess: form.card.chess
    readonly property var place: form.card.widget.place
    readonly property var history: (form.chess?.history?.length ?? 0) > 1 ? form.chess.history : null
    readonly property var best: form.history && form.chess.best !== undefined ? form.chess.best : null
    readonly property string bestText: Translation.tr("best")
    readonly property real pad: form.card.tileInset
    readonly property real chartGap: 8
    readonly property real captionPiece: 14
    readonly property real queenFraction: 0.45
    readonly property real tallRatingFraction: 0.3
    readonly property real oneRowChartHeight: 0.7
    readonly property int bestBesideCols: 4
    readonly property bool tall: form.place.rows > 1
    readonly property real cell: Math.min(form.width, form.height)
    readonly property bool oneRowChart: !form.tall && form.history !== null && form.place.cols > 1

    component RatingChart: Canvas {
        id: chart
        property bool filled: false
        readonly property color ink: form.card.contentColor
        readonly property real stroke: 2
        readonly property real dot: chart.stroke * 1.5 / 2
        readonly property real areaAlpha: 0.12
        readonly property real lineAlpha: 0.6
        readonly property real bestAlpha: 0.5
        readonly property real dashScale: 2

        onInkChanged: chart.requestPaint()
        onFilledChanged: chart.requestPaint()
        onCanvasSizeChanged: chart.requestPaint()
        Connections {
            target: form
            function onHistoryChanged() {
                chart.requestPaint();
            }
            function onBestChanged() {
                chart.requestPaint();
            }
        }

        onPaint: {
            const ctx = chart.getContext("2d");
            ctx.reset();
            if (!form.history)
                return;
            const ys = CardLayouts.chartYs(form.history, form.best, chart.height, chart.stroke);
            const last = ys.length - 1;
            const step = (chart.width - chart.dot) / last;
            const slopes = CardLayouts.monotoneSlopes(ys);
            const rgba = alpha => Qt.rgba(chart.ink.r, chart.ink.g, chart.ink.b, alpha);
            if (form.best !== null) {
                ctx.strokeStyle = rgba(chart.bestAlpha);
                ctx.lineWidth = chart.stroke / 2;
                ctx.setLineDash([chart.stroke * chart.dashScale, chart.stroke * chart.dashScale]);
                ctx.beginPath();
                ctx.moveTo(0, chart.stroke);
                ctx.lineTo(chart.width, chart.stroke);
                ctx.stroke();
                ctx.setLineDash([]);
            }
            ctx.beginPath();
            ctx.moveTo(0, ys[0]);
            for (let i = 1; i <= last; i++) {
                const x = step * i;
                ctx.bezierCurveTo(x - step * 2 / 3, ys[i - 1] + slopes[i - 1] / 3, x - step / 3, ys[i] - slopes[i] / 3, x, ys[i]);
            }
            if (chart.filled) {
                ctx.save();
                ctx.lineTo(step * last, chart.height);
                ctx.lineTo(0, chart.height);
                ctx.closePath();
                ctx.fillStyle = rgba(chart.areaAlpha);
                ctx.fill();
                ctx.restore();
                ctx.beginPath();
                ctx.moveTo(0, ys[0]);
                for (let i = 1; i <= last; i++) {
                    const x = step * i;
                    ctx.bezierCurveTo(x - step * 2 / 3, ys[i - 1] + slopes[i - 1] / 3, x - step / 3, ys[i] - slopes[i] / 3, x, ys[i]);
                }
            }
            ctx.strokeStyle = rgba(chart.lineAlpha);
            ctx.lineWidth = chart.stroke;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.stroke();
            ctx.fillStyle = chart.ink;
            ctx.beginPath();
            ctx.arc(step * last, ys[last], chart.dot, 0, 2 * Math.PI);
            ctx.fill();
        }
    }

    ColumnLayout {
        visible: form.tall
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: form.pad
            Layout.topMargin: form.pad
            Layout.rightMargin: form.pad
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    spacing: 4

                    PieceGlyph {
                        implicitWidth: form.captionPiece
                        implicitHeight: form.captionPiece
                        piece: "q"
                        tint: form.card.mutedContentColor
                    }
                    StyledText {
                        text: form.card.chessModeText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: form.card.mutedContentColor
                    }
                }
                ShrinkThenWrapText {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.preferredHeight: form.height * form.tallRatingFraction
                    largestSize: Math.max(24, Math.min(64, Math.floor(form.height * form.tallRatingFraction / 1.2)))
                    maxLines: 1
                    text: `${form.chess?.rating ?? ""}`
                    font.weight: Font.Medium
                    color: form.card.contentColor
                }
            }
            ColumnLayout {
                visible: form.best !== null && form.place.cols >= form.bestBesideCols
                Layout.alignment: Qt.AlignTop
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: form.bestText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: form.card.mutedContentColor
                }
                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `${form.best}`
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: form.card.contentColor
                }
            }
        }
        StyledText {
            visible: form.best !== null && form.place.cols < form.bestBesideCols
            Layout.leftMargin: form.pad
            Layout.topMargin: form.chartGap
            text: `${form.bestText} ${form.best}`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: form.card.mutedContentColor
        }
        RatingChart {
            visible: form.history !== null
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 2
            filled: true
        }
        Item {
            visible: form.history === null
            Layout.fillHeight: true
        }
    }

    RowLayout {
        visible: !form.tall
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.preferredWidth: form.cell
            Layout.preferredHeight: form.cell
            Layout.alignment: form.oneRowChart ? Qt.AlignLeft : Qt.AlignHCenter

            readonly property real inner: form.cell - form.pad * 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: form.pad
                spacing: 0

                Item {
                    Layout.fillHeight: true
                }
                PieceGlyph {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: parent.width * form.queenFraction
                    implicitHeight: implicitWidth
                    piece: "q"
                    tint: form.card.contentColor
                }
                ShrinkThenWrapText {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.preferredHeight: parent.height * (1 - form.queenFraction)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    largestSize: Math.max(Appearance.font.pixelSize.smallest, Math.min(48, Math.floor(parent.height * (1 - form.queenFraction) / 1.2)))
                    maxLines: 1
                    text: `${form.chess?.rating ?? ""}`
                    font.weight: Font.Medium
                    color: form.card.contentColor
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }
        ColumnLayout {
            visible: form.oneRowChart
            Layout.fillWidth: true
            Layout.preferredHeight: form.height * form.oneRowChartHeight
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: form.pad
            spacing: 2

            StyledText {
                visible: form.best !== null
                text: `${form.bestText} ${form.best}`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: form.card.mutedContentColor
            }
            RatingChart {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
