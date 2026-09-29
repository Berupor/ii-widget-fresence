import QtQuick
import QtQuick.Shapes
import "CardLayouts.js" as CardLayouts

Item {
    id: glyph
    property string piece: "q"
    property color tint: "white"
    property color cutFill: "transparent"
    readonly property var outline: CardLayouts.chessPieces[glyph.piece.toLowerCase()] ?? {
        "body": [],
        "cuts": []
    }
    readonly property real viewport: 24
    readonly property real seam: 0.5

    Shape {
        width: glyph.viewport
        height: glyph.viewport
        scale: glyph.width / glyph.viewport
        transformOrigin: Item.TopLeft

        ShapePath {
            fillColor: glyph.outline.body[0] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.outline.body[0] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.outline.body[1] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.outline.body[1] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.outline.body[2] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.outline.body[2] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.outline.body[3] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.outline.body[3] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.outline.body[4] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.outline.body[4] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.cutFill
            strokeColor: "transparent"
            PathSvg {
                path: glyph.outline.cuts.join(" ")
            }
        }
    }
}
