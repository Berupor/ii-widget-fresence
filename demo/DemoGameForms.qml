//@ probe fresence -g 420x560 -s 2500
/**
 * The four game forms in one detail grid: a hero over two rows, a one-row banner, rings
 * at 1x1 and 2x1 (wide draws the name beside it), a cover and a cover under a widget
 * color, which keeps the tile's own fill instead of the art's.
 */
import ".."
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import "lib/DemoCovers.js" as DemoCovers
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You"
            })], [Demo.room("room-a", [Demo.member("acc-gil", [Demo.device({
                            "id": "dev-gil",
                            "account": "Gil",
                            "row": [],
                            "detail": [Demo.widget("game", [0, 0, 4, 2], {
                                    "form": "hero"
                                }), Demo.widget("game", [0, 2, 2, 1], {
                                    "form": "banner"
                                }), Demo.widget("game", [2, 2, 1, 1], {
                                    "form": "ring"
                                }), Demo.widget("game", [3, 2, 1, 1], {
                                    "form": "cover"
                                }), Demo.widget("game", [0, 3, 2, 1], {
                                    "form": "ring"
                                }), Demo.widget("game", [2, 3, 2, 1], {
                                    "form": "cover",
                                    "color": "tertiary_container"
                                })],
                            "state": {
                                "game": Demo.game("Space Marine 2", Demo.minutes(95), {
                                    "header": DemoCovers.url("sm2-header.jpg"),
                                    "hero": DemoCovers.url("sm2-hero.jpg"),
                                    "logo": DemoCovers.url("sm2-logo.png"),
                                    "cover": DemoCovers.url("sm2-header.jpg")
                                })
                            }
                        })])])])

    function gameTiles(): var {
        return Items.tiles(gilRow).filter(t => t.type === "game");
    }

    function checks() {
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "each game form is drawn as asked, none dimmed",
                "got": root.gameTiles().map(t => [t.form, t.dimmed]),
                "want": [["hero", false], ["banner", false], ["ring", false], ["cover", false], ["ring", false], ["cover", false]]
            },
            {
                "name": "a session is shown as a stopwatch on every form",
                "got": Items.shownText(gilRow, "gameSession").filter(t => /^1:3[45]:\d\d$/.test(t) || /^1:3[45]:\d\d in game$/.test(t)).length,
                "want": 6
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
            id: gilRow
            Layout.fillWidth: true
            modelData: "acc-gil"
            showDetails: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
