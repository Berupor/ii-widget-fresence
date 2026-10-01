import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

/** A YouTube video: its frame with the time left and a red watched bar, the title and the channel; a 4x2 adds a position row. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property var place: form.card.widget.place
    readonly property bool tracked: CardLayouts.mediaProgress(form.media, form.card.now) >= 0
    readonly property real pad: form.card.tileInset
    readonly property bool bleeds: form.card.shape === "rounded"
    readonly property bool square: !form.card.wide
    readonly property bool cell: form.square && form.card.height < form.tallMinHeight
    readonly property bool poster: form.square && !form.cell
    readonly property bool strip: !form.square && form.place.cols <= CardLayouts.stripMaxCols
    readonly property bool session: !form.square && !form.strip && form.place.cols >= form.sessionMinCols && form.place.rows >= form.sessionMinRows
    readonly property bool row: !form.square && !form.strip && !form.session
    readonly property real tallMinHeight: 120
    readonly property int sessionMinCols: 4
    readonly property int sessionMinRows: 2
    readonly property real frameShare: 0.5
    readonly property real videoAspect: 16 / 9
    readonly property real frameRadius: 8
    readonly property real cellLogoShare: 0.28
    readonly property real frameLogoShare: 0.18
    readonly property real textVertical: 6

    component Frame: Item {
        id: frame
        required property var card
        property real radius: 0
        property real logoHeight: 20
        property bool edgeBar: false
        property real edgeMargin: 0
        property bool badge: true
        property bool remainingBadge: true
        readonly property var media: frame.card.media
        readonly property bool playing: frame.media?.playing === true
        readonly property real fraction: Math.max(0, CardLayouts.mediaProgress(frame.media, frame.card.now))
        readonly property real remainingMs: (frame.media?.length_ms ?? 0) - CardLayouts.mediaPositionMs(frame.media, frame.card.now)
        readonly property bool tracked: CardLayouts.mediaProgress(frame.media, frame.card.now) >= 0
        readonly property real barHeight: 3
        readonly property real trackAlpha: 0.3
        readonly property real logoAspect: 1.42
        readonly property real logoCorner: 0.28
        readonly property real logoGlyph: 0.8
        readonly property real badgeMargin: 4
        readonly property string badgeText: {
            if (frame.remainingBadge && frame.tracked && frame.remainingMs > 0)
                return `-${Fresence.stopwatchText(frame.remainingMs)}`;
            return (frame.media?.length_ms ?? 0) > 0 ? Fresence.stopwatchText(frame.media.length_ms) : "";
        }

        layer.enabled: frame.radius > 0
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: frame.width
                height: frame.height
                radius: frame.radius
            }
        }

        PresenceArt {
            id: art
            anchors.fill: parent
            radius: 0
            source: frame.media?.art_url ?? ""
            media: frame.media
            fallbackIcon: ""
            playing: frame.card.animating
            color: frame.card.youtubeScreen
        }

        Rectangle {
            objectName: "videoLogo"
            visible: art.status !== Image.Ready
            anchors.centerIn: parent
            anchors.verticalCenterOffset: badge.visible ? -Math.max(0, height / 2 + frame.badgeMargin + parent.height / 2 - badge.y) : 0
            width: frame.logoHeight * frame.logoAspect
            height: frame.logoHeight
            radius: frame.logoHeight * frame.logoCorner
            color: frame.card.youtubeRed
            opacity: frame.playing ? 1 : art.idleGlyphAlpha

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: frame.logoHeight * frame.logoGlyph
                color: "white"
                text: frame.playing ? "play_arrow" : "pause"
            }
        }

        Rectangle {
            id: badge
            visible: frame.badge && frame.badgeText.length > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: frame.badgeMargin
            anchors.bottomMargin: frame.badgeMargin + (frame.edgeBar && frame.tracked && frame.remainingBadge ? frame.barHeight : 0)
            width: badgeLabel.implicitWidth + 8
            height: badgeLabel.implicitHeight + 2
            radius: 4
            color: Qt.rgba(0, 0, 0, 0.7)

            StyledText {
                id: badgeLabel
                objectName: "videoBadge"
                anchors.centerIn: parent
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Medium
                color: "white"
                text: frame.badgeText
            }
        }

        Rectangle {
            objectName: "videoEdgeBar"
            visible: frame.edgeBar && frame.tracked
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: frame.edgeMargin
            height: frame.barHeight
            radius: frame.edgeMargin > 0 ? height / 2 : 0
            color: Qt.rgba(1, 1, 1, frame.trackAlpha)

            Rectangle {
                objectName: "videoEdgeFill"
                width: parent.width * frame.fraction
                height: parent.height
                radius: parent.radius
                color: frame.playing ? frame.card.youtubeRed : "white"
            }
        }
    }

    component VideoText: Item {
        id: text
        required property var card
        property int titleLines: 2
        property bool showChannel: true
        property bool alignTop: false
        readonly property var media: text.card.media
        readonly property real gap: 1
        readonly property bool channelFits: text.showChannel && title.implicitHeight + text.gap + channel.implicitHeight <= text.height

        Column {
            width: parent.width
            anchors.top: text.alignTop ? parent.top : undefined
            anchors.verticalCenter: text.alignTop ? undefined : parent.verticalCenter
            spacing: text.gap

            StyledText {
                id: title
                objectName: "videoTitle"
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: text.titleLines
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.pixelSize: 14
                font.weight: Font.Medium
                text: text.media?.title ?? ""
                color: text.card.contentColor
            }
            StyledText {
                id: channel
                objectName: "videoChannel"
                width: parent.width
                visible: text.channelFits && text.media?.artist
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.pixelSize: 12
                text: text.media?.artist ?? ""
                color: text.card.mutedContentColor
            }
        }
    }

    component Progress: RowLayout {
        id: progress
        required property var card
        property bool times: false
        readonly property var media: progress.card.media
        readonly property bool playing: progress.media?.playing === true
        readonly property real positionMs: CardLayouts.mediaPositionMs(progress.media, progress.card.now)
        readonly property real remainingMs: (progress.media?.length_ms ?? 0) - progress.positionMs
        readonly property real timeSize: 11
        spacing: 8

        StyledText {
            objectName: "videoPosition"
            visible: progress.times
            font.pixelSize: progress.timeSize
            color: progress.card.mutedContentColor
            text: Fresence.stopwatchText(progress.positionMs)
        }
        WaveBar {
            objectName: "videoProgress"
            Layout.fillWidth: true
            color: progress.playing ? progress.card.youtubeRed : progress.card.mutedContentColor
            to: 1
            value: Math.max(0, CardLayouts.mediaProgress(progress.media, progress.card.now))
        }
        StyledText {
            objectName: "videoRemaining"
            visible: progress.times && progress.remainingMs > 0
            font.pixelSize: progress.timeSize
            color: progress.card.mutedContentColor
            text: `-${Fresence.stopwatchText(progress.remainingMs)}`
        }
    }

    Frame {
        visible: form.cell
        anchors.fill: parent
        card: form.card
        logoHeight: form.height * form.cellLogoShare
        badge: false
        edgeBar: form.tracked
        edgeMargin: form.bleeds ? 0 : form.pad
    }

    Item {
        visible: form.poster
        anchors.fill: parent

        Frame {
            id: posterFrame
            width: parent.width
            height: width / form.videoAspect
            card: form.card
            logoHeight: width * form.frameLogoShare
            edgeBar: true
        }
        VideoText {
            anchors.top: posterFrame.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: form.pad
            anchors.rightMargin: form.pad
            anchors.topMargin: form.textVertical
            anchors.bottomMargin: form.textVertical
            card: form.card
        }
    }

    Item {
        visible: form.strip
        anchors.fill: parent
        anchors.margins: form.pad

        VideoText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: form.tracked ? stripProgress.top : parent.bottom
            card: form.card
            alignTop: form.tracked
            showChannel: !form.tracked
        }
        Progress {
            id: stripProgress
            visible: form.tracked
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            card: form.card
        }
    }

    RowLayout {
        visible: form.row
        anchors.fill: parent
        anchors.margins: form.pad
        spacing: form.pad

        Frame {
            Layout.fillHeight: true
            Layout.preferredWidth: height * form.videoAspect
            card: form.card
            radius: form.frameRadius
            logoHeight: width * form.frameLogoShare
            edgeBar: true
        }
        VideoText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            card: form.card
        }
    }

    ColumnLayout {
        visible: form.session
        anchors.fill: parent
        anchors.margins: form.pad
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: form.pad

            Frame {
                id: sessionFrame
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: (form.width - 2 * form.pad) * form.frameShare
                Layout.preferredHeight: width / form.videoAspect
                card: form.card
                radius: form.frameRadius
                logoHeight: width * form.frameLogoShare
                remainingBadge: false
            }
            VideoText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                card: form.card
                titleLines: 3
            }
        }
        Progress {
            Layout.fillWidth: true
            visible: form.tracked
            card: form.card
            times: true
        }
    }
}
