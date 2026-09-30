import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

/** The last game as a board, own side at the bottom; mirrors BoardForm in ChessTiles.kt. */
Item {
    id: form
    required property var card
    readonly property var chess: form.card.chess
    readonly property var game: form.chess?.last ?? null
    readonly property var squares: CardLayouts.boardSquares(form.game?.fen, form.game?.color)
    readonly property bool square: form.width <= form.height
    readonly property bool roomy: form.height >= form.roomyHeight
    readonly property bool hasChip: form.game?.delta !== undefined
    readonly property real pad: form.card.tileInset
    readonly property real boardInset: 4
    readonly property real roomyHeight: 120
    readonly property real chipBesideWidth: 240
    readonly property real tokenFraction: 0.84
    readonly property real pieceFraction: 0.6
    readonly property real silhouetteBoost: 1.15
    readonly property real tokenShade: 0.5
    readonly property real lightSquareAlpha: 0.16
    readonly property real darkSquareAlpha: 0.06
    readonly property real chipMarginSquares: 0.5
    readonly property real captionSize: 12
    readonly property real chipTextSize: 14
    readonly property real footerRatingSize: 28

    readonly property color ink: form.card.contentColor
    readonly property color fill: form.card.tint
    readonly property bool inkIsLighter: form.ink.hslLightness > form.fill.hslLightness
    readonly property color lightToken: ColorUtils.mix(form.inkIsLighter ? form.ink : form.fill, "white", form.tokenShade)
    readonly property color darkToken: ColorUtils.mix(form.inkIsLighter ? form.fill : form.ink, "black", form.tokenShade)

    readonly property string resultText: {
        if (form.game?.result === "win")
            return form.game.ending === "checkmate" ? Translation.tr("Won by checkmate") : Translation.tr("Win");
        return form.game?.result === "loss" ? Translation.tr("Loss") : Translation.tr("Draw");
    }
    readonly property string shortResultText: form.game?.result === "win" ? Translation.tr("Win") : form.resultText
    readonly property string opponentText: {
        const opponent = [form.game?.opponent, form.game?.opponent_rating].filter(v => v !== undefined && v !== null).join(" ");
        const moves = form.game?.moves;
        const movesText = moves === undefined ? "" : (moves === 1 ? Translation.tr("1 move") : Translation.tr("%1 moves").arg(moves));
        return [opponent, movesText].filter(v => v).join(", ");
    }

    onResultTextChanged: summary.shortened = false

    component DeltaChip: Rectangle {
        id: chip
        property int delta: 0
        implicitWidth: chipText.implicitWidth + 20
        implicitHeight: chipText.implicitHeight + 8
        radius: height / 2
        color: Appearance.colors.colPrimary

        StyledText {
            id: chipText
            anchors.centerIn: parent
            text: CardLayouts.deltaText(chip.delta)
            font.pixelSize: form.chipTextSize
            font.weight: Font.DemiBold
            font.letterSpacing: -0.02 * form.chipTextSize
            font.features: ({
                    "tnum": 1
                })
            color: Appearance.colors.colOnPrimary
        }
    }

    Item {
        id: board
        width: form.square ? form.width : form.height
        height: form.height

        readonly property real side: Math.min(clipped.width, clipped.height) / 8

        Item {
            id: clipped
            anchors.fill: parent
            anchors.margins: form.boardInset

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: clipped.width
                    height: clipped.height
                    radius: Math.max(0, form.card.radius - form.boardInset)
                }
            }

            Grid {
                anchors.centerIn: parent
                columns: 8

                Repeater {
                    model: 64

                    Rectangle {
                        id: cell
                        required property int index
                        readonly property string piece: form.squares[Math.floor(cell.index / 8)][cell.index % 8]
                        readonly property bool white: cell.piece !== "" && cell.piece === cell.piece.toUpperCase()

                        width: board.side
                        height: board.side
                        color: Qt.rgba(form.ink.r, form.ink.g, form.ink.b, (Math.floor(cell.index / 8) + cell.index % 8) % 2 === 0 ? form.lightSquareAlpha : form.darkSquareAlpha)

                        Rectangle {
                            visible: cell.piece !== ""
                            anchors.centerIn: parent
                            width: board.side * form.tokenFraction
                            height: width
                            radius: width / 2
                            color: cell.white ? form.lightToken : form.darkToken

                            Loader {
                                anchors.centerIn: parent
                                active: cell.piece !== ""
                                width: board.side * form.pieceFraction * form.silhouetteBoost
                                height: width

                                sourceComponent: PieceGlyph {
                                    piece: cell.piece
                                    tint: cell.white ? form.darkToken : form.lightToken
                                    cutFill: cell.white ? form.lightToken : form.darkToken
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DeltaChip {
        id: cornerChip
        visible: form.square && form.width >= form.roomyHeight && form.hasChip && cornerChip.corner !== null
        delta: form.game?.delta ?? 0

        readonly property real margin: board.side * form.chipMarginSquares
        readonly property var corner: CardLayouts.freeCorner(form.squares, Math.ceil((cornerChip.margin + cornerChip.width) / board.side), Math.ceil((cornerChip.margin + cornerChip.height) / board.side))

        x: cornerChip.corner?.start === false ? form.width - cornerChip.width - cornerChip.margin : cornerChip.margin
        y: cornerChip.corner?.top === false ? form.height - cornerChip.height - cornerChip.margin : cornerChip.margin
    }

    Item {
        id: summary
        visible: !form.square
        x: board.width
        width: Math.max(0, form.width - board.width)
        height: form.height

        readonly property bool chipBeside: !form.roomy && form.width - form.height >= form.chipBesideWidth
        readonly property real gap: 2
        property bool shortened: false
        readonly property real resultSmallest: 12
        readonly property real resultLargest: form.roomy ? 22 : 16
        readonly property real availableHeight: summary.height - 2 * (form.roomy ? form.pad : form.pad / 2)
        readonly property var kept: CardLayouts.keptParts({
            "caption": form.roomy ? modeCaption.implicitHeight + summary.gap : 0,
            "opponent": opponentCaption.implicitHeight + summary.gap,
            "rating": form.roomy ? footer.implicitHeight + summary.gap : 0
        }, Math.round(summary.resultSmallest * 1.3), summary.availableHeight)
        readonly property real restHeight: (summary.kept.includes("caption") ? modeCaption.implicitHeight + summary.gap : 0) + (summary.kept.includes("opponent") ? opponentCaption.implicitHeight + summary.gap : 0) + (summary.kept.includes("rating") ? footer.implicitHeight + summary.gap : 0)
        readonly property bool twoLines: !summary.chipBeside && summary.availableHeight - summary.restHeight >= summary.resultLargest * 1.3 * 2

        ColumnLayout {
            x: form.pad
            y: form.roomy ? form.pad : form.pad / 2
            width: summary.width - form.pad * 2 - (summary.chipBeside && form.hasChip ? sideChip.width + form.pad : 0)
            height: summary.availableHeight
            spacing: summary.gap

            Item {
                Layout.fillHeight: true
                visible: !form.roomy
            }
            StyledText {
                id: modeCaption
                Layout.fillWidth: true
                visible: summary.kept.includes("caption")
                text: form.card.chessModeText
                font.pixelSize: form.captionSize
                font.weight: Font.Medium
                color: form.card.mutedContentColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            ShrinkThenWrapText {
                id: resultLabel
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                largestSize: summary.resultLargest
                maxLines: summary.twoLines ? 2 : 1
                text: summary.shortened ? form.shortResultText : form.resultText
                font.weight: Font.DemiBold
                color: form.card.contentColor
                onFitsChanged: if (!resultLabel.fits)
                    summary.shortened = true
            }
            StyledText {
                id: opponentCaption
                Layout.fillWidth: true
                visible: summary.kept.includes("opponent")
                text: form.opponentText
                font.pixelSize: form.captionSize
                font.weight: Font.Medium
                color: form.card.mutedContentColor
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Item {
                Layout.fillHeight: true
            }
            RowLayout {
                id: footer
                visible: summary.kept.includes("rating")
                spacing: 8

                ShrinkThenWrapText {
                    largestSize: form.footerRatingSize
                    maxLines: 1
                    value: true
                    text: `${form.chess?.rating ?? ""}`
                    color: form.card.contentColor
                }
                DeltaChip {
                    visible: form.hasChip
                    delta: form.game?.delta ?? 0
                }
            }
        }

        DeltaChip {
            id: sideChip
            visible: summary.chipBeside && form.hasChip
            delta: form.game?.delta ?? 0
            anchors.right: parent.right
            anchors.rightMargin: form.pad
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
