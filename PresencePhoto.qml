pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.widgets
import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects

/** A shared photo from the agent's cache with the time it has left, or a picture by url. */
Rectangle {
    id: root
    property string path: ""
    property real expiresAt: NaN
    property bool cropped: false
    property bool badge: true
    property string shape: "rounded"
    property real tileInset: 0
    property string url: ""
    property string fit: "cover"
    property bool settleGif: false
    property int settleSeconds: 4

    readonly property bool animating: root.visible && root.Window.visibility !== Window.Hidden
    readonly property bool showsUrl: root.url.length > 0
    readonly property var shownImage: root.showsUrl ? remoteImage.item : image
    readonly property int status: root.shownImage?.status ?? Image.Null

    readonly property real backingAlpha: 0.08
    readonly property int minHeight: 100
    readonly property int maxHeight: 320
    // Shared regions come in every shape, so the card follows the image instead of cropping it to a fixed strip
    readonly property real naturalHeight: (root.shownImage?.implicitHeight ?? 0) > 0 ? root.width * root.shownImage.implicitHeight / root.shownImage.implicitWidth : 0

    readonly property real settledHeight: root.naturalHeight > 0 ? Math.round(Math.max(root.minHeight, Math.min(root.maxHeight, root.naturalHeight))) : root.minHeight
    // AnimatedImage re-decodes on every sourceSize change, so the image skips the height ease
    readonly property real imageHeight: root.cropped ? root.height : root.settledHeight

    implicitHeight: root.settledHeight
    radius: Appearance.rounding.normal
    color: Qt.alpha(Appearance.colors.colOnLayer2, root.backingAlpha)

    component ExpiryBadge: Rectangle {
        id: badge
        required property real expiresAt
        property string shape: "rounded"
        property real tileInset: 0
        readonly property real cornerInset: 3
        readonly property real outlineMargin: 2
        readonly property real insetStep: 1
        readonly property real spotWidth: 76
        readonly property real spotHeight: 22
        readonly property var corners: [
            {
                "atEnd": true,
                "atTop": true
            },
            {
                "atEnd": true,
                "atTop": false
            },
            {
                "atEnd": false,
                "atTop": true
            },
            {
                "atEnd": false,
                "atTop": false
            }
        ]
        readonly property var spot: badge.spotFor(badge.parent?.width ?? 0, badge.parent?.height ?? 0)

        function insideCircle(x: real, y: real, width: real, height: real): bool {
            const dx = (x - width / 2) / (width / 2);
            const dy = (y - height / 2) / (height / 2);
            return dx * dx + dy * dy <= 1;
        }

        function fitsCircle(corner: var, inset: real, width: real, height: real): bool {
            const left = (corner.atEnd ? width - inset - badge.spotWidth : inset) - badge.outlineMargin;
            const top = (corner.atTop ? inset : height - inset - badge.spotHeight) - badge.outlineMargin;
            const right = left + badge.spotWidth + 2 * badge.outlineMargin;
            const bottom = top + badge.spotHeight + 2 * badge.outlineMargin;
            const midX = (left + right) / 2;
            const midY = (top + bottom) / 2;
            return [[left, top], [midX, top], [right, top], [right, midY], [right, bottom], [midX, bottom], [left, bottom], [left, midY]].every(p => badge.insideCircle(p[0], p[1], width, height));
        }

        function spotFor(width: real, height: real): var {
            if (badge.shape === "rounded")
                return {
                    "atEnd": true,
                    "atTop": true,
                    "inset": badge.cornerInset
                };
            let best = {
                "atEnd": true,
                "atTop": true,
                "inset": badge.tileInset
            };
            if (badge.shape !== "circle")
                return best;
            for (const corner of badge.corners) {
                for (let inset = badge.cornerInset; inset < best.inset; inset += badge.insetStep) {
                    if (badge.fitsCircle(corner, inset, width, height)) {
                        best = {
                            "atEnd": corner.atEnd,
                            "atTop": corner.atTop,
                            "inset": inset
                        };
                        break;
                    }
                }
            }
            return best;
        }

        x: badge.spot.atEnd ? (badge.parent?.width ?? 0) - badge.width - badge.spot.inset : badge.spot.inset
        y: badge.spot.atTop ? badge.spot.inset : (badge.parent?.height ?? 0) - badge.height - badge.spot.inset
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.4)
        implicitWidth: badgeRow.implicitWidth + 14
        implicitHeight: badgeRow.implicitHeight + 6

        Row {
            id: badgeRow
            x: 6
            y: 3
            spacing: 3

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 12
                color: "white"
                text: "schedule"
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11
                color: "white"
                text: Fresence.leftText(badge.expiresAt)
            }
        }
    }

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Item {
        id: art
        anchors.fill: parent

        layer.enabled: root.radius > 0
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: art.width
                height: art.height
                radius: root.radius
            }
        }

        Loader {
            id: remoteImage
            anchors.fill: parent
            active: root.showsUrl
            sourceComponent: PresenceArt {
                radius: 0
                source: root.url
                playing: root.animating
                fallbackIcon: "image"
                settleGif: root.settleGif
                settleSeconds: root.settleSeconds
                fit: root.fit
            }
        }

        LocalPicture {
            id: image
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: root.imageHeight
            sourcePath: root.path
            playing: root.animating
            settleGif: root.settleGif
            settleSeconds: root.settleSeconds
            thumbnailSizeName: "x-large" // The default sizes itself off sourceSize, which is 0 before the first load
            // Panoramas get letterboxed rather than gutted; anything taller is cropped to maxHeight
            fillMode: !root.cropped && root.naturalHeight > 0 && root.naturalHeight < root.minHeight ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            fit: root.cropped ? root.fit : "cover"
        }
    }

    MaterialSymbol {
        visible: !root.showsUrl && root.status !== Image.Ready
        anchors.centerIn: parent
        iconSize: Math.round(root.height * 0.3)
        color: Appearance.colors.colSubtext
        text: "photo_camera"
    }

    ExpiryBadge {
        visible: root.badge && root.path.length > 0 && !isNaN(root.expiresAt)
        expiresAt: root.expiresAt
        shape: root.shape
        tileInset: root.tileInset
    }
}
