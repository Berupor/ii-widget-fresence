pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import "ArtPalette.mjs" as Palette
import "CardLayouts.js" as CardLayouts

/**
 * Colors taken from a picture, as app/shared ui/card/ArtPalette.kt does for music and
 * game tiles: the theme color of the picture at `url` (scored quantization of a 64 px
 * copy) decides fill, content, accent and shade. Until the picture is sampled the colors
 * are the neutral ones, a picture that cannot be read falls back to the hue of `key`.
 */
Item {
    id: root
    property string url
    property string key
    readonly property string artKey: CardLayouts.artKey(root.url)
    property color neutralContent: Appearance.colors.colOnLayer1
    property bool neutral: false

    property string sampled: Palette.remembered(root.artKey) ?? ""
    readonly property string seed: root.url.length === 0 ? Palette.artlessSeed(root.key) : root.sampled
    readonly property bool tinted: !root.neutral && root.seed.length > 0
    readonly property var tones: root.tinted ? Palette.palette(root.seed, Appearance.m3colors.darkmode) : null

    readonly property color fill: root.tones?.fill ?? "transparent"
    readonly property color content: root.tones?.content ?? root.neutralContent
    readonly property color accent: root.tones?.accent ?? root.neutralContent
    readonly property color shade: root.tones?.shade ?? "black"

    onArtKeyChanged: root.sampled = Palette.remembered(root.artKey) ?? ""

    readonly property bool wanted: !root.neutral && root.url.length > 0 && root.sampled.length === 0
    readonly property string seedPath: FileUtils.trimFileProtocol(`${Directories.cache}/media/coverseed/${Qt.md5(root.artKey)}`)
    readonly property string cacheFilePath: fetcher.item?.cacheFilePath ?? ""
    readonly property bool downloaded: fetcher.item?.downloaded ?? false

    function adopt(seed: string): void {
        const color = seed || Palette.artlessSeed(root.key);
        Palette.remember(root.artKey, color);
        root.sampled = color;
    }

    function store(seed: string): void {
        if (seed.length > 0)
            Quickshell.execDetached(["bash", "-c", 'mkdir -p "$(dirname "$1")" && printf %s "$2" > "$1"', "_", root.seedPath, seed]);
    }

    FileView {
        id: seedFile
        property bool missing: false
        path: root.wanted ? root.seedPath : ""
        printErrors: false
        onPathChanged: seedFile.missing = false
        onLoaded: root.adopt(seedFile.text().trim())
        onLoadFailed: seedFile.missing = true
    }

    Loader {
        id: fetcher
        active: root.wanted && seedFile.missing
        sourceComponent: ArtDownload {
            source: root.url
        }
    }

    Loader {
        active: root.downloaded && root.wanted
        sourceComponent: Item {
            Process {
                running: true
                command: ["magick", `${root.cacheFilePath}[0]`, "-resize", "64x64>", "-alpha", "off", "-depth", "8", "-compress", "none", "ppm:-"]
                stdout: StdioCollector {
                    onStreamFinished: worker.sendMessage(text)
                }
            }

            WorkerScript {
                id: worker
                source: "ArtPaletteWorker.mjs"
                onMessage: seed => {
                    root.store(seed);
                    root.adopt(seed);
                }
            }
        }
    }
}
