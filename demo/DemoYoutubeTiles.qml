//@ probe fresence -g 1180x900 -s 3000
/** The YouTube video tile (TileVideo.qml) at 1x1, 2x1, 2x2, 4x1 and 4x2: with and without a frame, paused, live, and what counts as YouTube. */
import ".."
import "lib"
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoCovers.js" as DemoCovers
import "../CardLayouts.js" as CardLayouts
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now

    property bool seeded: false
    readonly property real unit: 78
    readonly property real gap: 8
    readonly property var sizes: [[1, 1], [2, 1], [2, 2], [4, 1], [4, 2]]
    readonly property string frameUrl: DemoCovers.url("rdr2-header.jpg")
    readonly property var video: ({
            "kind": "video",
            "player": "plasma-browser-integration",
            "url": "https://www.youtube.com/watch?v=9-2CSJC114k"
        })
    readonly property var variants: [
        {
            "name": "frame",
            "media": Demo.playing("48 hours in Lisbon: what to see", "Maya Travels", root.frameUrl, 374000, 1104000, root.video)
        },
        {
            "name": "paused",
            "media": Demo.playing("48 hours in Lisbon: what to see", "Maya Travels", root.frameUrl, 374000, 1104000, Object.assign({
                "playing": false
            }, root.video))
        },
        {
            "name": "logo",
            "media": Demo.playing("48 hours in Lisbon: what to see", "Maya Travels", undefined, 374000, 1104000, root.video)
        },
        {
            "name": "logoPaused",
            "media": Demo.playing("48 hours in Lisbon: what to see", "Maya Travels", undefined, 374000, 1104000, Object.assign({
                "playing": false
            }, root.video))
        },
        {
            "name": "live",
            "media": Demo.playing("lofi radio 24/7 - beats to relax and study to", "Lofi Girl", root.frameUrl, undefined, undefined, Object.assign({
                "position_ms": undefined,
                "position_at": undefined
            }, root.video))
        }
    ]
    readonly property var wall: root.variants.map(variant => root.sizes.map(([cols, rows]) => root.tile(variant, cols, rows)))

    function tile(variant, cols, rows) {
        const id = `dev-${variant.name}-${cols}x${rows}`;
        return {
            "id": id,
            "widget": Demo.widget("media", [0, 0, cols, rows], {
                "form": "player"
            }),
            "device": {
                "device_id": id,
                "online": true,
                "state": {
                    "media": variant.media
                }
            }
        };
    }

    function tileOf(name, cols, rows) {
        return Items.tiles(wallView).find(t => t.device.device_id === `dev-${name}-${cols}x${rows}`) ?? null;
    }

    function part(name, cols, rows, objectName) {
        return Items.byName(root.tileOf(name, cols, rows), objectName).find(item => item.visible) ?? null;
    }

    function shown(name, cols, rows, objectName) {
        return root.part(name, cols, rows, objectName)?.text ?? null;
    }

    function fillOf(name, cols, rows) {
        const fill = root.part(name, cols, rows, "videoEdgeFill");
        return fill ? Math.round(fill.width / fill.parent.width * 100) : null;
    }

    function checks() {
        const all = [[1, 1], [2, 1], [2, 2], [4, 1], [4, 2]];
        return [
            {
                "name": "every YouTube video loads the video form on every size",
                "got": [Items.tiles(wallView).length, Items.brokenForms(wallView), Items.byName(wallView, "tileForm").every(l => l.file === "TileVideo.qml")],
                "want": [root.variants.length * root.sizes.length, [], true]
            },
            {
                "name": "a video is YouTube by its player or its url, a music track and another video are not",
                "got": [
                    CardLayouts.isYoutube({
                        "kind": "video",
                        "player": "com.google.android.youtube"
                    }),
                    CardLayouts.isYoutube({
                        "kind": "video",
                        "player": "firefox",
                        "url": "https://youtu.be/9-2CSJC114k"
                    }),
                    CardLayouts.isYoutube({
                        "kind": "video",
                        "player": "mpv"
                    }),
                    CardLayouts.isYoutube({
                        "kind": "music",
                        "player": "youtube"
                    })
                ],
                "want": [true, true, false, false]
            },
            {
                "name": "a 1x1 is the frame alone, every other size has a title",
                "got": all.map(([c, r]) => root.part("frame", c, r, "videoTitle") !== null),
                "want": [false, true, true, true, true]
            },
            {
                "name": "the badge shows the time left on 2x2 and 4x1, the length on 4x2, none on 1x1 and 2x1",
                "got": all.map(([c, r]) => root.shown("frame", c, r, "videoBadge")),
                "want": [null, null, "-12:10", "-12:10", "18:24"]
            },
            {
                "name": "the red edge bar is watched share of the length on 1x1, 2x2 and 4x1, none on 2x1 and 4x2",
                "got": all.map(([c, r]) => root.fillOf("frame", c, r)),
                "want": [34, null, 34, 34, null]
            },
            {
                "name": "a paused video draws a white edge bar and a playing one a red one",
                "got": ["paused", "frame"].map(n => String(root.part(n, 2, 2, "videoEdgeFill").color)),
                "want": ["#ffffff", "#ff0033"]
            },
            {
                "name": "the 2x1 shows the title and the red progress, the channel only with no position",
                "got": [root.part("frame", 2, 1, "videoProgress") !== null, root.part("frame", 2, 1, "videoChannel") === null, root.part("live", 2, 1, "videoProgress") === null, root.shown("live", 2, 1, "videoChannel")],
                "want": [true, true, true, "Lofi Girl"]
            },
            {
                "name": "the 4x2 has a position, a progress bar and the time left across the bottom",
                "got": [root.shown("frame", 4, 2, "videoPosition"), root.part("frame", 4, 2, "videoProgress") !== null, root.shown("frame", 4, 2, "videoRemaining")],
                "want": ["6:14", true, "-12:10"]
            },
            {
                "name": "no art draws the red logo on the dark screen, a frame does not",
                "got": [root.part("logo", 2, 2, "videoLogo") !== null, root.part("frame", 2, 2, "videoLogo") === null, String(root.tileOf("logo", 2, 2).artPlaceholder)],
                "want": [true, true, "#0f0f0f"]
            },
            {
                "name": "a live stream has no badge, no edge bar and keeps the frame",
                "got": all.slice(2).map(([c, r]) => [root.part("live", c, r, "videoBadge"), root.part("live", c, r, "videoEdgeBar")]),
                "want": [[null, null], [null, null], [null, null]]
            }
        ];
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    DemoCoverSeed {
        onSeeded: root.seeded = true
    }

    Column {
        id: wallView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
        spacing: root.gap

        Repeater {
            model: root.seeded ? root.wall : []

            delegate: Row {
                id: line
                required property var modelData
                spacing: root.gap

                Repeater {
                    model: line.modelData

                    delegate: CardTile {
                        id: tileItem
                        required property var modelData
                        width: tileItem.modelData.widget.place.cols * root.unit + (tileItem.modelData.widget.place.cols - 1) * root.gap
                        height: tileItem.modelData.widget.place.rows * root.unit + (tileItem.modelData.widget.place.rows - 1) * root.gap
                        widget: tileItem.modelData.widget
                        device: tileItem.modelData.device
                    }
                }
            }
        }
    }
}
