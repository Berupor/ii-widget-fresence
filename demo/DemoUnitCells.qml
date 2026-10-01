//@ probe fresence -g 1000x1250 -s 1500
/**
 * Countdown and timer tiles as unit cells at every layout of app/shared ui/card/UnitCells.kt:
 * 1x1, 2x1, 3x1, 4x1, 2xN, 3xN and 4xN, with and without a label.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property real unit: 78
    readonly property real gap: 8
    readonly property var sizes: [[1, 1], [2, 1], [3, 1], [4, 1], [2, 2], [2, 3], [3, 2], [3, 3], [4, 2], [4, 3]]
    readonly property var sources: ({
            "countdown": {
                "mode": "until",
                "time": Demo.iso(((2 * 24 + 3) * 60 + 4) * 60000 + 5000)
            },
            "timer": {
                "mode": "since",
                "time": Demo.iso(-(25 * 60000 + 7000))
            }
        })

    readonly property var wallTiles: {
        const tiles = [];
        for (const kind of Object.keys(root.sources))
            for (const label of ["Focus", ""])
                for (const [cols, rows] of root.sizes)
                    tiles.push(root.tile(kind, label, cols, rows));
        return tiles;
    }

    function tile(kind, label, cols, rows) {
        const extra = {
            "form": "timer",
            "time_mode": root.sources[kind].mode,
            "color": kind === "timer" ? "secondary_container" : "tertiary_container"
        };
        if (label)
            extra.label = label;
        return {
            "kind": kind,
            "label": label,
            "widget": Demo.value(kind, [0, 0, cols, rows], extra),
            "device": {
                "device_id": `dev-${kind}-${cols}x${rows}-${label || "plain"}`,
                "online": true,
                "state": {
                    "values": {
                        [kind]: {
                            "time": root.sources[kind].time
                        }
                    }
                }
            }
        };
    }

    function tileOf(kind, label, cols, rows) {
        return Items.tiles(wall).find(t => t.device.device_id === `dev-${kind}-${cols}x${rows}-${label || "plain"}`) ?? null;
    }

    function cellsOf(kind, label, cols, rows) {
        return Items.shownText(root.tileOf(kind, label, cols, rows), "unitCell");
    }

    function checks() {
        return [
            {
                "name": "every unit tile renders one CardTile and every form loads",
                "got": [Items.tiles(wall).length, Items.brokenForms(wall)],
                "want": [root.wallTiles.length, []]
            },
            {
                "name": "a countdown shows days, hours, minutes and seconds as far as the tile has cells: one, two or four",
                "got": [[1, 1], [2, 1], [3, 1], [4, 1], [2, 2], [4, 3]].map(([c, r]) => root.cellsOf("countdown", "Focus", c, r).join(" ")),
                "want": ["2", "2 3", "2 3 4 5", "2 3 4 5", "2 3 4 5", "2 3 4 5"]
            },
            {
                "name": "a timer drops the leading zero units and counts up from minutes",
                "got": [[1, 1], [2, 1], [3, 1], [4, 2]].map(([c, r]) => root.cellsOf("timer", "", c, r).join(" ")),
                "want": ["25", "25 7", "25 7", "25 7"]
            },
            {
                "name": "numbers grow with the tile: 28 in one cell, 24 in a row of cells, 40 once the tile is four wide and tall",
                "got": [[1, 1], [3, 1], [4, 1], [4, 2], [2, 3]].map(([c, r]) => Items.byName(root.tileOf("countdown", "Focus", c, r), "unitCell").filter(t => t.visible)[0].largestSize),
                "want": [28, 24, 24, 40, 24]
            },
            {
                "name": "a 4x1 tile carries the label and the moment beside the cells, 4x2 above them, 2x2 the label alone, 3x1 nothing",
                "got": [[4, 1], [4, 2], [2, 2], [3, 1]].map(([c, r]) => [Items.shownText(root.tileOf("countdown", "Focus", c, r), "unitLabel").length, Items.shownText(root.tileOf("countdown", "Focus", c, r), "unitMoment").length]),
                "want": [[1, 1], [1, 1], [1, 0], [0, 0]]
            }
        ];
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    Flow {
        id: wall
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: root.gap

        Repeater {
            model: root.wallTiles
            delegate: CardTile {
                id: tileItem
                required property var modelData
                width: tileItem.modelData.widget.place.cols * root.unit + (tileItem.modelData.widget.place.cols - 1) * root.gap
                height: tileItem.modelData.widget.place.rows * root.unit + (tileItem.modelData.widget.place.rows - 1) * root.gap
                widget: tileItem.modelData.widget
                device: tileItem.modelData.device
            }
        }
    }
}
