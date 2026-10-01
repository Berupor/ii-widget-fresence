//@ probe fresence -g 620x1560 -s 1500
/**
 * A close-up of the value forms at a size where the bar fill, the ring gap and
 * the headline value are actually legible - a friend's row only ever shows them
 * shrunk into a 1x1/2x1 cell. Also the text that has to fit: a window title led
 * by a symbol, a single long word, ring captions, and a form the type does not
 * have, which falls back to the type's first one.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib"
import "lib/DemoCovers.js" as DemoCovers
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property string symbolTitle: "◐ Personalization"

    readonly property var mainWidgets: [
        Demo.value("cpu", [0, 0, 2, 1], {
            "form": "bar",
            "color": "primary_container",
            "label": "CPU",
            "on_missing": "hide"
        }),
        Demo.value("swap", [2, 0, 1, 1], {
            "form": "ring",
            "icon": "memory_alt",
            "color": "secondary_container",
            "label": "Memory",
            "on_missing": "hide"
        }),
        Demo.value("load", [3, 0, 1, 1], {
            "form": "number",
            "color": "tertiary_container",
            "label": "Load",
            "on_missing": "hide"
        }),
        Demo.value("disk", [0, 1, 1, 1], {
            "form": "text",
            "color": "primary_container",
            "label": "Disk",
            "on_missing": "hide"
        }),
        Demo.value("window", [1, 1, 2, 1], {
            "form": "text",
            "on_missing": "hide"
        }),
        Demo.value("window", [3, 1, 1, 1], {
            "form": "text",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.value("word", [0, 2, 2, 1], {
            "form": "text",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("swap", [2, 2, 1, 1], {
            "form": "ring",
            "color": "tertiary_container",
            "label": "Disk",
            "on_missing": "hide"
        }),
        Demo.value("battery", [3, 2, 1, 1], {
            "form": "ring",
            "color": "primary_container",
            "label": "Battery",
            "on_missing": "hide"
        }),
        Demo.value("memory", [0, 3, 1, 1], {
            "form": "bar",
            "color": "tertiary_container",
            "label": "Memory",
            "on_missing": "hide"
        }),
        Demo.widget("media", [1, 3, 2, 1], {
            "form": "wave",
            "color": "primary",
            "on_missing": "hide"
        }),
        Demo.widget("media", [3, 3, 1, 1], {
            "form": "vinyl",
            "color": "primary_container",
            "on_missing": "hide"
        })
    ]

    readonly property var dialWidgets: [
        Demo.value("cpu", [0, 0, 1, 1], {
            "form": "dial",
            "color": "secondary_container",
            "label": "CPU",
            "on_missing": "hide"
        }),
        Demo.value("disk", [1, 0, 2, 2], {
            "form": "dial",
            "color": "tertiary_container",
            "label": "Disk",
            "on_missing": "hide"
        }),
        Demo.value("load", [3, 0, 1, 1], {
            "form": "vinyl",
            "label": "Foreign form"
        }),
        Demo.value("load", [3, 1, 1, 1], {
            "label": "No form"
        })
    ]

    readonly property var gaugeWidgets: [
        Demo.value("cpu", [0, 0, 1, 1], {
            "form": "figure",
            "on_missing": "hide"
        }),
        Demo.value("memory", [1, 0, 1, 1], {
            "form": "figure",
            "color": "secondary_container",
            "on_missing": "hide"
        }),
        Demo.value("disk", [2, 0, 1, 1], {
            "form": "figure",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.value("battery", [3, 0, 1, 1], {
            "form": "figure",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("cpu", [0, 1, 2, 1], {
            "form": "figure",
            "label": "CPU",
            "color": "secondary_container",
            "on_missing": "hide"
        }),
        Demo.value("swap", [2, 1, 2, 1], {
            "form": "ring",
            "icon": "memory_alt",
            "label": "Memory",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("cpu", [0, 2, 1, 1], {
            "form": "cells",
            "label": "CPU",
            "on_missing": "hide"
        }),
        Demo.value("custom", [1, 2, 1, 1], {
            "form": "cells",
            "label": "Custom",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.value("cpu", [2, 2, 2, 1], {
            "form": "cells",
            "label": "Cores",
            "color": "secondary_container",
            "on_missing": "hide"
        }),
        Demo.value("session", [0, 3, 2, 1], {
            "form": "text",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("session", [2, 3, 2, 1], {
            "form": "number",
            "icon": "code",
            "color": "tertiary_container",
            "on_missing": "hide"
        })
    ]

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-scalars", [Demo.device({
                            "id": "dev-scalars",
                            "account": "Scalars",
                            "detail": root.mainWidgets,
                            "state": {
                                "media": Demo.playing("Nightcall", "Kavinsky", DemoCovers.url("nightcall.jpg"), 40000, 200000),
                                "values": {
                                    "cpu": {
                                        "text": "63%",
                                        "fill": 0.63,
                                        "parts": [0.9, 0.2, 0.75, 1, 0.4, 0.05, 0.6, 0.95]
                                    },
                                    "memory": {
                                        "text": "12.0/16.0G",
                                        "fill": 0.75,
                                        "used_bytes": 12884901888,
                                        "total_bytes": 17179869184
                                    },
                                    "swap": {
                                        "text": "12.0/16.0G",
                                        "fill": 0.75,
                                        "used_bytes": 12884901888,
                                        "total_bytes": 17179869184
                                    },
                                    "custom": {
                                        "text": "40%",
                                        "fill": 0.4
                                    },
                                    "session": {
                                        "text": "Reviewing a patch",
                                        "subtext": "Zed"
                                    },
                                    "load": {
                                        "text": "2.40 / 8"
                                    },
                                    "disk": {
                                        "text": "47%",
                                        "fill": 0.47,
                                        "used_bytes": 1034789347328,
                                        "total_bytes": 2199023255552
                                    },
                                    "window": {
                                        "text": root.symbolTitle
                                    },
                                    "word": {
                                        "text": "Donaudampfschifffahrtsgesellschaft"
                                    },
                                    "battery": {
                                        "text": "82%",
                                        "fill": 0.82
                                    }
                                }
                            }
                        })])])])

    readonly property var device: Fresence.membersById["acc-scalars"]?.shownDevices[0] ?? null

    function tileOf(grid, widgets, index) {
        return Items.tiles(grid).find(t => Items.sameWidget(t.widget, widgets[index])) ?? null;
    }

    function tileAt(index) {
        const dialFrom = root.mainWidgets.length;
        const gaugeFrom = dialFrom + root.dialWidgets.length;
        if (index < dialFrom)
            return root.tileOf(mainGrid, root.mainWidgets, index);
        return index < gaugeFrom ? root.tileOf(dialGrid, root.dialWidgets, index - dialFrom) : root.tileOf(gaugeGrid, root.gaugeWidgets, index - gaugeFrom);
    }

    function part(index, name) {
        return Items.byName(root.tileAt(index), name)[0] ?? null;
    }

    function ringCaptionClear(index) {
        const value = root.part(index, "ringValue");
        const caption = root.part(index, "ringCaption");
        if (!value || !caption)
            return null;
        const valueBottom = value.mapToItem(null, 0, value.height).y;
        const captionTop = caption.mapToItem(null, 0, 0).y;
        return caption.visible && !caption.truncated && !value.truncated && valueBottom <= captionTop;
    }

    function ringTextOffCenter(tile) {
        const center = Items.byName(tile, "ringValue")[0]?.parent;
        const ring = center?.parent;
        if (!ring)
            return null;
        const shown = center.children.filter(it => it.visible && it.text.length > 0);
        const top = shown[0].mapToItem(ring, 0, 0).y;
        const bottom = shown[shown.length - 1].mapToItem(ring, 0, shown[shown.length - 1].height).y;
        return Math.abs((top + bottom) / 2 - ring.height / 2);
    }

    function gauge(index) {
        return root.tileAt(root.mainWidgets.length + root.dialWidgets.length + index);
    }

    function gaugePart(index, name) {
        return Items.byName(root.gauge(index), name)[0] ?? null;
    }

    function cellsOf(index) {
        return Items.findAll(root.gauge(index), it => it.layoutOfCells !== undefined)[0] ?? null;
    }

    function waveLine(index) {
        return Items.findAll(root.tileAt(index), it => it.valueBarHeight !== undefined && it.visible)[0] ?? null;
    }

    function waveBandInside(index) {
        const line = root.waveLine(index);
        if (!line)
            return null;
        let box = line.parent;
        while (box && !box.clip)
            box = box.parent;
        const reach = line.valueBarHeight / 2 + line.valueBarHeight * line.waveAmplitudeMultiplier;
        const centre = line.mapToItem(box, 0, line.height / 2).y;
        return centre - reach >= -0.5 && centre + reach <= box.height + 0.5;
    }

    function checks() {
        const wideTitle = root.part(4, "textValue");
        const narrowTitle = root.part(5, "textValue");
        const word = root.part(6, "textValue");
        return [
            {
                "name": "every fixture tile places on the grid",
                "got": [mainGrid.placed.length, dialGrid.placed.length, gaugeGrid.placed.length],
                "want": [root.mainWidgets.length, root.dialWidgets.length, root.gaugeWidgets.length]
            },
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "a leading symbol stays on the line of its word in a 2x1 text tile",
                "got": [wideTitle?.lineCount, wideTitle?.truncated],
                "want": [1, false]
            },
            {
                "name": "a leading symbol stays on the line of its word when a 1x1 tile has to squeeze it",
                "got": [narrowTitle?.lineCount, narrowTitle?.truncated],
                "want": [1, false]
            },
            {
                "name": "only a lone symbol or emoji is glued to its word, plain words keep their space",
                "got": ["◐ Personalization", "driving home 🎧", "🇯🇵 Tokyo", "Somewhere new", "up 3 hours"].map(t => root.tileAt(4)?.withSymbolsAttached(t)),
                "want": ["◐ Personalization", "driving home 🎧", "🇯🇵 Tokyo", "Somewhere new", "up 3 hours"]
            },
            {
                "name": "a long single word shrinks instead of eliding",
                "got": [word?.truncated, word?.lineCount, (word?.fontInfo.pixelSize ?? 99) < Appearance.font.pixelSize.huge],
                "want": [false, 1, true]
            },
            {
                "name": "a ring shows the value's own text and the widget's label under it",
                "got": [root.part(1, "ringValue")?.text, root.part(7, "ringCaption")?.text],
                "want": ["12 of 16 GB", "Disk"]
            },
            {
                "name": "a ring small enough to lose its caption box keeps the value and drops the icon and the caption",
                "got": [Items.byName(smallRingProbe, "ringValue")[0]?.visible, Items.byName(smallRingProbe, "ringCaption")[0]?.visible, Items.findAll(smallRingProbe, it => it.iconSize !== undefined && it.visible).length, root.part(1, "ringValue")?.visible],
                "want": [true, false, 0, true]
            },
            {
                "name": "a form the value cannot fill gives way to the first one it can, a text form stays",
                "got": [["ring", {"text": "hi"}], ["bar", {"time": "2026-01-01T00:00:00Z"}], ["timer", {"fill": 0.5}], ["clock", {"time": "2026-01-01T00:00:00Z"}], ["text", {"fill": 0.5}], ["ring", null]].map(([form, value]) => CardLayouts.shownValueForm(Demo.value("cpu", [0, 0, 1, 1], {"form": form}), value)),
                "want": ["text", "clock", "ring", "clock", "text", "ring"]
            },
            {
                "name": "a ring or dial without a label keeps its text in the middle",
                "got": [unlabeledRingProbe, unlabeledDialProbe].map(tile => root.ringTextOffCenter(tile) < 1),
                "want": [true, true]
            },
            {
                "name": "dial captions sit below the value, whole",
                "got": root.ringCaptionClear(13),
                "want": true
            },
            {
                "name": "a 2x1 ring draws its value and label beside the ring",
                "got": [root.gaugePart(5, "wideRingValue")?.text, root.gaugePart(5, "wideRingValue")?.visible, root.gaugePart(5, "ringValue")?.visible],
                "want": ["12 of 16 GB", true, false]
            },
            {
                "name": "memory and disk read as used of total, the cpu keeps its own text",
                "got": [root.gaugePart(1, "figureCompact")?.text, root.gaugePart(2, "figureCompact")?.text, root.gaugePart(0, "figureCompact")?.text],
                "want": ["12 GB", "964 GB", "63%"]
            },
            {
                "name": "a wide figure gets the value and label beside the picture",
                "got": [root.gaugePart(4, "figureValue")?.text, root.gaugePart(4, "figureValue")?.visible],
                "want": ["63%", true]
            },
            {
                "name": "cells light one cell per core from parts, and by fill round it without them",
                "got": [6, 7, 8].map(index => root.cellsOf(index)?.count).concat([root.cellsOf(7)?.lit]),
                "want": [8, 16, 8, 6]
            },
            {
                "name": "a value subtext sits above a text sentence, and stands in for a banner's empty label",
                "got": [root.gaugePart(9, "textSubtext")?.text, root.gaugePart(9, "textValue")?.text, root.gauge(10)?.subtext],
                "want": ["Zed", "Reviewing a patch", "Zed"]
            },
            {
                "name": "a bar fills by the value's fill, not by parsing its text",
                "got": [root.waveLine(0)?.value, root.waveLine(9)?.value],
                "want": [0.63, 0.75],
                "tol": 0.001
            },
            {
                "name": "a wave line keeps its troughs: the whole wave sits inside the tile, in a 2x1 bar, a 1x1 bar and the music wave",
                "got": [root.waveBandInside(0), root.waveBandInside(9), root.waveBandInside(10)],
                "want": [true, true, true]
            },
            {
                "name": "the music wave moves on from position_ms by the time since position_at",
                "got": root.waveLine(10)?.value ?? -1,
                "want": 0.2,
                "tol": 0.04
            },
            {
                "name": "with a known track length the vinyl shows its progress ring",
                "got": Items.findAll(root.tileAt(11), it => it.lineWidth !== undefined && it.value !== undefined && it.visible).length,
                "want": 1
            },
            {
                "name": "a dial tile draws a wavy ring, at a 1x1 and a 2x2 size",
                "got": [12, 13].map(index => Items.findAll(root.tileAt(index), it => it.waveAmplitude !== undefined && it.value !== undefined && it.visible).length),
                "want": [1, 1]
            },
            {
                "name": "a dial caption sits below the value, whole",
                "got": root.ringCaptionClear(13),
                "want": true
            },
            {
                "name": "a form the type does not have, or none at all, falls back to the type's first form",
                "got": [root.tileAt(14)?.form, root.tileAt(15)?.form, root.part(14, "textValue")?.text],
                "want": ["text", "text", "2.40 / 8"]
            },
            {
                "name": "a tile takes the fill of its color role and the matching on-color for its text",
                "got": [String(root.tileAt(1)?.tint), String(root.tileAt(1)?.contentColor), String(root.tileAt(4)?.tint)],
                "want": [String(Appearance.colors.colSecondaryContainer), String(Appearance.colors.colOnSecondaryContainer), String(Appearance.colors.colLayer2)]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        CardGrid {
            id: mainGrid
            Layout.fillWidth: true
            device: root.device
            widgets: root.mainWidgets
            grid: "detail"
        }

        CardGrid {
            id: dialGrid
            Layout.fillWidth: true
            device: root.device
            widgets: root.dialWidgets
            grid: "detail"
        }

        CardGrid {
            id: gaugeGrid
            Layout.fillWidth: true
            device: root.device
            widgets: root.gaugeWidgets
            grid: "detail"
        }

        Item {
            Layout.fillHeight: true
        }
    }

    CardTile {
        id: smallRingProbe
        opacity: 0
        width: 64
        height: 64
        widget: root.mainWidgets[1]
        device: root.device
    }

    CardTile {
        id: unlabeledRingProbe
        opacity: 0
        width: 120
        height: 120
        widget: Demo.value("swap", [0, 0, 1, 1], {
            "form": "ring"
        })
        device: root.device
    }

    CardTile {
        id: unlabeledDialProbe
        opacity: 0
        width: 120
        height: 120
        widget: Demo.value("battery", [0, 0, 1, 1], {
            "form": "dial"
        })
        device: root.device
    }
}
