//@ probe fresence -g 420x1200 -s 2500
/**
 * Two more friends' cards on their own, row and detail both open: a travelling
 * photographer (a shared photo, a local clock and the weather in the row, then
 * the photo and weather large, a clock, sunrise/sunset and a line for where she
 * is in the detail - no system metrics) next to a coder (what window is open,
 * workspace and cpu in the row, the app, package count, load, a local clock and
 * what's playing in the detail).
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoCards.js" as DemoCards
import "lib/DemoItems.js" as Items
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property string photoPath: FileUtils.trimFileProtocol(Qt.resolvedUrl("covers/teardrop.jpg"))

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-nomad", [DemoCards.device("traveler", {
                            "id": "dev-nomad",
                            "account": "Nomad",
                            "name": "phone",
                            "kind": "phone"
                        }, root.photoPath)]), Demo.member("acc-turing", [DemoCards.device("coder", {
                            "id": "dev-turing",
                            "account": "Turing"
                        })])])])

    readonly property var expiredDevice: {
        const d = DemoCards.device("traveler", {
            "id": "dev-expired",
            "account": "Expired"
        }, root.photoPath);
        d.state.photo.expires_at = Demo.iso(-Demo.minutes(1));
        return d;
    }

    function grids(row): var {
        return Items.findAll(row, it => it.placed !== undefined && it.grid !== undefined && it.visible);
    }

    function cellsUsed(grid): int {
        return grid.placed.reduce((sum, p) => sum + p.cols * p.rows, 0);
    }

    function overlaps(a, b): bool {
        return a.col < b.col + b.cols && b.col < a.col + a.cols && a.row < b.row + b.rows && b.row < a.row + a.rows;
    }

    function badGrids(): var {
        const bad = [];
        for (const name of DemoCards.names) {
            for (const [grid, widgets] of [["row", DemoCards.rows[name]], ["detail", DemoCards.details[name]]]) {
                const places = widgets.map(w => w.place);
                const clash = places.some((p, i) => places.some((q, j) => i < j && root.overlaps(p, q)));
                if (clash || !places.every(p => CardLayouts.fits(p, grid)))
                    bad.push(`${grid} ${name}`);
            }
        }
        return bad;
    }

    function notTruncated(text: string): bool {
        const copies = Items.findAll(root, it => it.truncated !== undefined && it.text === text && it.visible);
        return copies.length > 0 && copies.every(t => !t.truncated);
    }

    function checks() {
        const rowGrids = [nomadRow, turingRow].map(r => root.grids(r).find(g => g.grid === "row"));
        const photos = Items.findAll(nomadRow, it => it.expiresAt !== undefined && it.path !== undefined && it.visible);
        const caption = Items.findAll(root, it => it.wrapMode !== undefined && it.text === "Barcelona, for a week" && it.visible);
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "both rows drew their row and detail grids",
                "got": [nomadRow, turingRow].map(r => root.grids(r).map(g => g.grid).join(",")),
                "want": ["row,detail", "row,detail"]
            },
            {
                "name": "each row grid fills all four cells",
                "got": rowGrids.map(g => g ? root.cellsUsed(g) : 0),
                "want": [4, 4]
            },
            {
                "name": "the photo tiles draw the agent's cached file and say how long it has left",
                "got": [photos.length, photos.every(p => p.path === root.photoPath), Items.findAll(nomadRow, it => it.text !== undefined && /^\d+ min left$/.test(it.text) && it.visible).length > 0],
                "want": [2, true, true]
            },
            {
                "name": "an expired photo is missing: its hidden tile drops out and the row closes the gap",
                "got": expiredGrid.placed.map(p => [p.widget.type, p.col]),
                "want": [["value", 0], ["weather", 1]]
            },
            {
                "name": "a caption tile wraps at word boundaries, not mid-word",
                "got": caption.length > 0 && caption.every(t => t.wrapMode !== Text.Wrap),
                "want": true
            },
            {
                "name": "a weather tile's city caption is not truncated",
                "got": root.notTruncated("Barcelona"),
                "want": true
            },
            {
                "name": "a 1x1 number value shrinks to fit instead of eliding",
                "got": root.notTruncated("1.24"),
                "want": true
            },
            {
                "name": "a 2x1 text value shrinks to fit instead of eliding",
                "got": root.notTruncated("fresence - Zed"),
                "want": true
            },
            {
                "name": "no demo card uses the error role",
                "got": DemoCards.names.filter(n => DemoCards.rows[n].concat(DemoCards.details[n]).some(w => (w.color ?? "").startsWith("error"))),
                "want": []
            },
            {
                "name": "every demo card grid fits its grid, with no widgets on top of each other",
                "got": root.badGrids(),
                "want": []
            },
            {
                "name": "Turing's status line skips the window his row shows and says what he is playing",
                "got": Items.shownText(turingRow, "memberStatus")[0] ?? "",
                "want": "Midnight City - M83"
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
            id: nomadRow
            Layout.fillWidth: true
            modelData: "acc-nomad"
            showDetails: true
        }

        PresenceRow {
            id: turingRow
            Layout.fillWidth: true
            modelData: "acc-turing"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    CardGrid {
        id: expiredGrid
        visible: false
        width: 388
        device: root.expiredDevice
        widgets: DemoCards.rows.traveler
    }
}
