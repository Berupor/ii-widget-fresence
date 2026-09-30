//@ probe fresence -g 420x560 -s 1500
/**
 * The spare end of the spectrum: one quote across the row, a mood sticker, a
 * big clock and the weather in the detail grid - both open, on its own so it
 * reads as restraint rather than emptiness next to a denser card. Off screen,
 * the same card on a device that has no quote yet keeps the tile, dimmed.
 */
import ".."
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoCards.js" as DemoCards
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-ren", [DemoCards.device("minimal", {
                            "id": "dev-ren",
                            "account": "Ren",
                            "name": "phone",
                            "kind": "phone"
                        })])])])

    readonly property var quietDevice: Demo.device({
        "id": "dev-quiet",
        "account": "Quiet",
        "row": DemoCards.rows.minimal,
        "state": {
            "values": {}
        }
    })

    function grids(): var {
        return Items.findAll(renRow, it => it.placed !== undefined && it.grid !== undefined && it.visible);
    }

    function checks() {
        const row = root.grids().find(g => g.grid === "row");
        const quiet = Items.tiles(quietGrid)[0] ?? null;
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "the row and its detail grid are both drawn",
                "got": root.grids().map(g => g.grid),
                "want": ["row", "detail"]
            },
            {
                "name": "the quote spans the whole row",
                "got": row ? row.placed.map(p => [p.col, p.cols]) : [],
                "want": [[0, 4]]
            },
            {
                "name": "a big-form tile shows its label over the value",
                "got": Items.findAll(renRow, it => it.card !== undefined && it.centered !== undefined && it.visible).map(l => l.card.labelText).includes("Mood"),
                "want": true
            },
            {
                "name": "a value with no data and on_missing dim keeps its place, dimmed, with a dash",
                "got": [quietGrid.placed.length, quiet?.dimmed, quiet?.shownValueText],
                "want": [1, true, "-"]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        PresenceRow {
            id: renRow
            Layout.fillWidth: true
            modelData: "acc-ren"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    CardGrid {
        id: quietGrid
        visible: false
        width: 388
        device: root.quietDevice
        widgets: DemoCards.rows.minimal
    }
}
