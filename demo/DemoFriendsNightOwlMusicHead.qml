//@ probe fresence -g 420x1200 -s 1500
/**
 * Two friends' cards on their own, row and detail both open: a night owl (a
 * local clock, what window is open and the moon phase in the row, the game, a
 * wave line, the app, uptime, the night weather, the moon, an alarm and
 * sunrise/sunset in the detail) next to a music head (a spinning vinyl, what
 * she's into lately and a clock in the row) with the minimal detail grid.
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

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-nyx", [DemoCards.device("nightOwl", {
                            "id": "dev-nyx",
                            "account": "Nyx"
                        })]), Demo.member("acc-echo", [DemoCards.device("musicHead", {
                            "id": "dev-echo",
                            "account": "Echo",
                            "name": "laptop",
                            "kind": "laptop",
                            "detail": DemoCards.details.minimal,
                            "state": Object.assign(DemoCards.state("musicHead"), {
                                "values": Object.assign(DemoCards.state("musicHead").values, DemoCards.state("minimal").values)
                            })
                        })])])])

    function grids(row): var {
        return Items.findAll(row, it => it.placed !== undefined && it.grid !== undefined && it.visible);
    }

    function cellsUsed(grid): int {
        return grid.placed.reduce((sum, p) => sum + p.cols * p.rows, 0);
    }

    function checks() {
        const rowGrids = [nyxRow, echoRow].map(r => root.grids(r).find(g => g.grid === "row"));
        const waveBars = Items.findAll(nyxRow, it => it.wavy !== undefined && it.waveFrequency !== undefined && it.visible);
        const vinyl = Items.tiles(echoRow).find(t => t.form === "vinyl") ?? null;
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "both rows drew their row and detail grids",
                "got": [nyxRow, echoRow].map(r => root.grids(r).map(g => g.grid).join(",")),
                "want": ["row,detail", "row,detail"]
            },
            {
                "name": "each row grid fills all four cells",
                "got": rowGrids.map(g => g ? root.cellsUsed(g) : 0),
                "want": [4, 4]
            },
            {
                "name": "the wave form draws one wavy progress line",
                "got": [waveBars.length, waveBars[0]?.wavy],
                "want": [1, true]
            },
            {
                "name": "the wave line's progress is position_ms over length_ms, moved on since position_at",
                "got": waveBars[0]?.value ?? -1,
                "want": 40000 / 210000,
                "tol": 0.02
            },
            {
                "name": "a playing vinyl turns",
                "got": Items.findAll(vinyl, it => it.rotation > 0).length > 0,
                "want": true
            },
            {
                "name": "Nyx's status line says the game her detail pictures, the window is already on her row",
                "got": Items.shownText(nyxRow, "memberStatus")[0] ?? "",
                "want": "Playing Cyberpunk 2077 · 2h"
            },
            {
                "name": "Echo's status line leaves the track to her vinyl and falls back to online",
                "got": Items.shownText(echoRow, "memberStatus")[0] ?? "",
                "want": "Online"
            },
            {
                "name": "a clock fed plain text shows that text, with no distance under it",
                "got": [Items.shownText(echoRow, "clockValue").includes("09:00"), Items.shownText(echoRow, "clockDistance").length],
                "want": [true, 0]
            },
            {
                "name": "a session reads elapsed time, not the calendar day it crossed",
                "got": (() => {
                    const midnight = new Date();
                    midnight.setHours(24, 0, 11, 0);
                    const before = Fresence.now;
                    Fresence.now = midnight.getTime();
                    const result = [Fresence.sessionText(midnight.getTime() - 13 * 60000), Fresence.sessionText(midnight.getTime() - 25 * 3600000)];
                    Fresence.now = before;
                    return result;
                })(),
                "want": ["13m", "1d"]
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
            id: nyxRow
            Layout.fillWidth: true
            modelData: "acc-nyx"
            showDetails: true
        }

        PresenceRow {
            id: echoRow
            Layout.fillWidth: true
            modelData: "acc-echo"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
