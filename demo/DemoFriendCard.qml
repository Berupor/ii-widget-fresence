//@ probe fresence -g 420x560 -s 1500
/**
 * One friend's night owl card, detail grid open: a game banner, the track as a
 * wave line, the app, uptime, night weather, moon phase, an alarm clock and
 * sunrise/sunset. Her row grid is left empty so nothing repeats between the row
 * and the detail grid below it.
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
                            "account": "Nyx",
                            "row": []
                        })])])])

    function grids(): var {
        return Items.findAll(nyxRow, it => it.placed !== undefined && it.grid !== undefined && it.visible);
    }

    function checks() {
        const detail = root.grids().find(g => g.grid === "detail");
        const holes = detail ? 16 - detail.placed.reduce((sum, p) => sum + p.cols * p.rows, 0) : -1;
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "an empty row draws no row grid, the detail grid is open",
                "got": root.grids().map(g => g.grid),
                "want": ["detail"]
            },
            {
                "name": "the detail grid fills all sixteen cells",
                "got": holes,
                "want": 0
            },
            {
                "name": "every detail tile has its data, so none is dimmed",
                "got": Items.tiles(nyxRow).filter(t => t.dimmed).map(t => t.widget.source ?? t.type),
                "want": []
            },
            {
                "name": "an alarm clock reads its moment in local HH:MM and how far off it is",
                "got": [Items.shownText(nyxRow, "clockValue")[0] ?? "", Items.shownText(nyxRow, "clockDistance")[0] ?? ""],
                "want": [Qt.formatTime(new Date(Date.now() + Demo.minutes(7 * 60 + 30)), "HH:mm"), "in 7 h"]
            },
            {
                "name": "with the game on the card, the status line says what else she is up to",
                "got": Items.shownText(nyxRow, "memberStatus")[0] ?? "",
                "want": "Playing Cyberpunk 2077 · 2h"
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
