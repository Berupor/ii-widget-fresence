pragma ComponentBehavior: Bound

import QtMultimedia
import QtQuick

/** Kept out of TileClip.qml and CardTile.qml, so a build without qt6-multimedia fails only this Loader.setSource() and callers fall back to their plain circle. */
Item {
    id: root
    required property var card
    property bool autoLoop: true
    property bool settles: Fresence.opt("pauseGifs")
    property int settleSeconds: Fresence.opt("gifPauseSeconds")

    readonly property string path: root.card.clipFile
    readonly property bool onScreen: root.card.animating
    property bool settled: false
    property bool settleDue: false
    readonly property bool shouldLoop: root.autoLoop && root.onScreen && !root.settled && root.path.length > 0
    property bool withSound: false
    property real lastPosition: 0

    function seekToStart(): void {
        root.lastPosition = 0;
        player.position = 0;
    }

    function replay(): void {
        root.withSound = true;
        sound.muted = false;
        root.seekToStart();
        player.play();
    }

    function rest(): void {
        root.settleDue = false;
        sound.muted = true;
        root.seekToStart();
        if (root.shouldLoop)
            player.play();
        else
            player.pause();
    }

    // A StoppedState leaves the output blank, so every pass ends on this wrap to the first frame instead of on a stop
    function passEnded(): void {
        if (root.withSound) {
            root.withSound = false;
            root.settled = root.settles;
            root.rest();
        } else if (root.settleDue) {
            root.settled = true;
        }
    }

    onShouldLoopChanged: root.rest()
    onOnScreenChanged: if (root.onScreen)
        root.settled = false

    Timer {
        running: root.settles && root.shouldLoop && !root.withSound
        interval: root.settleSeconds * 1000
        onTriggered: root.settleDue = true
    }

    MediaPlayer {
        id: player
        source: root.path.length > 0 ? Qt.resolvedUrl(root.path) : ""
        videoOutput: output
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            id: sound
            muted: true
        }

        onMediaStatusChanged: if (player.mediaStatus === MediaPlayer.LoadedMedia)
            root.rest()
        onPositionChanged: {
            const wrapped = player.position < root.lastPosition;
            root.lastPosition = player.position;
            if (wrapped)
                root.passEnded();
        }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
