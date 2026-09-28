//@ probe fresence -g 960x600 -s 2500
/**
 * The README hero: five friends, each card a different shape of the same room -
 * a night owl (a GIF, a far-away clock, the window, the moon), a music head
 * (spinning vinyl), a traveler (a shared photo next to a live sky over
 * Barcelona), a coder (cpu ring, workspace number, the window) and a friend
 * just playing a game, cover art and all. Rows stay collapsed - the point is
 * reading the room at a glance, not every tile it owns.
 */
import ".."
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "lib"
import "lib/DemoCovers.js" as DemoCovers
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items

Item {
    id: root
    readonly property real columnWidth: (root.width - 48) / 2

    function text(t: string): var {
        return {
            "text": t
        };
    }

    readonly property var snapshot: Demo.snapshot([Demo.device({
            "id": "dev-self",
            "account": "You"
        })], [Demo.room("room-a", [Demo.member("acc-nyx", [Demo.device({
                            "id": "dev-nyx",
                            "account": "Nyx",
                            "row": [Demo.widget("image", [0, 0, 1, 1], {
                                    "url": DemoCovers.url("death-note-l.gif")
                                }), Demo.value("local_time", [1, 0, 1, 1], {
                                    "form": "number",
                                    "label": "Tokyo",
                                    "color": "tertiary_container"
                                }), Demo.value("window", [2, 0, 1, 1]), Demo.value("moon", [3, 0, 1, 1], {
                                    "form": "moon"
                                })],
                            "state": {
                                "values": {
                                    "local_time": root.text("03:12"),
                                    "window": root.text("mpv"),
                                    "moon": {
                                        "text": "Waxing",
                                        "fill": 0.62
                                    }
                                }
                            }
                        })]), Demo.member("acc-echo", [Demo.device({
                            "id": "dev-echo",
                            "account": "Echo",
                            "name": "laptop",
                            "kind": "laptop",
                            "row": [Demo.widget("media", [0, 0, 1, 1], {
                                    "form": "vinyl"
                                }), Demo.value("lately", [1, 0, 3, 1], {
                                    "form": "banner",
                                    "label": "Into lately",
                                    "icon": "album",
                                    "color": "secondary_container"
                                })],
                            "state": {
                                "media": Demo.playing("Teardrop", "Massive Attack", DemoCovers.url("teardrop.jpg"), 120000, 330000),
                                "values": {
                                    "lately": root.text("trip-hop, mostly Bristol")
                                }
                            }
                        })]), Demo.member("acc-nomad", [Demo.device({
                            "id": "dev-nomad",
                            "account": "Nomad",
                            "name": "phone",
                            "kind": "phone",
                            "row": [Demo.widget("photo", [0, 0, 2, 1]), Demo.value("weather", [2, 0, 2, 1], {
                                    "form": "weather_live"
                                })],
                            "photo": FileUtils.trimFileProtocol(String(Qt.resolvedUrl("covers/rdr2-hero.jpg"))),
                            "state": {
                                "photo": {
                                    "id": "photo-nomad",
                                    "key": "a2V5",
                                    "mime": "image/jpeg",
                                    "width": 1600,
                                    "height": 900,
                                    "expires_at": Demo.iso(Demo.minutes(40))
                                },
                                "values": {
                                    "weather": root.text("24;113;0;9;120;1;62;Waxing Gibbous;420;1230;1080;Barcelona")
                                }
                            }
                        })]), Demo.member("acc-turing", [Demo.device({
                            "id": "dev-turing",
                            "account": "Turing",
                            "row": [Demo.value("cpu", [0, 0, 1, 1], {
                                    "form": "ring",
                                    "label": "CPU",
                                    "color": "primary_container"
                                }), Demo.value("workspace", [1, 0, 1, 1], {
                                    "form": "number",
                                    "label": "Workspace"
                                }), Demo.value("window", [2, 0, 2, 1], {
                                    "icon": "terminal"
                                })],
                            "state": {
                                "values": {
                                    "cpu": {
                                        "text": "63%",
                                        "fill": 0.63
                                    },
                                    "workspace": root.text("3"),
                                    "window": root.text("nvim main.go")
                                }
                            }
                        })]), Demo.member("acc-ghost", [Demo.device({
                            "id": "dev-ghost",
                            "account": "Ghost",
                            "row": [Demo.widget("game", [0, 0, 4, 1])],
                            "state": {
                                "game": Demo.game("Cyberpunk 2077", Demo.minutes(95), {
                                    "header": DemoCovers.url("cp2077-header.jpg")
                                })
                            }
                        })])])])

    function tilesOf(accountId: string): var {
        return Items.tiles(Items.rowOf(root, accountId));
    }

    function checks() {
        const weather = root.tilesOf("acc-nomad").find(t => t.widget.source === "weather");
        const ghost = root.tilesOf("acc-ghost")[0];
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "all five friends made it into the room",
                "got": ["acc-nyx", "acc-echo", "acc-nomad", "acc-turing", "acc-ghost"].map(id => Fresence.membersById[id]?.presence.kind),
                "want": ["online", "online", "online", "online", "online"]
            },
            {
                "name": "every row tile has its data",
                "got": ["acc-nyx", "acc-echo", "acc-nomad", "acc-turing", "acc-ghost"].map(id => root.tilesOf(id).filter(t => t.dimmed).length),
                "want": [0, 0, 0, 0, 0]
            },
            {
                "name": "the traveler's weather tile is live, sky and all",
                "got": [weather?.form, Items.byName(weather, "tileWeatherSky")[0]?.active],
                "want": ["weather_live", true]
            },
            {
                "name": "the game friend's row is the game, banner and all",
                "got": [ghost?.type, ghost?.form, Items.shownText(ghost, "gameName")],
                "want": ["game", "banner", ["Cyberpunk 2077"]]
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.preferredWidth: root.columnWidth
                Layout.alignment: Qt.AlignTop
                spacing: 12

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-nyx"
                }

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-echo"
                }

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-ghost"
                }
            }

            ColumnLayout {
                Layout.preferredWidth: root.columnWidth
                Layout.alignment: Qt.AlignTop
                spacing: 12

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-nomad"
                }

                PresenceRow {
                    Layout.preferredWidth: root.columnWidth
                    modelData: "acc-turing"
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
