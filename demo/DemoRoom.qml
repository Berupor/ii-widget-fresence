//@ probe fresence -g 430x1000 -s 4000
/**
 * The room drawn from made-up data: `ingest` takes the same Snapshot line
 * `fresence watch` prints, so nothing here is stubbed and the whole pipeline runs.
 * `-p scenario=` picks the state - `plain` is the everyday room in two rooms with
 * the switcher, several devices per account and someone offline, `edge` is
 * everything that has ever looked wrong: long names, a nameless account, broken
 * art, an account with more devices than fit. Before the room settles, both walk
 * the agent states a snapshot or a watch exit can put the tab in.
 */
import ".."
import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import "lib"
import "lib/DemoCovers.js" as DemoCovers
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items

Item {
    id: root

    property string scenario: "plain"
    readonly property bool edge: root.scenario === "edge"

    readonly property var self: [Demo.device({
            "id": "dev-you-laptop",
            "account": "You",
            "name": "thinkpad",
            "kind": "laptop",
            "row": [Demo.value("window", [0, 0, 3, 1]), Demo.value("battery", [3, 0, 1, 1], {
                    "form": "ring",
                    "label": "Battery"
                })],
            "state": {
                "values": {
                    "window": {
                        "text": "fresence - Zed"
                    },
                    "battery": {
                        "text": "81%",
                        "fill": 0.81
                    }
                }
            }
        }), Demo.device({
            "id": "dev-you-phone",
            "account": "You",
            "name": "pixel",
            "kind": "phone",
            "online": false
        })]

    readonly property var mira: Demo.member("acc-mira", [Demo.device({
            "id": "dev-mira-desk",
            "account": "Mira",
            "row": [Demo.widget("game", [0, 0, 2, 1]), Demo.widget("media", [2, 0, 2, 1], {
                    "form": "player"
                })],
            "state": {
                "game": Demo.game("Red Dead Redemption 2", Demo.minutes(70), {
                    "header": DemoCovers.url("rdr2-header.jpg"),
                    "hero": DemoCovers.url("rdr2-hero.jpg")
                }),
                "media": Demo.playing("Teardrop", "Massive Attack", DemoCovers.url("teardrop.jpg"), 61000, 330000)
            }
        })])

    readonly property var plainRooms: [Demo.room("room-a", [root.mira, Demo.member("acc-dan", [Demo.device({
                    "id": "dev-dan-tower",
                    "account": "Dan",
                    "online": false,
                    "seenAgo": Demo.minutes(180),
                    "row": [Demo.widget("game", [0, 0, 4, 1])]
                }), Demo.device({
                    "id": "dev-dan-phone",
                    "account": "Dan",
                    "name": "phone",
                    "kind": "phone",
                    "row": [Demo.widget("media", [0, 0, 4, 1])],
                    "state": {
                        "media": Demo.playing("Nightcall", "Kavinsky", DemoCovers.url("nightcall.jpg"), 78000, 258000)
                    }
                })]), Demo.member("acc-kai", [Demo.device({
                    "id": "dev-kai-laptop",
                    "account": "Kai",
                    "name": "laptop",
                    "kind": "laptop",
                    "online": false,
                    "seenAgo": Demo.minutes(42),
                    "row": [Demo.value("window", [0, 0, 4, 1])],
                    "state": {
                        "values": {
                            "window": {
                                "text": "vim notes.md"
                            }
                        }
                    }
                }), Demo.device({
                    "id": "dev-kai-phone",
                    "account": "Kai",
                    "card": false
                })]), Demo.member("acc-lena", [Demo.device({
                    "id": "dev-lena",
                    "account": "Lena",
                    "online": false,
                    "seenAgo": Demo.minutes(42),
                    "row": [Demo.value("window", [0, 0, 4, 1])],
                    "state": {
                        "values": {
                            "window": {
                                "text": "Telegram"
                            }
                        }
                    }
                })])]), Demo.room("room-b", [root.mira, Demo.member("acc-noor", [Demo.device({
                    "id": "dev-noor",
                    "account": "Noor"
                })])])]

    readonly property var manyDevices: [0, 1, 2, 3, 4].map(i => Demo.device({
                "id": `dev-many-${i}`,
                "account": "Rin",
                "name": `box-${i}`,
                "online": i >= 2,
                "row": [Demo.value("window", [0, 0, 4, 1])],
                "state": i === 2 ? {
                    "incognito": {}
                } : {
                    "values": {
                        "window": {
                            "text": `window on box-${i}`
                        }
                    }
                }
            }))

    readonly property var edgeRooms: [Demo.room("room-edge", [Demo.member("acc-long", [Demo.device({
                    "id": "dev-long",
                    "account": "Maximiliana Alexandrovna-Konstantinopolskaya",
                    "name": "a-workstation-with-a-hostname-nobody-can-read",
                    "row": [Demo.value("window", [0, 0, 4, 1])],
                    "state": {
                        "values": {
                            "window": {
                                "text": "A very long window title that goes on - and on - past any sidebar width anyone has"
                            }
                        }
                    }
                }), Demo.device({
                    "id": "dev-long-2",
                    "account": "Maximiliana Alexandrovna-Konstantinopolskaya",
                    "name": "another-hostname-that-is-also-far-too-long"
                })]), Demo.member("acc-nameless", [Demo.device({
                    "id": "dev-nameless",
                    "row": [Demo.widget("game", [0, 0, 4, 1])],
                    "state": {
                        "game": Demo.game("Cyberpunk 2077", 5000, {
                            "header": DemoCovers.url("dead-header.jpg")
                        })
                    }
                })]), Demo.member("acc-sol", [Demo.device({
                    "id": "dev-sol",
                    "account": "Sol",
                    "row": [Demo.widget("media", [0, 0, 4, 1], {
                            "form": "player"
                        })],
                    "state": {
                        "media": Demo.playing("A track whose art never loads", "Nobody", DemoCovers.url("gone.jpg"), 1000, 200000)
                    }
                })]), Demo.member("acc-rin", root.manyDevices), Demo.member("acc-bart", [Demo.device({
                    "id": "dev-bart",
                    "account": "Bartholomew Fitzgerald-Worthington the Third",
                    "online": false,
                    "seenAgo": Demo.minutes(3 * 24 * 60 + 30)
                })])])]

    readonly property var snapshot: Demo.snapshot(root.self, root.edge ? root.edgeRooms : root.plainRooms)

    property int step: 0
    property int waited: 0
    property var seen: ({})

    function note(key: string, value): void {
        const next = Object.assign({}, root.seen);
        next[key] = value;
        root.seen = next;
    }

    function stateText(state: string): string {
        Fresence.snapshot = {
            "status": {
                "state": state,
                "version": "demo",
                "update": "9.9.9"
            },
            "rooms": []
        };
        return [Fresence.agentState, Fresence.placeholderText(), Items.byName(tab, "roomHeader")[0]?.visible ?? false].join("|");
    }

    function advance(): void {
        switch (root.step) {
        case 0:
            if (Fresence.memberIds.length === 0)
                return;
            root.note("switchable", tab.switchable);
            tab.pickingRoom = true;
            root.step = 1;
            break;
        case 1:
            root.note("roomList", Items.findAll(Items.byName(tab, "roomList")[0], it => it.modelData?.room_id !== undefined && it.current !== undefined).map(b => [b.modelData.room_id, b.current]));
            tab.pickingRoom = false;
            if (!root.edge)
                Fresence.selectRoom("room-b");
            root.step = 2;
            break;
        case 2:
            if (!root.edge && Fresence.opt("room") !== "room-b")
                return;
            root.note("picked", [Fresence.room?.room_id, Fresence.opt("room"), Fresence.memberIds.slice()]);
            Fresence._pickedRoomId = "room-gone";
            root.note("gone", Fresence.room?.room_id);
            Fresence._pickedRoomId = "";
            if (!root.edge)
                Fresence.selectRoom("room-a");
            root.step = 3;
            break;
        case 3:
            if (!root.edge && Fresence.opt("room") !== "room-a")
                return;
            const dan = Items.rowOf(tab, "acc-dan");
            if (dan) {
                const before = dan.device.device_id;
                dan.nextDevice();
                const after = dan.device.device_id;
                dan.nextDevice();
                root.note("cycle", [before, after, dan.device.device_id]);
            }
            const kept = Fresence.snapshot;
            root.note("states", ["unlinked", "linking", "update_required"].map(s => root.stateText(s)));
            const connecting = JSON.parse(JSON.stringify(kept));
            connecting.status.state = "connecting";
            Fresence.snapshot = connecting;
            root.note("connecting", [Fresence.headerText(), Fresence.memberIds.length > 0]);
            const found = Fresence.binaryFound;
            Fresence.binaryFound = true;
            Fresence.snapshot = null;
            Fresence.watchExitCode = 3;
            root.note("notRunning", [Fresence.agentState, Fresence.placeholderText()]);
            Fresence.watchExitCode = 1;
            root.note("brokenWatch", Fresence.agentState);
            Fresence.watchExitCode = 0;
            Fresence.binaryFound = found;
            Fresence.snapshot = kept;
            root.step = 4;
            break;
        case 4:
            // Flipping binaryFound started and killed a real watch, whose exit clears the snapshot a beat later
            if (++root.waited < 20)
                return;
            Fresence.ingest(JSON.stringify(root.snapshot));
            root.step = 5;
            break;
        }
    }

    Timer {
        interval: 50
        running: root.step < 5
        repeat: true
        onTriggered: root.advance()
    }

    function row(accountId: string): var {
        return Items.rowOf(tab, accountId);
    }

    function statusOf(accountId: string): string {
        return Items.shownText(root.row(accountId), "memberStatus").join("");
    }

    function plainChecks(): var {
        const kai = root.row("acc-kai");
        const lena = root.row("acc-lena");
        return [
            {
                "name": "more than one room puts the switcher on the header, and its list marks the current one",
                "got": [root.seen.switchable, root.seen.roomList],
                "want": [true, [["room-a", true], ["room-b", false]]]
            },
            {
                "name": "a picked room is shown and stored in the room option",
                "got": root.seen.picked,
                "want": ["room-b", "room-b", ["acc-self", "acc-mira", "acc-noor"]]
            },
            {
                "name": "a stored room that is no longer in the snapshot falls back to the first",
                "got": root.seen.gone,
                "want": "room-a"
            },
            {
                "name": "the room is what was fed in, offline members last",
                "got": [Fresence.room?.room_id, Fresence.memberIds, Fresence.onlineCount],
                "want": ["room-a", ["acc-self", "acc-dan", "acc-kai", "acc-mira", "acc-lena"], 4]
            },
            {
                "name": "an offline member is dimmed and says when they were last seen",
                "got": [lena?.opacity, root.statusOf("acc-lena")],
                "want": [0.6, "Last seen 42 min ago"]
            },
            {
                "name": "the first online device leads, the chip cycles through all and comes back",
                "got": [root.row("acc-dan")?.device?.device_id, root.seen.cycle],
                "want": ["dev-dan-phone", ["dev-dan-phone", "dev-dan-tower", "dev-dan-phone"]]
            },
            {
                "name": "a device chip shows only on an account with more than one card",
                "got": ["acc-self", "acc-dan", "acc-kai", "acc-mira"].map(id => Items.byName(root.row(id), "deviceChip")[0]?.visible),
                "want": [true, true, false, false]
            },
            {
                "name": "an offline device of an online account shows dimmed under a last seen line",
                "got": [Fresence.membersById["acc-kai"]?.presence.kind, kai?.deviceAway, Items.tiles(kai).map(t => t.valueText)],
                "want": ["online", true, ["vim notes.md"]]
            },
            {
                "name": "the game and the track on the row keep the status line quiet",
                "got": root.statusOf("acc-mira"),
                "want": "Online"
            },
            {
                "name": "each state before a room says what is going on instead of the room",
                "got": root.seen.states,
                "want": ["unlinked|This device is not linked yet.\nfresence link, or fresence join with an invite|false", "linking|Linking this device…|false", "update_required|The agent needs updating to 9.9.9|false"]
            }
        ];
    }

    function edgeChecks(): var {
        const rin = root.row("acc-rin");
        const nameless = Items.tiles(root.row("acc-nameless"))[0];
        const sol = Items.tiles(root.row("acc-sol"))[0];
        return [
            {
                "name": "a single room keeps the header plain",
                "got": root.seen.switchable,
                "want": false
            },
            {
                "name": "the room is what was fed in, offline members last",
                "got": [Fresence.memberCount, Fresence.onlineCount, Fresence.memberIds[Fresence.memberIds.length - 1]],
                "want": [6, 5, "acc-bart"]
            },
            {
                "name": "an account with no name says so",
                "got": Items.shownText(root.row("acc-nameless"), "memberName"),
                "want": ["No name"]
            },
            {
                "name": "with more devices than fit, the first online one not hiding leads",
                "got": rin?.device?.device_id,
                "want": "dev-many-3"
            },
            {
                "name": "long names elide on one line instead of pushing the row wider",
                "got": [Items.byName(root.row("acc-long"), "memberName")[0]?.truncated, Items.byName(root.row("acc-long"), "deviceChip")[0]?.width <= 140, root.row("acc-long")?.width <= tab.width],
                "want": [true, true, true]
            },
            {
                "name": "a dead header url shows the picture its cache slot fell back to",
                "got": Items.findAll(nameless, it => it.fallbackIcon !== undefined && it.status !== undefined && it.visible)[0]?.status,
                "want": Image.Ready
            },
            {
                "name": "art that never loads leaves the player its fallback icon, title and all",
                "got": [Items.findAll(sol, it => it.fallbackIcon !== undefined && it.status !== undefined)[0]?.status === Image.Ready, Items.shownText(sol, "mediaTitle")],
                "want": [false, ["A track whose art never loads"]]
            },
            {
                "name": "days offline read as days",
                "got": root.statusOf("acc-bart"),
                "want": "Last seen 3 days ago"
            }
        ];
    }

    function checks() {
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "every row got drawn",
                "got": Fresence.memberIds.every(id => root.row(id)?.visible),
                "want": true
            },
            {
                "name": "connecting keeps the last room and says so in the header",
                "got": root.seen.connecting,
                "want": ["Connecting to the server…", true]
            },
            {
                "name": "watch exiting with 3 means the agent is not running, any other exit is waiting",
                "got": [root.seen.notRunning, root.seen.brokenWatch],
                "want": [["not_running", "The fresence agent is not running.\nsystemctl --user start fresence"], "starting"]
            }
        ].concat(root.edge ? root.edgeChecks() : root.plainChecks());
    }

    DemoCoverSeed {
        extraSeeds: ({
                "dead-header.jpg": "cp2077-header.jpg"
            })
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    PresenceTab {
        id: tab
        anchors.fill: parent
    }
}
