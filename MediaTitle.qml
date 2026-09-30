import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Title and artist, or channel for a video, of what a media tile plays, with the state mark of untracked media. */
RowLayout {
    id: title
    required property var card
    property color color: title.card.contentColor
    property color subtleColor: title.card.mutedContentColor
    property bool centered: false
    property bool stateMark: false
    property int markAlignment: Qt.AlignVCenter
    readonly property var media: title.card.media
    readonly property real titleSize: 14
    readonly property real artistSize: 12
    readonly property real marqueeSpeed: 0.03
    readonly property int marqueeDelayMs: 1500
    spacing: 8

    component StateMark: Item {
        id: mark
        property bool playing: true
        property color color: "white"
        property real equalizerHeight: 12
        property real pauseSize: 16
        readonly property var barHeights: [0.55, 1, 0.7]
        implicitWidth: mark.playing ? bars.implicitWidth : pauseIcon.implicitWidth
        implicitHeight: mark.playing ? mark.equalizerHeight : mark.pauseSize

        Row {
            id: bars
            objectName: "mediaEqualizer"
            visible: mark.playing
            anchors.centerIn: parent
            height: mark.equalizerHeight
            spacing: 2

            Repeater {
                model: mark.barHeights

                Rectangle {
                    required property real modelData
                    anchors.bottom: parent.bottom
                    width: 3
                    height: mark.equalizerHeight * modelData
                    radius: width / 2
                    color: mark.color
                }
            }
        }
        MaterialSymbol {
            id: pauseIcon
            visible: !mark.playing
            anchors.centerIn: parent
            iconSize: mark.pauseSize
            color: mark.color
            text: "pause"
        }
    }

    component Progress: RowLayout {
        id: progress
        required property var card
        property bool times: false
        readonly property var media: progress.card.media
        readonly property bool music: progress.media?.kind !== "video"
        readonly property bool playing: progress.media?.playing === true
        readonly property real fraction: CardLayouts.mediaProgress(progress.media, progress.card.now)
        readonly property real positionMs: CardLayouts.mediaPositionMs(progress.media, progress.card.now)
        readonly property real remainingMs: (progress.media?.length_ms ?? 0) - progress.positionMs
        readonly property bool showsTimes: progress.times && progress.music
        readonly property bool wavy: progress.music && progress.playing && progress.card.animating
        readonly property real timeSize: 11
        spacing: 8

        StyledText {
            objectName: "mediaPosition"
            visible: progress.showsTimes
            font.pixelSize: progress.timeSize
            color: progress.card.mutedContentColor
            text: Fresence.stopwatchText(progress.positionMs)
        }
        WaveBar {
            objectName: "mediaProgress"
            Layout.fillWidth: true
            color: progress.playing ? progress.card.contentColor : progress.card.mutedContentColor
            to: 1
            value: Math.max(0, progress.fraction)
            wavy: progress.wavy
            animateWave: progress.wavy
        }
        StyledText {
            objectName: "mediaRemaining"
            visible: progress.showsTimes && progress.remainingMs > 0
            font.pixelSize: progress.timeSize
            color: progress.card.mutedContentColor
            text: `-${Fresence.stopwatchText(progress.remainingMs)}`
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        Item {
            id: marquee
            Layout.fillWidth: true
            implicitHeight: titleText.implicitHeight
            clip: true

            readonly property real overflow: Math.max(0, titleText.implicitWidth - marquee.width)
            property real shift: 0

            HoverHandler {
                id: hover
            }

            StyledText {
                id: titleText
                objectName: "mediaTitle"
                x: marquee.overflow > 0 ? -marquee.shift : (title.centered ? (marquee.width - titleText.width) / 2 : 0)
                width: titleText.implicitWidth
                wrapMode: Text.NoWrap
                textFormat: Text.PlainText
                font.pixelSize: title.titleSize
                font.weight: Font.Medium
                text: title.media?.title ?? ""
                color: title.color
            }

            SequentialAnimation on shift {
                running: marquee.overflow > 0 && title.card.animating
                loops: hover.hovered ? Animation.Infinite : 1

                PauseAnimation {
                    duration: title.marqueeDelayMs
                }
                NumberAnimation {
                    to: marquee.overflow
                    duration: marquee.overflow / title.marqueeSpeed
                }
                PauseAnimation {
                    duration: title.marqueeDelayMs
                }
                PropertyAction {
                    value: 0
                }
            }
        }
        StyledText {
            objectName: "mediaSubtitle"
            Layout.fillWidth: true
            visible: text.length > 0
            horizontalAlignment: title.centered ? Text.AlignHCenter : Text.AlignLeft
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.pixelSize: title.artistSize
            text: title.media?.artist ?? ""
            color: title.subtleColor
        }
    }

    StateMark {
        visible: title.stateMark
        Layout.alignment: title.markAlignment
        playing: title.media?.playing === true
        color: title.color
    }
}
