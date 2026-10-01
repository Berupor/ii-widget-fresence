pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects

/** Rounded album art with a music note fallback; an animated cover plays as a GIF. */
Rectangle {
    id: root
    required property string source
    property list<string> fallbacks: []
    property string fallbackIcon: root.mediaSymbol
    property color fallbackColor: Appearance.colors.colSubtext
    property real fallbackLift: 0
    property var media: null
    property real glyphSize: Math.round(root.height * 0.4)
    property int fillMode: Image.PreserveAspectCrop
    property string fit: "cover"
    property int horizontalAlignment: Image.AlignHCenter
    property int verticalAlignment: Image.AlignVCenter

    readonly property int effectiveFillMode: root.fit === "stretch" ? Image.Stretch : root.fit === "blur" ? Image.PreserveAspectFit : root.fillMode

    radius: 10
    color: Qt.alpha(Appearance.colors.colOnLayer2, root.backingAlpha)

    readonly property real backingAlpha: 0.08
    readonly property real idleAlpha: 0.7
    readonly property real idleSaturation: 0.15
    readonly property real idleGlyphAlpha: 0.55
    readonly property bool idle: root.media !== null && root.media.playing !== true
    readonly property string mediaSymbol: root.media?.kind === "video" ? "smart_display" : "music_note"

    property bool playing: true
    property bool settleGif: false
    property int settleSeconds: 4
    readonly property int status: image.item?.status ?? Image.Null
    readonly property real heightPerWidth: (image.item?.implicitWidth ?? 0) > 0 ? image.item.implicitHeight / image.item.implicitWidth : -1

    readonly property bool downloaded: download.downloaded
    readonly property bool isGif: download.isGif

    readonly property string resolvedSource: root.downloaded ? Qt.resolvedUrl(download.cacheFilePath) : ""
    readonly property int sizeStep: 64
    readonly property int pixelWidth: root.quantized(root.width)
    readonly property int pixelHeight: root.quantized(root.height)

    function quantized(size: real): int {
        return Math.ceil(size * Screen.devicePixelRatio / root.sizeStep) * root.sizeStep;
    }

    ArtDownload {
        id: download
        source: root.source
        fallbacks: root.fallbacks
    }

    Item {
        id: picture
        anchors.fill: parent

        opacity: root.idle ? root.idleAlpha : 1
        layer.enabled: root.idle
        layer.effect: HueSaturation {
            saturation: root.idleSaturation - 1
        }

        Item {
            id: blurBackdrop
            objectName: "pictureFitBackdrop"
            // layer.enabled hides its own source item to show the blurred copy in its place -
            // binding that item's own visible would fight that, so the fit switch lives here.
            visible: root.fit === "blur"
            anchors.fill: parent

            Image {
                objectName: "pictureFitBackdrop"
                anchors.fill: parent
                asynchronous: true
                cache: false
                source: root.fit === "blur" ? root.resolvedSource : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 64
                sourceSize.height: 64

                layer.enabled: true
                layer.effect: FastBlur {
                    radius: 48
                }
            }
        }

        Loader {
            id: image
            anchors.fill: parent
            sourceComponent: root.isGif ? animatedArt : staticArt

            layer.enabled: root.radius > 0 || root.fit === "blur"
            layer.effect: OpacityMask {
                maskSource: PictureFitFeatherMask {
                    objectName: "pictureFitFeather"
                    width: image.width
                    height: image.height
                    radius: root.radius
                    paintedWidth: root.fit === "blur" ? image.item?.paintedWidth ?? image.width : image.width
                    paintedHeight: root.fit === "blur" ? image.item?.paintedHeight ?? image.height : image.height
                }
            }
        }
    }

    Component {
        id: staticArt
        StyledImage {
            source: root.resolvedSource
            fillMode: root.effectiveFillMode
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            sourceSize.width: root.pixelWidth
            sourceSize.height: root.pixelHeight
            cache: true
        }
    }

    Component {
        id: animatedArt
        AnimatedImage {
            id: gif
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
            source: root.resolvedSource
            fillMode: root.effectiveFillMode
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            // QMovie scales to sourceSize exactly, ignoring aspect, and takes 0x0 as a real size; -1 decodes at native size.
            sourceSize.width: root.fit === "stretch" ? root.pixelWidth : -1
            sourceSize.height: root.fit === "stretch" ? root.pixelHeight : -1
            cache: true
            playing: root.playing

            property bool stopAtFirstFrame: false

            function restartSettle(): void {
                gif.stopAtFirstFrame = false;
                gif.paused = false;
                settleTimer.restart();
            }

            Component.onCompleted: if (root.settleGif && gif.playing)
                gif.restartSettle()

            onPlayingChanged: {
                if (!root.settleGif)
                    return;
                if (gif.playing)
                    gif.restartSettle();
                else
                    settleTimer.stop();
            }

            onCurrentFrameChanged: if (gif.stopAtFirstFrame && gif.currentFrame === 0)
                gif.paused = true

            Timer {
                id: settleTimer
                interval: root.settleSeconds * 1000
                onTriggered: gif.stopAtFirstFrame = gif.frameCount > 1
            }
        }
    }

    MaterialSymbol {
        visible: root.status !== Image.Ready && root.fallbackIcon.length > 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.fallbackLift
        iconSize: root.glyphSize
        color: Qt.alpha(root.fallbackColor, root.idle ? root.idleGlyphAlpha : 1)
        text: root.fallbackIcon
    }
}
