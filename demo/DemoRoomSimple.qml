//@ probe fresence -g 420x900 -s 1500
/**
 * The room at its plainest: one friend playing music with the app she's in named
 * too, one in a game, one with nothing more than the window she's in, and one gone
 * incognito, so the room says only that she's hidden.
 */
import ".."
import qs.modules.common
import QtQuick
import "lib"
import "lib/DemoCovers.js" as DemoCovers
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items

Item {
    id: root

    readonly property var snapshot: Demo.snapshot([Demo.device({
                "id": "dev-self",
                "account": "You",
                "row": [Demo.value("window", [0, 0, 4, 1])],
                "state": {
                    "values": {
                        "window": {
                            "text": "fresence - Zed"
                        }
                    }
                }
            })], [Demo.room("room-a", [Demo.member("acc-mira", [Demo.device({
                            "id": "dev-mira",
                            "account": "Mira",
                            "name": "workstation",
                            "row": [Demo.widget("media", [0, 0, 3, 1], {
                                    "form": "player",
                                    "shape": "circle"
                                })],
                            "status": ["window", "app"],
                            "state": {
                                "media": Demo.playing("Nightcall", "Kavinsky", DemoCovers.url("nightcall.jpg"), 78000, 258000),
                                "values": {
                                    "app": {
                                        "text": "discord"
                                    }
                                }
                            }
                        })]), Demo.member("acc-dan", [Demo.device({
                            "id": "dev-dan",
                            "account": "Dan",
                            "row": [Demo.widget("game", [0, 0, 4, 1])],
                            "state": {
                                "game": Demo.game("Red Dead Redemption 2", Demo.minutes(84), {
                                    "header": DemoCovers.url("rdr2-header.jpg")
                                })
                            }
                        })]), Demo.member("acc-zoe", [Demo.device({
                            "id": "dev-zoe",
                            "account": "Zoe",
                            "name": "laptop",
                            "kind": "laptop",
                            "status": ["window"],
                            "state": {
                                "values": {
                                    "window": {
                                        "text": "Fresence - pull requests - Firefox"
                                    }
                                }
                            }
                        })]), Demo.member("acc-lena", [Demo.device({
                            "id": "dev-lena",
                            "account": "Lena",
                            "name": "phone",
                            "kind": "phone",
                            "row": [Demo.value("window", [0, 0, 4, 1])],
                            "state": {
                                "incognito": {},
                                "values": {
                                    "window": {
                                        "text": "Messages"
                                    }
                                }
                            }
                        })])])])

    function statusOf(accountId: string): string {
        const row = Items.rowOf(root, accountId);
        return row ? Items.shownText(row, "memberStatus").join("") : "";
    }

    function tileTypes(accountId: string): var {
        return Items.tiles(Items.rowOf(root, accountId)).filter(t => t.visible && !t.dimmed).map(t => t.type);
    }

    function statusWithout(accountId: string): string {
        const member = Fresence.membersById[accountId];
        const device = member.devices[0];
        return Fresence.statusFor(member, Object.assign({}, device, {
            "card": Object.assign({}, device.card, {
                "status": undefined
            })
        }), null);
    }

    function checks() {
        return [
            {
                "name": "the room is what was fed in, you included",
                "got": [Fresence.memberCount, Fresence.onlineCount],
                "want": [5, 5]
            },
            {
                "name": "you come first, then the rest by name",
                "got": Fresence.memberIds,
                "want": ["acc-self", "acc-dan", "acc-mira", "acc-zoe", "acc-lena"]
            },
            {
                "name": "each row draws what its card asks for",
                "got": ["acc-mira", "acc-dan", "acc-zoe", "acc-lena"].map(id => root.tileTypes(id).join(",")),
                "want": ["media", "game", "", ""]
            },
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "a playing track on the row leaves the status line to the app, the next of her status sources",
                "got": root.statusOf("acc-mira"),
                "want": "discord"
            },
            {
                "name": "a game on the row leaves the status line with nothing but online",
                "got": root.statusOf("acc-dan"),
                "want": "Online"
            },
            {
                "name": "the plain friend's status line names her window",
                "got": root.statusOf("acc-zoe"),
                "want": "Fresence - pull requests - Firefox"
            },
            {
                "name": "without status sources on the card the window stays unsaid",
                "got": root.statusWithout("acc-zoe"),
                "want": "Online"
            },
            {
                "name": "an incognito friend says only that she's hidden, window and all",
                "got": [Fresence.membersById["acc-lena"].presence.kind, root.statusOf("acc-lena").includes("Messages"), root.tileTypes("acc-lena").length],
                "want": ["incognito", false, 0]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    PresenceTab {
        anchors.fill: parent
    }
}
