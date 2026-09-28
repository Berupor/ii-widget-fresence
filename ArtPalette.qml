pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell.Io
import "ArtPalette.js" as Palette

/**
 * Colors taken from a picture, as app/shared ui/card/ArtPalette.kt does for music and
 * game tiles: the average hue of the picture at `url` decides fill, content, accent and
 * shade. Until the picture is sampled the colors are the neutral ones, a picture that
 * cannot be read falls back to the hue of `key`.
 */
Item {
    id: root
    property string url
    property string key
    property color neutralContent: Appearance.colors.colOnLayer1
    property bool neutral: false

    property string sampled: Palette.remembered(root.url) ?? ""
    readonly property string seed: root.url.length === 0 ? Palette.artlessSeed(root.key) : root.sampled
    readonly property bool tinted: !root.neutral && root.seed.length > 0
    readonly property var tones: root.tinted ? Palette.palette(root.seed, Appearance.m3colors.darkmode) : null

    readonly property color fill: root.tones?.fill ?? "transparent"
    readonly property color content: root.tones?.content ?? root.neutralContent
    readonly property color accent: root.tones?.accent ?? root.neutralContent
    readonly property color shade: root.tones?.shade ?? "black"

    onUrlChanged: root.sampled = Palette.remembered(root.url) ?? ""

    PresenceArt {
        id: source
        visible: false
        width: 1
        height: 1
        source: root.url
    }

    Process {
        id: sampler
        readonly property string file: source.cacheFilePath
        running: !root.neutral && root.url.length > 0 && root.sampled.length === 0 && source.downloaded
        command: ["magick", `${sampler.file}[0]`, "-resize", "1x1!", "-format", "%[hex:p{0,0}]", "info:"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hex = text.trim().slice(0, 6);
                const seed = /^[0-9A-Fa-f]{6}$/.test(hex) ? `#${hex}` : Palette.artlessSeed(root.key);
                Palette.remember(root.url, seed);
                root.sampled = seed;
            }
        }
    }
}
