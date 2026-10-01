//@ probe fresence -g 460x320 -s 1500
/** The cpu, memory and disk ring tiles (TileLoad.qml) at 1x1 and 2x1, next to the ring they replace for other sources. */
import ".."
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property var widgets: [
        Demo.value("cpu", [0, 0, 1, 1], {
            "form": "ring",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("memory", [1, 0, 1, 1], {
            "form": "ring",
            "color": "secondary_container",
            "on_missing": "hide"
        }),
        Demo.value("disk", [2, 0, 1, 1], {
            "form": "ring",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.value("battery", [3, 0, 1, 1], {
            "form": "ring",
            "color": "primary_container",
            "label": "Battery",
            "on_missing": "hide"
        }),
        Demo.value("cpu", [0, 1, 2, 1], {
            "form": "ring",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("memory", [2, 1, 2, 1], {
            "form": "ring",
            "color": "secondary_container",
            "label": "Work laptop",
            "on_missing": "hide"
        }),
        Demo.value("disk", [0, 2, 2, 1], {
            "form": "ring",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.value("cpu", [2, 2, 1, 1], {
            "form": "ring",
            "color": "primary_container",
            "label": "Tower",
            "on_missing": "hide"
        }),
        Demo.value("memory", [3, 2, 1, 1], {
            "form": "ring",
            "color": "secondary_container",
            "icon": "bolt",
            "on_missing": "hide"
        })
    ]

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-load", [Demo.device({
                            "id": "dev-load",
                            "account": "Load",
                            "detail": root.widgets,
                            "state": {
                                "values": {
                                    "cpu": {
                                        "text": "2%",
                                        "fill": 0.02,
                                        "parts": [0.05, 0, 0.02, 0.1, 0, 0.01, 0.03, 0]
                                    },
                                    "memory": {
                                        "text": "9.9 of 15.6 GB",
                                        "fill": 0.63,
                                        "used_bytes": 10630044058,
                                        "total_bytes": 16750372454
                                    },
                                    "disk": {
                                        "text": "82%",
                                        "fill": 0.82,
                                        "used_bytes": 902168084070,
                                        "total_bytes": 1099511627776
                                    },
                                    "battery": {
                                        "text": "82%",
                                        "fill": 0.82
                                    }
                                }
                            }
                        })])])])

    readonly property var device: Fresence.membersById["acc-load"]?.shownDevices[0] ?? null

    function tileAt(index) {
        return Items.tiles(grid).find(t => Items.sameWidget(t.widget, root.widgets[index])) ?? null;
    }

    function part(index, name) {
        return Items.byName(root.tileAt(index), name)[0] ?? null;
    }

    function checks() {
        return [
            {
                "name": "every fixture tile places on the grid",
                "got": grid.placed.length,
                "want": root.widgets.length
            },
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "a 1x1 load ring shows the rounded percent of the fill",
                "got": [0, 1, 2].map(index => root.part(index, "loadPercent")?.text),
                "want": ["2%", "63%", "82%"]
            },
            {
                "name": "a 1x1 load ring puts the source picture in the gap and keeps a fitting label out of it",
                "got": [root.part(0, "loadPictogram")?.visible, root.part(7, "loadPictogram")?.visible, root.part(7, "loadArcLabel")?.visible],
                "want": [true, false, true]
            },
            {
                "name": "a battery ring is the tank, not a load ring",
                "got": [root.part(3, "batteryValue")?.text, root.part(3, "loadArc")],
                "want": ["82%", null]
            },
            {
                "name": "a 2x1 cpu lists the cores and counts them under the bars",
                "got": [root.part(4, "loadName")?.text, root.part(4, "loadCoreBars")?.visible, root.part(4, "loadDetailCaption")?.text],
                "want": ["CPU", true, "8 cores"]
            },
            {
                "name": "a 2x1 memory shows used bytes with the total under it, and the label as its name",
                "got": [root.part(5, "loadNameLabel")?.text, root.part(5, "loadAmount")?.text, root.part(5, "loadAmountCaption")?.text],
                "want": ["Work laptop", "9.9 GB", "of 16 GB"]
            },
            {
                "name": "a 2x1 disk shows the free bytes",
                "got": [root.part(6, "loadName")?.text, root.part(6, "loadAmount")?.text, root.part(6, "loadAmountCaption")?.text],
                "want": ["Disk", "184 GB", "free"]
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

    CardGrid {
        id: grid
        anchors.fill: parent
        anchors.margins: 16
        device: root.device
        widgets: root.widgets
        grid: "detail"
    }
}
