pragma ComponentBehavior: Bound

import QtMultimedia
import QtQuick

/** Kept out of TileClip.qml and CardTile.qml, so a build without qt6-multimedia fails only this Loader.setSource() and callers fall back to their plain circle. */
Item {
    id: root
    required property var card
    property bool autoLoop: true

    readonly property string path: root.card.clipFile
    readonly property bool shouldLoop: root.autoLoop && root.card.animating && root.path.length > 0
    property bool withSound: false

    function replay(): void {
        root.withSound = true;
        player.loops = 1;
        sound.muted = false;
        player.position = 0;
        player.play();
    }

    function rest(): void {
        player.loops = root.autoLoop ? MediaPlayer.Infinite : 1;
        sound.muted = true;
        player.position = 0;
        player.play();
        if (!root.shouldLoop)
            player.pause();
    }

    onShouldLoopChanged: root.rest()

    MediaPlayer {
        id: player
        source: root.path.length > 0 ? Qt.resolvedUrl(root.path) : ""
        videoOutput: output
        audioOutput: AudioOutput {
            id: sound
            muted: true
        }

        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia)
            root.rest()
        onPlaybackStateChanged: if (playbackState === MediaPlayer.StoppedState && root.withSound) {
            root.withSound = false;
            root.rest();
        }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
}
