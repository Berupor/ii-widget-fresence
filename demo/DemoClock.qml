//@ probe fresence -g 900x1500 -s 1500
/**
 * The clock tile at every size of both forms, with and without a city: the layouts
 * app/shared ui/card/Clock.kt picks by the place, and the day bar of the member's
 * next 24 hours in the viewer's time.
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
    readonly property int tokyoOffsetS: 9 * 3600

    readonly property var sizes: [[1, 1], [2, 1], [3, 1], [4, 1], [2, 2], [4, 2], [2, 4], [3, 4]]

    readonly property var wallTiles: {
        const tiles = [];
        for (const city of ["Tokyo", ""])
            for (const form of ["clock", "day"])
                for (const [cols, rows] of root.sizes)
                    tiles.push(root.tile(form, cols, rows, city));
        return tiles;
    }

    function tile(form, cols, rows, city) {
        return {
            "widget": Demo.widget("clock", [0, 0, cols, rows], {
                "form": form,
                "color": form === "day" ? "tertiary_container" : "secondary_container"
            }),
            "device": {
                "device_id": `dev-clock-${form}-${cols}x${rows}-${city || "nocity"}`,
                "online": true,
                "state": {
                    "utc_offset_s": root.tokyoOffsetS,
                    "weather": city ? {
                        "place": city
                    } : undefined
                }
            }
        };
    }

    function layoutFor(form, cols, rows) {
        return CardLayouts.clockLayout(form, cols, rows);
    }

    function checks() {
        const noon = Date.parse("2026-09-30T12:00:00Z");
        const partsAt = minute => CardLayouts.dayPartsAhead(minute).map(p => [p.from, p.to, p.night]);
        return [
            {
                "name": "every clock tile renders one CardTile and every form loads",
                "got": [Items.tiles(wall).length, Items.brokenForms(wall)],
                "want": [root.wallTiles.length, []]
            },
            {
                "name": "the clock reads the owner's zone, from midnight on",
                "got": [CardLayouts.minuteOfDayAt(0, Date.parse("2026-01-01T15:20:00Z")), CardLayouts.minuteOfDayAt(-5 * 3600, Date.parse("2026-01-01T03:45:00Z")), CardLayouts.hhmm(22 * 60 + 45), CardLayouts.hhmm(24 * 60 + 5)],
                "want": [15 * 60 + 20, 22 * 60 + 45, "22:45", "00:05"]
            },
            {
                "name": "night runs from 23:00 to 07:00",
                "got": [22 * 60 + 59, 23 * 60, 0, 6 * 60 + 59, 7 * 60].map(CardLayouts.isNight),
                "want": [false, true, true, true, false]
            },
            {
                "name": "the next change is the morning at night and the night by day, past midnight when it already passed",
                "got": [CardLayouts.nextPhaseChange(23 * 60 + 30), CardLayouts.nextPhaseChange(12 * 60), CardLayouts.nextPhaseChange(7 * 60)],
                "want": [
                    {
                        "morning": true,
                        "afterMin": 7.5 * 60
                    },
                    {
                        "morning": false,
                        "afterMin": 11 * 60
                    },
                    {
                        "morning": false,
                        "afterMin": 16 * 60
                    }
                ]
            },
            {
                "name": "the day bar splits the next 24 hours at the phase changes and ends on the 24th hour",
                "got": [partsAt(12 * 60), partsAt(2 * 60)],
                "want": [
                    [[0, 11 * 60, false], [11 * 60, 19 * 60, true], [19 * 60, 24 * 60, false]],
                    [[0, 5 * 60, true], [5 * 60, 21 * 60, false], [21 * 60, 24 * 60, true]]
                ]
            },
            {
                "name": "a gap prints whole hours without minutes and the half hours with them",
                "got": [CardLayouts.signedHours(180), CardLayouts.signedHours(-300), CardLayouts.signedHours(330), CardLayouts.signedHours(-570), CardLayouts.offsetGapMinutes(5.5 * 3600, 0)],
                "want": ["+3", "-5", "+5:30", "-9:30", 330]
            },
            {
                "name": "the member's date runs ahead, behind or with the viewer's, and 1970-01-01 is a Thursday",
                "got": [CardLayouts.dayShift(noon, 14 * 3600, -10 * 3600), CardLayouts.dayShift(noon, -10 * 3600, 14 * 3600), CardLayouts.dayShift(noon, 3600, 0), CardLayouts.weekdayAt(0, 0), CardLayouts.weekdayAt(0, 3 * 86400000)],
                "want": [1, -1, 0, 4, 0]
            },
            {
                "name": "the place and the form pick the layout",
                "got": [[null, 1, 1], ["clock", 2, 1], ["clock", 3, 1], ["clock", 4, 1], ["clock", 2, 2], ["clock", 4, 2], ["clock", 3, 3], ["day", 1, 4], ["day", 2, 1], ["day", 4, 1], ["day", 2, 2], ["day", 4, 2], ["day", 2, 4]].map(a => root.layoutFor(...a)),
                "want": ["stacked", "rowShort", "rowShort", "rowLong", "corner", "big", "big", "stacked", "dayRowShort", "dayRowLong", "dayCorner", "sideBySide", "tall"]
            },
            {
                "name": "a tall clock without a form keeps the day bar, a chosen form stays",
                "got": [Demo.widget("clock", [0, 0, 2, 3]), Demo.widget("clock", [0, 0, 2, 3], {
                        "form": "clock"
                    }), Demo.widget("clock", [0, 0, 2, 2]), Demo.widget("clock", [0, 0, 1, 1], {
                        "form": "day"
                    })].map(CardLayouts.shownForm),
                "want": ["day", "clock", "clock", "day"]
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
