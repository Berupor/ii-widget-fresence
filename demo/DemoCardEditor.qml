//@ probe fresence -g 460x640 -s 5000
/**
 * The card editor over a made-up config: a move onto a neighbour is dropped, one into a free
 * cell lands, the resize corner steps through the form's sizes, and every edit is saved once
 * after the debounce unless the draft has a problem. The line instead of Online takes value sources
 * in the order picked. Ends on the detail grid with a tile picked.
 */
import ".."
import qs.modules.common
import QtQuick
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items

Item {
    id: root

    readonly property var snapshot: Demo.snapshot([Demo.device({
            "id": "dev-self",
            "account": "You",
            "state": {
                "values": {
                    "cpu": {
                        "text": "7%",
                        "fill": 0.07
                    }
                }
            }
        })], [])

    readonly property var config: ({
            "row": [Demo.value("cpu", [0, 0, 1, 1], {
                    "form": "ring",
                    "label": "CPU"
                }), Demo.value("window", [1, 0, 2, 1])],
            "detail": [Demo.value("memory", [0, 0, 2, 1], {
                    "form": "bar",
                    "label": "Memory",
                    "color": "primary_container"
                }), Demo.value("uptime", [2, 0, 2, 1], {
                    "form": "clock",
                    "label": "Uptime"
                }), Demo.widget("media", [0, 1, 2, 2], {
                    "form": "cover"
                })]
        })

    property int step: 0
    property var seen: ({})
    property var saves: []

    Connections {
        target: Fresence
        function onConfigSaved(config) {
            root.saves = root.saves.concat([config]);
        }
    }

    function cells(): var {
        return Items.findAll(editor, it => it.targetValid !== undefined && it.drag !== undefined);
    }

    function emptyCellsShown(): int {
        return Items.findAll(editor, it => it.col !== undefined && it.row !== undefined && it.cursorShape !== undefined && it.visible).length;
    }

    function dragCell(index, kind, dx, dy): void {
        const cell = root.cells().find(c => c.index === index);
        cell.drag = kind;
        cell.dx = dx;
        cell.dy = dy;
        cell.finish();
    }

    function places(grid): var {
        return (editor.draft?.[grid] ?? []).map(w => [w.place.col, w.place.row, w.place.cols, w.place.rows]);
    }

    function advance(): void {
        switch (root.step) {
        case 0:
            if (!Fresence.selfDevice)
                return;
            Fresence.configLoaded(root.config);
            root.step = 1;
            break;
        case 1:
            root.seen.emptyRowCells = root.emptyCellsShown();
            root.seen.stateAfterLoad = editor.saveState;
            editor.selectedIndex = 0;
            root.dragCell(0, "move", 1.2, 0);
            root.seen.afterBlockedMove = root.places("row");
            root.dragCell(0, "move", 2.6, 0.4);
            root.seen.afterMove = root.places("row");
            root.seen.stateAfterMove = editor.saveState;
            root.step = 2;
            break;
        case 2:
            if (editor.saveState !== "saved")
                return;
            root.seen.savesAfterMove = root.saves.length;
            root.seen.savedRow = root.saves[root.saves.length - 1].row.map(w => w.place.col);
            Items.findAll(root.cells().find(c => c.index === 1), h => h.symbol === "open_in_full")[0].clicked();
            root.seen.afterNextSize = root.places("row");
            root.dragCell(1, "resize", 5, 3);
            root.seen.afterOversize = root.places("row");
            editor.editWidgets(editor.widgets.concat([Demo.widget("image", [0, 0, 1, 1])]), -1);
            root.seen.stateWithProblem = [editor.saveState, editor.saveText];
            root.step = 3;
            break;
        case 3:
            root.seen.savesWithProblem = root.saves.length;
            editor.editWidgets(editor.widgets.slice(0, 2), -1);
            editor.picking = {
                "status": true
            };
            root.seen.statusSheetTypes = Items.findAll(editor, it => it.otherTypes !== undefined)[0].otherTypes;
            editor.pick(editor.draft, "value", "window", null);
            editor.picking = {
                "status": true
            };
            editor.pick(editor.draft, "value", "window", null);
            editor.picking = {
                "status": true
            };
            editor.createValue("Vibe", {
                "value": {
                    "text": "chill"
                }
            });
            root.seen.statusPicked = editor.draft.status;
            root.seen.rowAfterStatus = root.places("row");
            editor.deleteValue("vibe");
            root.seen.statusAfterDelete = editor.draft.status;
            editor.showGrid("detail");
            editor.selectedIndex = 1;
            root.step = 4;
            break;
        case 4:
            if (editor.saveState !== "saved")
                return;
            root.seen.emptyDetailCells = root.emptyCellsShown();
            root.step = 5;
            break;
        }
    }

    Timer {
        interval: 1000
        running: root.step === 3
        onTriggered: root.advance()
    }

    Timer {
        interval: 100
        running: root.step < 5 && root.step !== 3
        repeat: true
        onTriggered: root.advance()
    }

    function checks() {
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "a freshly loaded config is not saved back",
                "got": [root.seen.stateAfterLoad, root.seen.emptyRowCells],
                "want": ["idle", 1]
            },
            {
                "name": "a move onto a neighbour is dropped, a move into a free cell lands",
                "got": [root.seen.afterBlockedMove, root.seen.afterMove],
                "want": [[[0, 0, 1, 1], [1, 0, 2, 1]], [[3, 0, 1, 1], [1, 0, 2, 1]]]
            },
            {
                "name": "an edit waits for the debounce, then saves once",
                "got": [root.seen.stateAfterMove, root.seen.savesAfterMove, root.seen.savedRow],
                "want": ["pending", 1, [3, 1]]
            },
            {
                "name": "the resize corner steps to the form's next size, a drag past the edge is dropped",
                "got": [root.seen.afterNextSize, root.seen.afterOversize],
                "want": [[[3, 0, 1, 1], [1, 0, 1, 1]], [[3, 0, 1, 1], [1, 0, 1, 1]]]
            },
            {
                "name": "a draft with a problem says why and is not saved",
                "got": [root.seen.stateWithProblem, root.seen.savesWithProblem],
                "want": [["invalid", "Not saved: an image needs an https:// address"], 1]
            },
            {
                "name": "the status picker offers values only, keeps the order and skips a repeat, without touching the grids",
                "got": [root.seen.statusSheetTypes, root.seen.statusPicked, root.seen.rowAfterStatus],
                "want": [[], ["window", "vibe"], [[3, 0, 1, 1], [1, 0, 1, 1]]]
            },
            {
                "name": "a deleted value leaves the status line, and the status is saved with the card",
                "got": [root.seen.statusAfterDelete, root.saves[root.saves.length - 1]?.status],
                "want": [["window"], ["window"]]
            },
            {
                "name": "the detail grid shows an empty cell for every free one",
                "got": root.seen.emptyDetailCells,
                "want": 8
            }
        ];
    }

    Component.onCompleted: Fresence.ingest(JSON.stringify(root.snapshot))

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer1
    }

    CardEditor {
        id: editor
        anchors.fill: parent
        anchors.margins: 16
    }
}
