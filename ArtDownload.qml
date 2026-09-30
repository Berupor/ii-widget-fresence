pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import "CardLayouts.js" as CardLayouts

/** Fetches a picture into the cover cache, trying `source` and then `fallbacks`; `isGif` comes from the file's first bytes. */
Scope {
    id: root
    required property string source
    property list<string> fallbacks: []

    property string cacheFilePath: root.source.length > 0 ? `${Directories.coverArt}/${Qt.md5(root.source)}` : ""
    property bool downloaded: false
    property bool isGif: false

    function fetch(): void {
        if (artDownloader.running || root.cacheFilePath.length === 0)
            return;
        artDownloader.filePath = root.cacheFilePath;
        artDownloader.urls = [root.source, ...root.fallbacks].filter(CardLayouts.isHttpsUrl);
        artDownloader.running = true;
    }

    onCacheFilePathChanged: {
        root.downloaded = false;
        root.isGif = false;
        root.fetch();
    }

    onFallbacksChanged: root.fetch()

    Process {
        id: artDownloader
        property string filePath
        property list<string> urls
        readonly property string script: `
target="$1"; shift
if [ ! -f "$target" ]; then
    for url in "$@"; do
        tmp="$target.$$"
        if curl -4 -fsSL --proto =https --proto-redir =https -m 15 --max-filesize 20M -o "$tmp" -- "$url"; then
            mv "$tmp" "$target"
            break
        fi
        rm -f "$tmp"
    done
fi
head -c4 "$target" 2>/dev/null
`
        command: ["bash", "-c", artDownloader.script, "_", artDownloader.filePath, ...artDownloader.urls]
        stdout: StdioCollector {
            onStreamFinished: if (artDownloader.filePath === root.cacheFilePath)
                root.isGif = text === "GIF8"
        }
        onRunningChanged: {
            if (artDownloader.running)
                return;
            if (artDownloader.filePath === root.cacheFilePath)
                root.downloaded = true;
            else
                root.fetch();
        }
    }
}
