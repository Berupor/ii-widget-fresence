//@ probe fresence -g 430x700 -s 2500
/**
 * The detail grid opens on a tap on the face and closes on the next one, and a
 * card whose detail is empty has nothing to open. Each step waits for the one before it to land instead of a fixed delay.
 */
import ".."
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items

Item {
    id: root

    readonly property var snapshot: Demo.snapshot([Demo.device({
            "id": "dev-self",
            "account": "You"
        })], [Demo.room("room-a", [Demo.member("acc-ivy", [Demo.device({
                            "id": "dev-ivy",
                            "account": "Ivy",
                            "row": [Demo.value("window", [0, 0, 4, 1])],
                            "detail": [Demo.value("cpu", [0, 0, 1, 1], {
                                    "form": "ring",
                                    "label": "CPU"
                                }), Demo.value("uptime", [1, 0, 3, 1], {
                                    "label": "Uptime"
                                })],
                            "state": {
                                "values": {
                                    "window": {
                                        "text": "htop"
                                    },
                                    "cpu": {
                                        "text": "17%",
                                        "fill": 0.17
                                    },
                                    "uptime": {
                                        "text": "3 days"
                                    }
                                }
                            }
                        })]), Demo.member("acc-ray", [Demo.device({
                            "id": "dev-ray",
                            "account": "Ray",
                            "row": [Demo.value("window", [0, 0, 4, 1])],
                            "state": {
                                "values": {
                                    "window": {
                                        "text": "Blender"
                                    }
                                }
                            }
                        })])])])

    property int step: 0
    property var seen: []

    function detailShown(row): bool {
        return Items.findAll(row, it => it.grid === "detail" && it.placed !== undefined)[0]?.visible ?? false;
    }

    function tap(row): void {
        Items.findAll(row, it => it.holdStarted !== undefined)[0].tapped();
    }

    function note(): void {
        root.seen = root.seen.concat([[ivy.expandable, root.detailShown(ivy), ray.expandable, root.detailShown(ray)]]);
    }

    function advance(): void {
        switch (root.step) {
        case 0:
            if (!Fresence.membersById["acc-ivy"] || !ivy.expandable)
                return;
            root.note();
            root.tap(ivy);
            root.tap(ray);
            root.step = 1;
            break;
        case 1:
            root.note();
            root.tap(ivy);
            root.tap(ray);
            root.step = 2;
            break;
        case 2:
            root.note();
            root.step = 3;
            break;
        }
    }

    Timer {
        interval: 100
        running: root.step < 3
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
                "name": "a card with a detail starts closed, opens on a tap on the face and closes on the next",
                "got": root.seen.map(s => s.slice(0, 2)),
                "want": [[true, false], [true, true], [true, false]]
            },
            {
                "name": "a card with an empty detail is not expandable and stays closed",
                "got": root.seen.map(s => s.slice(2)),
                "want": [[false, false], [false, false], [false, false]]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        PresenceRow {
            id: ivy
            Layout.fillWidth: true
            modelData: "acc-ivy"
        }

        PresenceRow {
            id: ray
            Layout.fillWidth: true
            modelData: "acc-ray"
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
