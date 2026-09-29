pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts
import "CardRules.js" as Rules

/** One widget of a card, by protocol.md: the form file draws it, this is what the form reads. */
Item {
    id: root
    required property var widget
    required property var device
    property bool dimmed: false
    property real skyAnimPhase: -1

    readonly property string type: root.widget?.type ?? ""
    readonly property string form: CardLayouts.shownForm(root.widget)
    readonly property bool animating: root.visible && root.Window.visibility !== Window.Hidden
    readonly property bool hasData: !root.dimmed
    readonly property bool unrecognized: root.type !== "" && !CardLayouts.knownType(root.type)
    readonly property bool placeholder: root.unrecognized || (root.dimmed && root.type !== "value" && root.type !== "weather")
    readonly property bool fullBleed: CardLayouts.fullBleed(root.widget) && !root.placeholder
    readonly property bool wide: root.width > root.height
    readonly property bool edgeToEdge: CardLayouts.edgeToEdge(root.widget) && !root.placeholder
    readonly property real tileInset: CardLayouts.tileInset(root.width, root.height, root.shape)
    readonly property string chessModeText: ({
            "rapid": Translation.tr("Rapid"),
            "blitz": Translation.tr("Blitz"),
            "bullet": Translation.tr("Bullet"),
            "daily": Translation.tr("Daily")
        })[root.chess?.mode] ?? ""

    readonly property var state: root.device?.state ?? null
    readonly property var value: CardLayouts.valueOf(root.widget, root.state)
    readonly property var media: CardLayouts.mediaOf(root.widget, root.state)
    readonly property var game: root.state?.game ?? null
    readonly property var weather: root.state?.weather ?? null
    readonly property var chess: root.state?.chess ?? null
    readonly property var photo: root.state?.photo ?? null
    readonly property string photoFile: root.device?.photo_file ?? ""
    readonly property string clipFile: root.device?.clip_file ?? ""

    readonly property bool backdropIsPhoto: CardLayouts.backgroundIsPhoto(root.widget, root.device, Fresence.now)
    readonly property bool backdropIsClip: CardLayouts.backgroundIsClip(root.widget, root.device, Fresence.now)
    readonly property string backdropUrl: root.backdropIsPhoto || root.backdropIsClip ? "" : CardLayouts.backgroundUrl(root.widget, root.device)
    readonly property bool hasBackdropSource: root.backdropIsPhoto || root.backdropIsClip || CardLayouts.isHttpsUrl(root.backdropUrl)
    readonly property bool backdropShown: root.hasBackdropSource && backdropLoader.item?.status !== Image.Error

    readonly property bool ticks: root.animating && root.hasData && ((root.type === "value" && root.form === "timer") || root.type === "game" || (root.type === "media" && root.media?.playing === true))
    property real tickNow: 0
    readonly property real now: Math.max(Fresence.now, root.tickNow)

    Timer {
        interval: 1000
        running: root.ticks
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tickNow = Date.now()
    }

    readonly property real valueTimeMs: root.value?.time !== undefined ? Date.parse(root.value.time) : NaN
    readonly property string timeDirection: CardLayouts.timeDirection(root.widget?.time_mode, root.valueTimeMs, root.now)
    readonly property string valueText: {
        if (!root.value)
            return "-";
        if (!isNaN(root.valueTimeMs)) {
            if (root.timeDirection === "until")
                return Fresence.inText(root.valueTimeMs);
            return root.timeDirection === "since" ? Fresence.agoText(root.valueTimeMs) : "-";
        }
        return CardLayouts.bytesText(root.value) || root.value.text || (root.value.fill !== undefined ? `${Math.round(root.value.fill * 100)}%` : "-");
    }
    readonly property real fill: Math.max(0, Math.min(1, root.value?.fill ?? 0))
    readonly property string subtext: root.value?.subtext ?? ""
    readonly property string shortValueText: root.hasData ? (CardLayouts.compactBytesText(root.value) || root.shownValueText) : "-"
    readonly property string ringIcon: root.icon || (Rules.sourceSymbols[root.widget?.source] ?? "")
    readonly property string labelText: root.widget?.label ?? ""
    readonly property string icon: root.widget?.icon ?? ""
    readonly property string labelIcon: root.icon && ((root.widget?.place?.cols ?? 1) > 1 || !root.labelText) ? root.icon : ""
    readonly property string shownValueText: root.hasData ? root.withSymbolsAttached(root.valueText) : "-"

    readonly property var symbolCodeRanges: [[0x21, 0x2F], [0x3A, 0x40], [0x5B, 0x60], [0x7B, 0x7E], [0x2000, 0x2BFF], [0xFE00, 0xFE0F], [0x1F000, 0x1FAFF]]

    function isSymbol(token: string): bool {
        return [...token].every(ch => root.symbolCodeRanges.some(([from, to]) => ch.codePointAt(0) >= from && ch.codePointAt(0) <= to));
    }

    function withSymbolsAttached(text: string): string {
        const nbsp = " ";
        return text.replace(/^(\S+) +(?=\S)/, (whole, first) => root.isSymbol(first) ? first + nbsp : whole).replace(/(\S) +(\S+)$/, (whole, before, last) => root.isSymbol(last) ? before + nbsp + last : whole);
    }

    readonly property var colorKeys: CardLayouts.colorKeysOf(root.widget?.color)
    readonly property bool youtube: root.type === "media" && /youtube/i.test(root.media?.player ?? "")
    readonly property color youtubeRed: "#c94f4f"
    readonly property bool paletteFromMedia: root.type === "media" && !!root.media && !root.youtube && !root.widget?.color && !root.widget?.background
    readonly property bool mediaTinted: root.paletteFromMedia && mediaArt.tinted
    readonly property color tint: root.mediaTinted ? mediaArt.fill : Appearance.colors[root.colorKeys[0]]
    readonly property color contentColor: root.fullBleed || root.backdropShown ? "white" : (root.mediaTinted ? mediaArt.content : Appearance.colors[root.colorKeys[1]])
    readonly property color artPlaceholder: root.youtube ? root.youtubeRed : root.mediaTinted ? ColorUtils.mix(mediaArt.fill, mediaArt.content, 0.9) : Appearance.colors.colLayer1
    readonly property color artAccent: root.youtube ? "white" : root.mediaTinted ? mediaArt.accent : Appearance.colors.colSubtext

    readonly property alias mediaPalette: mediaArt

    ArtPalette {
        id: mediaArt
        url: root.paletteFromMedia ? (root.media.art_url ?? "") : ""
        key: root.paletteFromMedia ? (root.media.artist || root.media.title || "") : ""
        neutral: !root.paletteFromMedia
    }
    readonly property color mutedContentColor: ColorUtils.transparentize(root.contentColor, 0.35)

    readonly property real dimmedOpacity: 0.45
    opacity: root.dimmed ? root.dimmedOpacity : 1

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    readonly property string shape: CardLayouts.shownShape(root.widget)
    readonly property bool polygonMasked: root.shape === "cookie" || root.shape === "clover"
    readonly property real radius: root.shape === "circle" ? Math.min(root.width, root.height) / 2 : Appearance.rounding.large
    readonly property bool showsSky: root.type === "weather" && root.form === "sky"

    // CardLayouts.shownShape only ever resolves to cookie/clover on a square place, so
    // the polygon mask can stretch to the full tile without distortion.
    Item {
        id: shaped
        anchors.fill: parent

        layer.enabled: root.polygonMasked
        layer.effect: OpacityMask {
            maskSource: MaterialShape {
                width: shaped.width
                height: shaped.height
                shape: root.shape === "cookie" ? MaterialShape.Shape.Cookie9Sided : MaterialShape.Shape.Clover4Leaf
            }
        }

        Rectangle {
            visible: !root.fullBleed
            anchors.fill: parent
            radius: root.radius
            color: root.tint
        }

        Item {
            id: surface
            anchors.fill: parent

            layer.enabled: root.fullBleed || root.edgeToEdge || root.showsSky || root.hasBackdropSource
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: surface.width
                    height: surface.height
                    radius: root.radius
                }
            }

            Loader {
                objectName: "tileWeatherSky"
                anchors.fill: parent
                active: root.showsSky

                sourceComponent: WeatherSky {
                    weather: root.weather
                    tint: root.tint
                    contentColor: root.contentColor
                    running: root.animating
                    animPhase: root.skyAnimPhase
                }
            }

            Loader {
                id: backdropLoader
                objectName: "tileBackdrop"
                anchors.fill: parent
                active: root.hasBackdropSource
                sourceComponent: root.backdropIsPhoto ? backdropPhoto : (root.backdropIsClip ? backdropClip : backdropArt)
            }

            Component {
                id: backdropArt
                PresenceArt {
                    radius: 0
                    color: "transparent"
                    fallbackIcon: ""
                    source: root.backdropUrl
                    playing: root.animating
                    settleGif: Fresence.opt("pauseGifs")
                    settleSeconds: Fresence.opt("gifPauseSeconds")
                }
            }

            Component {
                id: backdropPhoto
                LocalPicture {
                    sourcePath: root.photoFile
                    playing: root.animating
                    settleGif: Fresence.opt("pauseGifs")
                    settleSeconds: Fresence.opt("gifPauseSeconds")
                }
            }

            Component {
                id: backdropClip
                Item {
                    id: clipBackdrop
                    anchors.fill: parent

                    Loader {
                        id: clipVideo
                        anchors.fill: parent

                        function load(): void {
                            clipVideo.setSource(Qt.resolvedUrl("TileClipVideo.qml"), {
                                "card": root,
                                "autoLoop": false
                            });
                        }

                        Component.onCompleted: clipVideo.load()
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: clipVideo.status === Loader.Ready
                        onClicked: clipVideo.item.replay()
                    }
                }
            }

            Rectangle {
                objectName: "tileBackdropScrim"
                anchors.fill: parent
                visible: root.backdropShown
                color: Qt.rgba(0, 0, 0, 0.55)
            }

            readonly property real inset: root.fullBleed || root.edgeToEdge ? 0 : root.tileInset

            Item {
                id: content
                x: surface.inset
                y: surface.inset
                width: Math.max(0, root.width - 2 * surface.inset)
                height: Math.max(0, root.height - 2 * surface.inset)
                clip: true

                Loader {
                    id: formLoader
                    objectName: "tileForm"
                    anchors.fill: parent
                    readonly property string file: root.placeholder ? "" : CardLayouts.formFile(root.widget)

                    function load(): void {
                        formLoader.setSource(formLoader.file ? Qt.resolvedUrl(formLoader.file) : "", {
                            "card": root
                        });
                    }

                    onFileChanged: formLoader.load()
                    Component.onCompleted: formLoader.load()
                }

                ColumnLayout {
                    objectName: "tilePlaceholder"
                    visible: root.placeholder
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 2

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.unrecognized ? "system_update" : ({
                                "media": "music_off",
                                "game": "sports_esports",
                                "photo": "photo_camera",
                                "clip": "videocam",
                                "image": "image",
                                "clock": "schedule",
                                "chess": "chess_queen"
                            })[root.type] ?? "block"
                        iconSize: Appearance.font.pixelSize.larger
                        color: root.mutedContentColor
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: root.height >= 64
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.mutedContentColor
                        text: root.unrecognized ? Translation.tr("Update the app") : ({
                                "media": Translation.tr("Nothing playing"),
                                "game": Translation.tr("Not in a game"),
                                "photo": Translation.tr("No photo"),
                                "clip": Translation.tr("No clip"),
                                "image": Translation.tr("No picture"),
                                "chess": Translation.tr("No games"),
                                "clock": Translation.tr("No time zone")
                            })[root.type] ?? ""
                    }
                }
            }
        }
    }
}
