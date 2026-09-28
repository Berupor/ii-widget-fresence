//@ probe fresence -g 440x210 -s 1500
/**
 * The README's incognito shot: holding your own avatar slides open
 * PresenceIncognitoPicker, and a friend whose device publishes state.incognito
 * shows up to everyone else as just a hidden line, window and all. Your own
 * incognito is read off your device's state in the snapshot, which is what the
 * bar indicator follows.
 */
import ".."
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items

Item {
    id: root

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You",
                "name": "laptop",
                "kind": "laptop",
                "state": {
                    "incognito": {
                        "note": "at the dentist"
                    }
                }
            })], [Demo.room("room-a", [Demo.member("acc-nova", [Demo.device({
                            "id": "dev-nova",
                            "account": "Nova",
                            "name": "phone",
                            "kind": "phone",
                            "row": [Demo.value("window", [0, 0, 4, 1])],
                            "state": {
                                "incognito": {},
                                "values": {
                                    "window": {
                                        "text": "Signal"
                                    }
                                }
                            }
                        })])])])

    function checks() {
        const nova = Items.rowOf(root, "acc-nova");
        const status = nova ? Items.shownText(nova, "memberStatus").join("") : "";
        return [
            {
                "name": "the picker is open over your own row",
                "got": picker.open,
                "want": true
            },
            {
                "name": "Nova reads as hidden, with no tile and no window in her line",
                "got": [Fresence.membersById["acc-nova"]?.presence.kind, status.length > 0, status.includes("Signal"), Items.tiles(nova).filter(t => t.visible).length],
                "want": ["incognito", true, false, 0]
            },
            {
                "name": "your own device's state.incognito is what hides you, note and all",
                "got": [Fresence.hiding, Fresence.incognitoLabel(), Fresence.membersById["acc-self"]?.presence.kind],
                "want": [true, "Hidden · at the dentist", "incognito"]
            },
            {
                "name": "the bar indicator shows while you hide",
                "got": indicator.shown,
                "want": true
            }
        ];
    }

    Component.onCompleted: Fresence.ingest(JSON.stringify(root.snapshot))

    FresenceIncognitoIndicator {
        id: indicator
        width: 0
        height: 0
        opacity: 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heldRow.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            RowLayout {
                id: heldRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 12
                }
                spacing: 12

                PresenceAvatar {
                    member: Fresence.membersById["acc-self"] ?? null
                    offline: false
                    hidden: false
                    interactive: true
                }

                PresenceIncognitoPicker {
                    id: picker
                    Layout.fillWidth: true
                    open: true
                    hovered: 3
                }
            }
        }

        PresenceRow {
            Layout.fillWidth: true
            modelData: "acc-nova"
        }
    }
}
