//@ probe fresence -g 200x100 -s 1500
/** Runs protocol/cases/tiles of the fresence repo, which app/shared checks too. Skipped without FRESENCE_REPO. */
import QtQuick
import Quickshell
import Quickshell.Io
import "../CardLayouts.js" as CardLayouts

Item {
    id: root

    readonly property string repo: Quickshell.env("FRESENCE_REPO") ?? ""
    property var cases: []

    function describe(tile): string {
        const place = tile.place;
        return `${tile.index}: ${place.col},${place.row} ${place.cols}x${place.rows}${tile.dimmed ? " dimmed" : ""} ${tile.form ?? "no form"} ${tile.shape}`;
    }

    function drawn(device, grid, nowMs): var {
        return CardLayouts.placed(device.card[grid], grid, device, nowMs).map(p => root.describe({
                "index": p.index,
                "place": {
                    "col": p.col,
                    "row": p.row,
                    "cols": p.cols,
                    "rows": p.rows
                },
                "dimmed": p.dimmed,
                "form": CardLayouts.shownForm(p.widget) || undefined,
                "shape": CardLayouts.shownShape(p.widget)
            }));
    }

    function checks() {
        if (root.repo === "")
            return [
                {
                    "name": "tile fixtures skipped: FRESENCE_REPO is not set",
                    "got": true,
                    "want": true
                }
            ];
        const perGrid = c => ["row", "detail"].map(grid => ({
                    "name": `${c.name} (${grid})`,
                    "got": root.drawn(c.device, grid, Date.parse(c.now)),
                    "want": c.want[grid].map(root.describe)
                }));
        return [
            {
                "name": "the tile fixtures load",
                "got": root.cases.length > 0,
                "want": true
            }
        ].concat(...root.cases.map(perGrid));
    }

    Process {
        running: root.repo !== ""
        command: ["bash", "-c", "jq -s add \"$1\"/protocol/cases/tiles/*.json", "_", root.repo]
        stdout: StdioCollector {
            onStreamFinished: root.cases = JSON.parse(text)
        }
    }
}
