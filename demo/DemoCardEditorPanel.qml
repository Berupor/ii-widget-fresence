//@ probe fresence -g 460x900 -s 4000
/**
 * The widget panel and "what to show" data sheet added on top of CardEditor: adding from an
 * empty cell, replacing data, creating and deleting a custom value, the size/form gallery, and
 * clearing a label/icon/colour back to unset. Ends with the panel open on a two-cell-wide tile
 * with the advanced editor on.
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
                    },
                    "battery": {
                        "text": "81%",
                        "fill": 0.81
                    }
                }
            }
        })], [])

    readonly property var config: ({
            "row": [Demo.value("cpu", [0, 0, 1, 1], {
                    "form": "ring",
                    "label": "CPU",
                    "icon": "bolt",
                    "color": "secondary"
                })],
            "detail": []
        })

    property int step: 0
    property var seen: ({})

    function place(col, row, cols, rows) {
        return {
            "col": col,
            "row": row,
            "cols": cols,
            "rows": rows
        };
    }

    function choices(): var {
        return Items.findAll(editor, it => it.tile !== undefined && it.removable !== undefined);
    }

    function choice(title): var {
        return root.choices().find(c => c.title === title);
    }

    function emptyCellAt(col, row): var {
        return Items.findAll(editor, it => it.col !== undefined && it.row !== undefined && it.cursorShape !== undefined && it.visible).find(c => c.col === col && c.row === row);
    }

    function field(placeholder): var {
        return Items.findAll(editor, it => it.placeholderText === placeholder)[0];
    }

    function galleryCells(): var {
        return Items.findAll(editor, it => it.variant !== undefined);
    }

    function iconButtons(): var {
        return Items.findAll(editor, it => it.modelData !== undefined && it.on !== undefined && it.keys === undefined);
    }

    function colorSwatches(): var {
        return Items.findAll(editor, it => it.modelData !== undefined && it.keys !== undefined);
    }

    function header(): var {
        return Items.byName(editor, "widgetPanelHeader")[0];
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
            root.emptyCellAt(2, 0).clicked({});
            root.choice("Battery").clicked();
            root.seen.addedAt = editor.widgets[editor.widgets.length - 1].place;

            editor.selectedIndex = 0;
            root.header().clicked();
            root.choice("Uptime").clicked();
            const replaced = editor.widgets[0];
            root.seen.afterReplace = [replaced.place, replaced.icon, replaced.color, replaced.form, "label" in replaced];

            editor.startAdding();
            root.choice("Text").clicked();
            const created = editor.widgets[editor.widgets.length - 1];
            root.seen.createdValue = [editor.draft.values.text.value.text, created.source, created.label];

            editor.picking = {
                "at": null
            };
            root.choices().find(c => c.title === "Text" && c.removable).removeRequested();
            root.seen.deletedValue = editor.draft.values.text;
            editor.picking = null;
            editor.editWidgets(editor.widgets.filter(w => w.source !== "text"), -1);

            editor.selectedIndex = 0;
            root.seen.variantCount = root.galleryCells().length;
            root.galleryCells().find(c => c.variant.form === "timer").pick();
            root.seen.afterVariant = [editor.widgets[0].place, editor.widgets[0].form];

            editor.selectedIndex = 1;
            root.seen.labelHiddenByDefault = !root.field("Label").visible;
            editor.draft = Object.assign({}, editor.draft, {
                "advanced_editor": true
            });
            root.field("Label").text = "Battery meter";
            root.field("A Material Symbols name").text = "coffee";
            root.colorSwatches().find(s => s.modelData === "secondary").clicked();
            const filled = editor.widgets[1];
            root.seen.fieldsFilled = [filled.label, filled.icon, filled.color];

            root.field("Label").text = "";
            root.iconButtons().find(b => b.modelData === "coffee").clicked();
            root.colorSwatches().find(s => s.modelData === "").clicked();
            const cleared = editor.widgets[1];
            root.seen.fieldsCleared = ["label" in cleared, "icon" in cleared, "color" in cleared];

            editor.picking = {
                "at": null
            };
            root.choice("Image").clicked();
            root.seen.problemBefore = editor.draftProblems.includes("image_url");
            editor.selectedIndex = editor.widgets.length - 1;
            root.field("Image address https://").text = "https://example.com/a.png";
            root.seen.problemAfter = editor.draftProblems.includes("image_url");
            root.seen.imageUrl = editor.widgets[editor.widgets.length - 1].url;

            root.step = 2;
            break;
        }
    }

    Timer {
        interval: 100
        running: root.step < 2
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
                "name": "adding from an empty cell lands at that cell with the preferred size",
                "got": root.seen.addedAt,
                "want": root.place(2, 0, 1, 1)
            },
            {
                "name": "replacing data keeps place, icon and color, and resets an incompatible form",
                "got": root.seen.afterReplace,
                "want": [root.place(0, 0, 1, 1), "bolt", "secondary", "clock", false]
            },
            {
                "name": "creating a custom value adds the value and a widget bound to it with the label",
                "got": root.seen.createdValue,
                "want": ["Text", "text", "Text"]
            },
            {
                "name": "deleting a value removes it from the config",
                "got": root.seen.deletedValue,
                "want": undefined
            },
            {
                "name": "the gallery applies the picked form and size",
                "got": [root.seen.variantCount, root.seen.afterVariant],
                "want": [3, [root.place(0, 0, 2, 1), "timer"]]
            },
            {
                "name": "the label stays hidden until the advanced editor is on",
                "got": root.seen.labelHiddenByDefault,
                "want": true
            },
            {
                "name": "a field takes a value",
                "got": root.seen.fieldsFilled,
                "want": ["Battery meter", "coffee", "secondary"]
            },
            {
                "name": "clearing a field removes the key instead of saving null",
                "got": root.seen.fieldsCleared,
                "want": [false, false, false]
            },
            {
                "name": "an image problem clears once a valid https url is typed",
                "got": [root.seen.problemBefore, root.seen.problemAfter, root.seen.imageUrl],
                "want": [true, false, "https://example.com/a.png"]
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
