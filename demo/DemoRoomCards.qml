//@ probe fresence -g 940x1100 -s 3000
/**
 * Cards by protocol.md, row and detail open: one friend with every widget type
 * across both grids (value, media, game, a shared photo from the agent's cache and
 * an https image), one whose missing data is hidden or dimmed so the grids collapse
 * around it, one with forms that are missing or foreign to their type, time
 * values on either side of now under each time_mode, and every color role, and one
 * with a music and a url background over its tile and a game background with no
 * picture yet, still in its own color.
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
    Component.onCompleted: Fresence.frozenAt = Demo.now

    readonly property string photoFile: FileUtils.trimFileProtocol(String(Qt.resolvedUrl("covers/rdr2-hero.jpg")))
    readonly property var colorRoles: ["primary", "secondary", "tertiary", "error", "primary_container", "secondary_container", "tertiary_container", "error_container"]
    readonly property var colorKeys: ["colPrimary", "colSecondary", "colTertiary", "colError", "colPrimaryContainer", "colSecondaryContainer", "colTertiaryContainer", "colErrorContainer"]

    readonly property var ada: Demo.member("acc-ada", [Demo.device({
            "id": "dev-ada",
            "account": "Ada",
            "row": [Demo.value("cpu", [0, 0, 1, 1], {
                    "form": "ring",
                    "label": "CPU",
                    "color": "primary_container"
                }), Demo.widget("media", [1, 0, 1, 1], {
                    "form": "vinyl"
                }), Demo.widget("game", [2, 0, 1, 1], {
                    "form": "cover"
                }), Demo.widget("photo", [3, 0, 1, 1])],
            "detail": [Demo.widget("image", [0, 0, 2, 2], {
                    "url": DemoCovers.url("sm2-hero.jpg")
                }), Demo.widget("media", [2, 0, 2, 1], {
                    "form": "player"
                }), Demo.widget("game", [2, 1, 2, 1], {
                    "form": "banner"
                }), Demo.value("alarm", [0, 2, 2, 1], {
                    "form": "clock",
                    "label": "Alarm",
                    "icon": "alarm",
                    "time_mode": "until"
                }), Demo.value("focus", [2, 2, 2, 1], {
                    "form": "timer",
                    "label": "Focus",
                    "time_mode": "since"
                }), Demo.value("memory", [0, 3, 2, 1], {
                    "form": "bar",
                    "label": "Memory",
                    "color": "tertiary_container"
                }), Demo.value("note", [2, 3, 2, 1], {
                    "form": "banner",
                    "label": "Note",
                    "icon": "edit_note"
                })],
            "photo": root.photoFile,
            "state": {
                "media": Demo.playing("Nightcall", "Kavinsky", DemoCovers.url("nightcall.jpg"), 78000, 258000),
                "game": Demo.game("Space Marine 2", Demo.minutes(35), {
                    "header": DemoCovers.url("sm2-header.jpg"),
                    "hero": DemoCovers.url("sm2-hero.jpg"),
                    "logo": DemoCovers.url("sm2-logo.png"),
                    "cover": DemoCovers.url("sm2-header.jpg")
                }),
                "photo": {
                    "id": "photo-1",
                    "key": "a2V5",
                    "mime": "image/jpeg",
                    "width": 1600,
                    "height": 900,
                    "expires_at": Demo.iso(Demo.minutes(50) + 30000)
                },
                "values": {
                    "cpu": {
                        "text": "42%",
                        "fill": 0.42
                    },
                    "alarm": {
                        "time": Demo.iso(Demo.minutes(90) + 30000)
                    },
                    "focus": {
                        "time": Demo.iso(-Demo.minutes(25))
                    },
                    "memory": {
                        "text": "12.4/31.0G",
                        "fill": 0.4
                    },
                    "note": {
                        "text": "back at 6, ping me"
                    }
                }
            }
        })])

    function present(id: string): var {
        return {
            "text": id
        };
    }

    readonly property var hid: Demo.member("acc-hid", [Demo.device({
            "id": "dev-hid",
            "account": "Hid",
            "row": [Demo.value("a", [0, 0, 1, 1]), Demo.value("gone", [1, 0, 1, 1]), Demo.value("b", [2, 0, 2, 1])],
            "detail": [Demo.value("gone", [0, 0, 4, 1], {
                    "on_missing": "hide"
                }), Demo.value("dim", [0, 1, 2, 1], {
                    "on_missing": "dim"
                }), Demo.widget("media", [2, 1, 2, 1], {
                    "on_missing": "dim"
                }), Demo.widget("game", [0, 2, 4, 1], {
                    "on_missing": "hide"
                }), Demo.value("d", [0, 3, 4, 1])],
            "state": {
                "values": {
                    "a": root.present("a"),
                    "b": root.present("b"),
                    "d": root.present("d")
                }
            }
        })])

    readonly property var mia: Demo.member("acc-mia", [Demo.device({
            "id": "dev-mia",
            "account": "Mia",
            "row": [Demo.value("x", [0, 0, 2, 1], {
                    "form": "cover"
                }), Demo.widget("media", [2, 0, 1, 1]), Demo.widget("game", [3, 0, 1, 1], {
                    "form": "player"
                })],
            "detail": [Demo.value("until_past", [0, 0, 2, 1], {
                    "form": "clock",
                    "time_mode": "until",
                    "on_missing": "dim"
                }), Demo.value("since_future", [2, 0, 2, 1], {
                    "form": "clock",
                    "time_mode": "since",
                    "on_missing": "dim"
                }), Demo.value("auto_future", [0, 1, 2, 1], {
                    "form": "text",
                    "time_mode": "auto"
                }), Demo.value("auto_past", [2, 1, 2, 1], {
                    "form": "text"
                })].concat(root.colorRoles.map((role, i) => Demo.value("x", [i % 4, 2 + Math.floor(i / 4), 1, 1], {
                    "form": "number",
                    "label": role,
                    "color": role
                }))),
            "state": {
                "media": Demo.playing("Teardrop", "Massive Attack", DemoCovers.url("teardrop.jpg"), 61000, 330000),
                "game": Demo.game("Red Dead Redemption 2", Demo.minutes(70), {
                    "header": DemoCovers.url("rdr2-header.jpg")
                }),
                "values": {
                    "x": {
                        "text": "7"
                    },
                    "until_past": {
                        "time": Demo.iso(-Demo.minutes(10))
                    },
                    "since_future": {
                        "time": Demo.iso(Demo.minutes(10))
                    },
                    "auto_future": {
                        "time": Demo.iso(Demo.minutes(10) + 30000)
                    },
                    "auto_past": {
                        "time": Demo.iso(-Demo.minutes(10) - 30000)
                    }
                }
            }
        })])

    readonly property var backdrop: Demo.member("acc-backdrop", [Demo.device({
            "id": "dev-backdrop",
            "account": "Bea",
            "row": [Demo.value("vibe", [0, 0, 2, 1], {
                    "form": "banner",
                    "label": "Now",
                    "background": {
                        "kind": "music"
                    }
                }), Demo.value("quiet", [2, 0, 1, 1], {
                    "background": {
                        "kind": "game"
                    }
                }), Demo.value("linked", [3, 0, 1, 1], {
                    "background": {
                        "kind": "url",
                        "url": DemoCovers.url("nightcall.jpg")
                    }
                })],
            "state": {
                "media": Demo.playing("Sundown", "FKJ", DemoCovers.url("nightcall.jpg"), 40000, 200000),
                "values": {
                    "vibe": {
                        "text": "chill"
                    },
                    "quiet": {
                        "text": "quiet"
                    },
                    "linked": {
                        "text": "linked"
                    }
                }
            }
        })])

    readonly property var discs: Demo.member("acc-disc", [Demo.device({
            "id": "dev-disc",
            "account": "Dee",
            "row": [Demo.widget("media", [0, 0, 1, 1], {
                    "form": "poster"
                }), Demo.widget("media", [1, 0, 1, 1], {
                    "form": "sleeve"
                })],
            "detail": [Demo.widget("media", [0, 0, 2, 2], {
                    "form": "poster"
                }), Demo.widget("media", [2, 0, 2, 2], {
                    "form": "sleeve"
                }), Demo.widget("media", [0, 2, 2, 2], {
                    "form": "poster",
                    "color": "primary_container"
                })],
            "state": {
                "media": Demo.playing("Teardrop", "Massive Attack", DemoCovers.url("teardrop.jpg"), 61000, 330000)
            }
        })])

    readonly property var tube: Demo.member("acc-tube", [Demo.device({
            "id": "dev-tube",
            "account": "Tube",
            "row": [Demo.widget("media", [0, 0, 4, 1], {
                    "form": "player"
                })],
            "detail": [Demo.widget("media", [0, 0, 1, 1], {
                    "form": "vinyl",
                    "on_missing": "dim"
                })],
            "state": {
                "media": Demo.playing("Economy wars", "Some channel", undefined, 674000, 1909000, {
                    "kind": "video",
                    "player": "app.revanced.android.youtube"
                })
            }
        })])

    readonly property var snapshot: Demo.snapshot([Demo.device({
            "id": "dev-self",
            "account": "You"
        })], [Demo.room("room-a", [root.ada, root.hid, root.mia, root.backdrop, root.discs, root.tube])])

    function row(accountId: string): var {
        return Items.rowOf(root, accountId);
    }

    function grids(accountId: string): var {
        return Items.findAll(root.row(accountId), it => it.placed !== undefined && it.grid !== undefined);
    }

    function grid(accountId: string, name: string): var {
        return root.grids(accountId).find(g => g.grid === name) ?? null;
    }

    function tilesOf(accountId: string, name: string): var {
        return Items.tiles(root.grid(accountId, name));
    }

    function tile(accountId: string, name: string, pred): var {
        return root.tilesOf(accountId, name).find(pred) ?? null;
    }

    function source(id: string): var {
        return t => t.widget.source === id;
    }

    function ofType(type: string): var {
        return t => t.type === type;
    }

    function layout(g): var {
        return (g?.placed ?? []).map(p => [p.widget.source ?? p.widget.type, p.col, p.row, p.cols, p.rows, p.dimmed]);
    }

    function checks() {
        const photo = root.tile("acc-ada", "row", root.ofType("photo"));
        const image = root.tile("acc-ada", "detail", root.ofType("image"));
        const alarm = root.tile("acc-ada", "detail", root.source("alarm"));
        const focus = root.tile("acc-ada", "detail", root.source("focus"));
        const hidMedia = root.tile("acc-hid", "detail", root.ofType("media"));
        const colored = root.tilesOf("acc-mia", "detail").filter(t => root.colorRoles.includes(t.widget.color));
        const music = root.tile("acc-backdrop", "row", root.source("vibe"));
        const quiet = root.tile("acc-backdrop", "row", root.source("quiet"));
        const linked = root.tile("acc-backdrop", "row", root.source("linked"));
        const discRow = root.tilesOf("acc-disc", "row");
        const discDetail = root.tilesOf("acc-disc", "detail");
        const tube = root.tile("acc-tube", "row", root.ofType("media"));
        const tubeVinyl = root.tile("acc-tube", "detail", root.ofType("media"));
        return [
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(root),
                "want": []
            },
            {
                "name": "every type draws with its data, none dimmed",
                "got": ["row", "detail"].map(g => root.tilesOf("acc-ada", g).map(t => [t.type, t.form, t.dimmed])),
                "want": [[["value", "ring", false], ["media", "vinyl", false], ["game", "cover", false], ["photo", "", false]], [["image", "", false], ["media", "player", false], ["game", "banner", false], ["value", "clock", false], ["value", "timer", false], ["value", "bar", false], ["value", "banner", false]]]
            },
            {
                "name": "the photo tile shows the agent's cached file with the time it has left",
                "got": [Items.findAll(photo, it => it.sourcePath !== undefined)[0]?.sourcePath, Items.findAll(photo, it => it.sourcePath !== undefined)[0]?.status, Items.findAll(photo, it => it.text === "50m").length],
                "want": [root.photoFile, Image.Ready, 1]
            },
            {
                "name": "the image tile draws its https url",
                "got": Items.findAll(image, it => it.fallbackIcon !== undefined && it.status !== undefined && it.visible).map(a => [a.source, a.status]),
                "want": [[DemoCovers.url("sm2-hero.jpg"), Image.Ready]]
            },
            {
                "name": "a clock shows the moment in local HH:MM and drops the distance under a label on a short tile",
                "got": [Items.shownText(alarm, "clockValue"), Items.shownText(alarm, "clockDistance")],
                "want": [[Demo.clockText(Date.parse(alarm?.value?.time ?? ""))], []]
            },
            {
                "name": "a timer ticks from its moment",
                "got": Items.shownText(focus, "timerValue").map(t => /^25:\d\d$/.test(t)),
                "want": [true]
            },
            {
                "name": "a hidden widget leaves no gap in the row, the rest slide left",
                "got": root.layout(root.grid("acc-hid", "row")),
                "want": [["a", 0, 0, 1, 1, false], ["b", 1, 0, 2, 1, false]]
            },
            {
                "name": "hidden widgets take their rows with them in the detail, dimmed ones keep their place",
                "got": [root.layout(root.grid("acc-hid", "detail")), root.grid("acc-hid", "detail")?.rowsUsed],
                "want": [[["dim", 0, 0, 2, 1, true], ["media", 2, 0, 2, 1, true], ["d", 0, 1, 4, 1, false]], 2]
            },
            {
                "name": "a dimmed widget fades and a missing media widget says nothing is playing",
                "got": [hidMedia?.opacity, Items.byName(hidMedia, "tilePlaceholder")[0]?.visible, Items.findAll(hidMedia, it => it.text === "Nothing playing" && it.visible).length],
                "want": [0.4, true, 1]
            },
            {
                "name": "a form missing or foreign to its type falls back to the type's first",
                "got": root.tilesOf("acc-mia", "row").map(t => t.form),
                "want": ["text", "cover", "banner"]
            },
            {
                "name": "until after the moment and since before it are no data, auto picks the side",
                "got": ["until_past", "since_future", "auto_future", "auto_past"].map(id => root.tile("acc-mia", "detail", root.source(id))).map(t => [t?.dimmed, t?.valueText]),
                "want": [[true, "-"], [true, "-"], [false, "in 10 min"], [false, "10 min ago"]]
            },
            {
                "name": "each color role paints the tile with its Material color and its on-color",
                "got": colored.map(t => [String(t.tint) === String(Appearance.colors[root.colorKeys[root.colorRoles.indexOf(t.widget.color)]]), String(t.contentColor) === String(Appearance.colors[root.colorKeys[root.colorRoles.indexOf(t.widget.color)].replace("col", "colOn")])]),
                "want": root.colorRoles.map(() => [true, true])
            },
            {
                "name": "a tile without a color sits on the neutral layer",
                "got": String(root.tile("acc-mia", "detail", root.source("auto_past"))?.tint),
                "want": String(Appearance.colors.colLayer2)
            },
            {
                "name": "a music and a url background show the picture behind the tile with white content",
                "got": [music, linked].map(t => [t?.backdropShown, String(t?.contentColor)]),
                "want": [[true, "#ffffff"], [true, "#ffffff"]]
            },
            {
                "name": "poster and sleeve draw on a tall place and fall back to cover and vinyl on a small one",
                "got": [discRow, discDetail].map(ts => ts.map(t => [t.form, Items.byName(t, "tileForm")[0]?.file])),
                "want": [[["poster", "TileCover.qml"], ["sleeve", "TileVinyl.qml"]], [["poster", "TilePoster.qml"], ["sleeve", "TileSleeve.qml"], ["poster", "TilePoster.qml"]]]
            },
            {
                "name": "a poster covers its whole tile, a music tile takes the cover's tint unless it has its own color",
                "got": [discDetail[0].fullBleed, discRow[0].fullBleed, discDetail[1].mediaTinted, discDetail[2].mediaTinted],
                "want": [true, false, true, false]
            },
            {
                "name": "a YouTube tile keeps its own color and draws a red play button in place of the missing art",
                "got": [tube?.mediaTinted, String(tube?.artPlaceholder), String(tube?.artAccent)],
                "want": [false, String(tube?.youtubeRed), "#ffffff"]
            },
            {
                "name": "a vinyl treats a video as nothing playing",
                "got": [tube?.dimmed, tubeVinyl?.dimmed, tubeVinyl?.media],
                "want": [false, true, null]
            },
            {
                "name": "a background with no picture yet leaves the tile in its own color",
                "got": [quiet?.backdropShown, String(quiet?.contentColor)],
                "want": [false, String(Appearance.colors.colOnLayer2)]
            }
        ];
    }

    DemoCoverSeed {
        onSeeded: Fresence.ingest(JSON.stringify(root.snapshot))
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        ColumnLayout {
            Layout.preferredWidth: (root.width - 36) / 2
            Layout.alignment: Qt.AlignTop
            spacing: 12

            PresenceRow {
                Layout.fillWidth: true
                modelData: "acc-ada"
                showDetails: true
            }

            PresenceRow {
                Layout.fillWidth: true
                modelData: "acc-disc"
                showDetails: true
            }
        }

        ColumnLayout {
            Layout.preferredWidth: (root.width - 36) / 2
            Layout.alignment: Qt.AlignTop
            spacing: 12

            PresenceRow {
                Layout.fillWidth: true
                modelData: "acc-hid"
                showDetails: true
            }

            PresenceRow {
                Layout.fillWidth: true
                modelData: "acc-mia"
                showDetails: true
            }

            PresenceRow {
                Layout.fillWidth: true
                modelData: "acc-backdrop"
                showDetails: true
            }

            PresenceRow {
                Layout.fillWidth: true
                modelData: "acc-tube"
                showDetails: true
            }
        }
    }
}
