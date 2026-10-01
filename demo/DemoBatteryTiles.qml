//@ probe fresence -g 820x1500 -s 1500
/** The battery tank tile (TileBattery.qml) at 1x1, 2x1, 2x2 and 4x1 across charge levels, charging and no value. */
import ".."
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property real unit: 78
    readonly property real gap: 8
    readonly property var sizes: [[1, 1], [2, 1], [2, 2], [4, 1]]
    readonly property var levels: [
        {
            "name": "p0",
            "fill": 0
        },
        {
            "name": "p5",
            "fill": 0.05
        },
        {
            "name": "p12",
            "fill": 0.12
        },
        {
            "name": "p20",
            "fill": 0.2
        },
        {
            "name": "p57",
            "fill": 0.57
        },
        {
            "name": "p81c",
            "fill": 0.81,
            "charging": true
        },
        {
            "name": "p100c",
            "fill": 1,
            "charging": true
        },
        {
            "name": "empty"
        }
    ]
    readonly property var wall: root.levels.map(level => root.sizes.map(([cols, rows]) => root.tile(level, cols, rows)))

    function tile(level, cols, rows) {
        const value = {};
        if (level.fill !== undefined) {
            value.text = `${Math.round(level.fill * 100)}%`;
            value.fill = level.fill;
        }
        if (level.charging)
            value.subtext = "charging";
        return {
            "id": `dev-${level.name}-${cols}x${rows}`,
            "widget": Demo.value("battery", [0, 0, cols, rows], {
                "form": "ring",
                "color": "primary_container",
                "on_missing": "dim"
            }),
            "device": {
                "device_id": `dev-${level.name}-${cols}x${rows}`,
                "online": true,
                "state": {
                    "values": level.fill === undefined ? {} : {
                        "battery": value
                    }
                }
            }
        };
    }

    function tileOf(name, cols, rows) {
        return Items.tiles(wallView).find(t => t.device.device_id === `dev-${name}-${cols}x${rows}`) ?? null;
    }

    function part(name, cols, rows, objectName) {
        const found = Items.byName(root.tileOf(name, cols, rows), objectName);
        return found.find(item => item.visible) ?? found[0] ?? null;
    }

    function shown(name, cols, rows, objectName) {
        const item = root.part(name, cols, rows, objectName);
        return item && item.visible ? item.text : null;
    }

    function levelFraction(name, cols, rows) {
        const level = root.part(name, cols, rows, "batteryLevel");
        return cols === 1 || rows > 1 ? level.height / level.parent.height : level.width / level.parent.width;
    }

    function checks() {
        return [
            {
                "name": "every battery tile loads the tank form",
                "got": [Items.tiles(wallView).length, Items.brokenForms(wallView), Items.byName(wallView, "tileForm").every(l => l.file === "TileBattery.qml")],
                "want": [root.levels.length * root.sizes.length, [], true]
            },
            {
                "name": "the level rises from the bottom on 1x1 and 2x2 and grows from the left on 2x1 and 4x1",
                "got": [[1, 1], [2, 2], [2, 1], [4, 1]].map(([c, r]) => Math.round(root.levelFraction("p57", c, r) * 100)),
                "want": [57, 57, 57, 57]
            },
            {
                "name": "the percent is on every size",
                "got": [[1, 1], [2, 1], [2, 2], [4, 1]].map(([c, r]) => root.shown("p57", c, r, "batteryValue")),
                "want": ["57%", "57%", "57%", "57%"]
            },
            {
                "name": "the status follows charge: charged, charging, running low, on battery",
                "got": [["p100c", "charged"], ["p81c", "charging"], ["p12", "running low"], ["p20", "running low"], ["p57", "on battery"]].map(([n]) => root.shown(n, 2, 2, "batteryStatus")),
                "want": ["charged", "charging", "running low", "running low", "on battery"]
            },
            {
                "name": "a charge past 20 percent is not low, a charging one never is",
                "got": [["p20", 4, 1], ["p57", 4, 1], ["p81c", 4, 1]].map(([n, c, r]) => root.tileOf(n, c, r).lowBattery),
                "want": [true, false, false]
            },
            {
                "name": "the corner glyph is a bolt when charging, an alert when low, a full battery otherwise",
                "got": ["p81c", "p12", "p57"].map(n => root.part(n, 1, 1, "batteryGlyph").text),
                "want": ["bolt", "battery_alert", "battery_full"]
            },
            {
                "name": "a charging value gets a bolt after it on 2x1, 2x2 and 4x1 and none on 1x1",
                "got": [[2, 1], [2, 2], [4, 1], [1, 1]].map(([c, r]) => root.part("p81c", c, r, "batteryBolt")?.visible ?? false),
                "want": [true, true, true, false]
            },
            {
                "name": "a low level is drawn in the error color",
                "got": [root.part("p5", 1, 1, "batteryLevel").color.r > root.part("p57", 1, 1, "batteryLevel").color.r, root.part("p5", 1, 1, "batteryGlyph").color],
                "want": [true, Appearance.colors.colError]
            },
            {
                "name": "a 2x1 and a 4x1 name the tile with the source when it has no label",
                "got": [root.shown("p57", 2, 1, "batteryLabel"), root.shown("p57", 4, 1, "batteryLabel"), root.shown("p57", 1, 1, "batteryLabel")],
                "want": ["Battery", "Battery", null]
            },
            {
                "name": "no value shows a dash and an empty level",
                "got": [root.shown("empty", 2, 1, "batteryValue"), root.levelFraction("empty", 2, 1)],
                "want": ["-", 0]
            }
        ];
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    Column {
        id: wallView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
        spacing: root.gap

        Repeater {
            model: root.wall

            delegate: Row {
                id: line
                required property var modelData
                spacing: root.gap

                Repeater {
                    model: line.modelData

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
    }
}
