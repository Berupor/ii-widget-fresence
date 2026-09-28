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
    readonly property bool placeholder: root.dimmed && root.type !== "value"
    readonly property bool fullBleed: CardLayouts.fullBleed(root.widget) && !root.placeholder
    readonly property bool wide: root.width > root.height

    readonly property var state: root.device?.state ?? null
    readonly property var value: CardLayouts.valueOf(root.widget, root.state)
    readonly property var media: root.state?.media ?? null
    readonly property var game: root.state?.game ?? null
    readonly property var photo: root.state?.photo ?? null
    readonly property string photoFile: root.device?.photo_file ?? ""

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
        return root.value.text || (root.value.fill !== undefined ? `${Math.round(root.value.fill * 100)}%` : "-");
    }
    readonly property real fill: Math.max(0, Math.min(1, root.value?.fill ?? 0))
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
    readonly property color tint: Appearance.colors[root.colorKeys[0]]
    readonly property color contentColor: root.fullBleed ? "white" : Appearance.colors[root.colorKeys[1]]
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

    readonly property real radius: Appearance.rounding.large
    readonly property bool showsSky: root.type === "value" && root.form === "weather_live"

    Rectangle {
        visible: !root.fullBleed
        anchors.fill: parent
        radius: root.radius
        color: root.tint
    }

    Item {
        id: surface
        anchors.fill: parent

        layer.enabled: root.fullBleed || root.showsSky
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
                value: root.value?.text ?? ""
                tint: root.tint
                contentColor: root.contentColor
                running: root.animating
                animPhase: root.skyAnimPhase
            }
        }

        readonly property real inset: root.fullBleed ? 0 : Math.max(4, Math.round(Math.min(root.width, root.height) * 0.1))

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
                    text: ({
                            "media": "music_off",
                            "game": "sports_esports",
                            "photo": "photo_camera",
                            "image": "image"
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
                    text: ({
                            "media": Translation.tr("Nothing playing"),
                            "game": Translation.tr("Not in a game"),
                            "photo": Translation.tr("No photo"),
                            "image": Translation.tr("No picture")
                        })[root.type] ?? ""
                }
            }
        }
    }
}
