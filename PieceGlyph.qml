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
    readonly property real corner: 1
    readonly property var bodyPaths: glyph.outline.body.map(path => glyph.rounded(path))
    readonly property string cutPath: glyph.outline.cuts.map(path => glyph.rounded(path)).join(" ")

    function polygons(path: string): var {
        const found = [];
        let current = null;
        let x = 0;
        let y = 0;
        for (const [, command, args] of path.matchAll(/([MmLlHhVvZz])([^MmLlHhVvZz]*)/g)) {
            const kind = command.toUpperCase();
            const relative = command !== kind;
            if (kind === "Z") {
                [x, y] = current[0];
                continue;
            }
            const numbers = (args.match(/-?(?:\d+\.?\d*|\.\d+)/g) ?? []).map(Number);
            const step = kind === "H" || kind === "V" ? 1 : 2;
            for (let i = 0; i < numbers.length; i += step) {
                if (kind !== "V")
                    x = relative ? x + numbers[i] : numbers[i];
                if (kind !== "H")
                    y = relative ? y + numbers[i + step - 1] : numbers[i + step - 1];
                if (kind === "M" && i === 0) {
                    current = [];
                    found.push(current);
                }
                current.push([x, y]);
            }
        }
        return found;
    }

    function toward(from: var, to: var): var {
        const distance = Math.hypot(to[0] - from[0], to[1] - from[1]);
        const share = distance > 0 ? Math.min(glyph.corner, distance / 2) / distance : 0;
        return [from[0] + (to[0] - from[0]) * share, from[1] + (to[1] - from[1]) * share];
    }

    function rounded(path: string): string {
        if (/[AaCcQqSsTt]/.test(path))
            return path;
        return glyph.polygons(path).map(points => {
            const count = points.length;
            const corners = points.map((point, i) => {
                const before = glyph.toward(point, points[(i + count - 1) % count]);
                const after = glyph.toward(point, points[(i + 1) % count]);
                return `${i === 0 ? "M" : "L"}${before[0]} ${before[1]}Q${point[0]} ${point[1]} ${after[0]} ${after[1]}`;
            });
            return `${corners.join("")}z`;
        }).join(" ");
    }

    Shape {
        width: glyph.viewport
        height: glyph.viewport
        scale: glyph.width / glyph.viewport
        transformOrigin: Item.TopLeft

        ShapePath {
            fillColor: glyph.bodyPaths[0] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.bodyPaths[0] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.bodyPaths[1] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.bodyPaths[1] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.bodyPaths[2] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.bodyPaths[2] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.bodyPaths[3] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.bodyPaths[3] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.bodyPaths[4] ? glyph.tint : "transparent"
            strokeColor: fillColor
            strokeWidth: glyph.seam
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: glyph.bodyPaths[4] ?? ""
            }
        }
        ShapePath {
            fillColor: glyph.cutFill
            strokeColor: "transparent"
            PathSvg {
                path: glyph.cutPath
            }
        }
    }
}
