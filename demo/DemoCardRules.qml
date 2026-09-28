//@ probe fresence -g 200x100 -s 300
/**
 * The card editor's rules against the cases of app/shared ChoicesTest.kt and GridTest.kt,
 * so the widget offers the same forms, sizes and places as the app does.
 */
import ".."
import "../CardRules.js" as Rules
import QtQuick

Item {
    id: root

    readonly property var config: ({
            "values": {
                "status": {
                    "value": {
                        "text": "writing code"
                    }
                }
            }
        })

    function place(col, row, cols, rows) {
        return {
            "col": col,
            "row": row,
            "cols": cols,
            "rows": rows
        };
    }

    function value(source, col, cols, form) {
        const w = {
            "type": "value",
            "source": source,
            "place": root.place(col ?? 0, 0, cols ?? 1, 1)
        };
        if (form)
            w.form = form;
        return w;
    }

    function media(col, row, cols, rows) {
        return {
            "type": "media",
            "place": root.place(col, row, cols, rows)
        };
    }

    readonly property var game: ({
            "type": "game",
            "place": root.place(0, 0, 0, 0)
        })
    readonly property var grid: [root.media(0, 0, 2, 2), root.media(2, 0, 2, 1)]

    function lastPlace(widgets) {
        return widgets ? widgets[widgets.length - 1].place : null;
    }

    function checks() {
        const statusForms = Rules.formsOffered(root.config, "value", "status", null);
        const rowVariants = Rules.variants(root.config, [root.value("battery", 0, 1, "ring"), root.value("app", 2, 2)], 0, "row", null);
        const ring = root.value("battery", 0, 1, "ring");
        const previewConfig = Object.assign({}, root.config, {
            "row": [root.value("battery"), root.value("cpu", 1), root.value("custom", 2)]
        });
        const realCpu = {
            "text": "7%",
            "fill": 0.07
        };
        const preview = Rules.preview(previewConfig, {
            "values": {
                "cpu": realCpu
            }
        }, 0);
        return [
            {
                "name": "time sources offer only clock forms",
                "got": Rules.formsOffered(root.config, "value", "alarm", null),
                "want": ["clock", "timer"]
            },
            {
                "name": "text sources offer no gauges",
                "got": [statusForms.includes("text"), statusForms.includes("ring"), statusForms.includes("clock")],
                "want": [true, false, false]
            },
            {
                "name": "a command source takes its shape from its current value",
                "got": Rules.shapeOf(root.config, "sleep", {
                    "values": {
                        "sleep": {
                            "time": "1970-01-01T00:00:00Z"
                        }
                    }
                }),
                "want": "time"
            },
            {
                "name": "weather and moon forms belong only to their sources",
                "got": [Rules.formsOffered(root.config, "value", "battery", null).some(f => ["weather", "weather_live", "moon", "sun"].includes(f)), Rules.formsOffered(root.config, "value", "weather", null), Rules.formsOffered(root.config, "value", "moon", null)],
                "want": [false, ["weather_live", "weather"], ["moon"]]
            },
            {
                "name": "variants list only sizes that fit next to neighbours",
                "got": [rowVariants.some(v => v.form === "bar" && v.size.cols === 2 && v.size.rows === 1), rowVariants.some(v => v.size.cols > 2)],
                "want": [true, false]
            },
            {
                "name": "switching to incompatible data resets the form",
                "got": [Rules.withData(root.config, ring, "value", "alarm", null).form, Rules.withData(root.config, root.value("battery", 0, 1, "bar"), "value", "cpu", null).form],
                "want": ["clock", "bar"]
            },
            {
                "name": "a value id is latin and unique",
                "got": [Rules.valueIdFor("Настроение", []), Rules.valueIdFor("До отпуска!", ["do_otpuska"]), Rules.valueIdFor("42", []), Rules.valueIdFor("???", [])],
                "want": ["nastroenie", "do_otpuska_2", "value_42", "value"]
            },
            {
                "name": "a preview fills missing values and keeps real ones",
                "got": [preview.values.cpu === realCpu, preview.values.battery?.fill !== undefined, !!preview.values.custom, !!preview.game],
                "want": [true, true, true, true]
            },
            {
                "name": "a new widget takes the first free slot of the preferred size",
                "got": root.lastPlace(Rules.added(root.grid, root.game, "detail")),
                "want": root.place(2, 1, 2, 1)
            },
            {
                "name": "a new widget shrinks when only a single cell is left",
                "got": root.lastPlace(Rules.added([root.media(0, 0, 2, 1), root.media(2, 0, 1, 1)], root.game, "row")),
                "want": root.place(3, 0, 1, 1)
            },
            {
                "name": "a full grid takes no more widgets",
                "got": Rules.added([root.media(0, 0, 2, 1), root.media(2, 0, 2, 1)], root.game, "row"),
                "want": null
            },
            {
                "name": "a new widget dropped on a cell starts there",
                "got": root.lastPlace(Rules.added(root.grid, root.game, "detail", [3, 1])),
                "want": root.place(3, 1, 1, 1)
            },
            {
                "name": "a move into another widget is rejected",
                "got": [Rules.moved(root.grid, 1, 1, 0, "detail"), Rules.moved(root.grid, 1, 2, 1, "detail")?.[1].place],
                "want": [null, root.place(2, 1, 2, 1)]
            },
            {
                "name": "a widget may move over its own old place",
                "got": Rules.moved([root.media(0, 0, 2, 2)], 0, 1, 0, "detail")?.[0].place,
                "want": root.place(1, 0, 2, 2)
            },
            {
                "name": "a resize is limited by neighbours and grid edges",
                "got": [Rules.resized(root.grid, 0, Rules.size(3, 2), "detail"), Rules.resized(root.grid, 1, Rules.size(2, 5), "detail"), Rules.resized(root.grid, 1, Rules.size(2, 2), "detail")?.[1].place],
                "want": [null, null, root.place(2, 0, 2, 2)]
            },
            {
                "name": "sizes for a widget are only what fits from its corner",
                "got": Rules.sizesFor(root.grid, 1, "detail").map(s => `${s.cols}x${s.rows}`),
                "want": ["1x1", "2x1", "1x2", "2x2", "1x3", "2x3", "1x4", "2x4"]
            },
            {
                "name": "widgets taller than the grid are cut to fit",
                "got": Rules.fittedInto([root.media(0, 0, 2, 2), root.media(2, 0, 2, 1), root.media(0, 1, 4, 1)], "row").map(w => w.place),
                "want": [root.place(0, 0, 2, 1), root.place(2, 0, 2, 1)]
            },
            {
                "name": "a new command value keeps only letters, digits and spaces of its name",
                "got": Rules.newValueSource("command", " Мой \"план\"! ", 0),
                "want": {
                    "command": "echo '{\"text\": \"Мой план\"}'",
                    "interval_s": 60
                }
            },
            {
                "name": "problems are found in the order they are listed",
                "got": Rules.problems({
                    "row": [
                        {
                            "type": "image",
                            "url": "http://x",
                            "place": root.place(0, 0, 1, 1)
                        },
                        {
                            "type": "value",
                            "background": {
                                "kind": "url",
                                "url": "http://x"
                            },
                            "place": root.place(1, 0, 1, 1)
                        }
                    ],
                    "values": {
                        "Bad": {
                            "command": "date"
                        },
                        "empty": {
                            "value": {
                                "text": ""
                            }
                        },
                        "at": {
                            "value": {
                                "time": "2026-09-28T15:00:00Z",
                                "text": "x"
                            }
                        }
                    }
                }),
                "want": ["value_source", "image_url", "background_url", "value_id", "value_empty", "command"]
            },
            {
                "name": "a cleared field leaves the widget instead of saving as null",
                "got": Rules.withFields(root.value("cpu", 0, 1, "ring"), {
                    "form": null,
                    "label": ""
                }),
                "want": root.value("cpu", 0, 1)
            }
        ];
    }
}
