import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** Art, title and a progress bar ticking from position_at; tap the art to play it on your Spotify. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property bool video: form.media?.kind === "video"
    readonly property real positionMs: CardLayouts.mediaPositionMs(form.media, form.card.now)
    readonly property real progress: CardLayouts.mediaProgress(form.media, form.card.now)
    readonly property bool showsTimes: !form.video && form.progress >= 0 && form.height >= 70
    readonly property real artHeight: Math.min(form.height, 64)
    readonly property bool videoFrame: form.video && form.artHeight * 16 / 9 <= form.width * 0.3
    readonly property real artWidth: form.videoFrame ? form.artHeight * 16 / 9 : Math.min(form.artHeight, form.width * 0.3)

    RowLayout {
        anchors.fill: parent
        spacing: 12

        PresenceArt {
            id: art
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: form.artWidth
            Layout.preferredHeight: form.artHeight
            source: form.media?.art_url ?? ""
            fallbackIcon: form.video ? (form.media?.playing ? "play_arrow" : "pause") : "music_note"
            playing: form.card.animating
            color: form.card.artPlaceholder
            fallbackColor: form.card.artAccent

            Rectangle {
                objectName: "playerLength"
                visible: form.videoFrame && (form.media?.length_ms ?? 0) > 0
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                width: lengthText.implicitWidth + 8
                height: lengthText.implicitHeight + 2
                radius: 4
                color: Qt.rgba(0, 0, 0, 0.7)

                StyledText {
                    id: lengthText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Medium
                    color: "white"
                    text: Fresence.stopwatchText(form.media?.length_ms ?? 0)
                }
            }

            MouseArea {
                id: artHover
                anchors.fill: parent
                enabled: Fresence.canSync(form.card.device)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Fresence.syncSpotify(form.card.device)

                Rectangle {
                    visible: artHover.containsMouse
                    anchors.fill: parent
                    radius: art.radius
                    color: Appearance.colors.colScrim

                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.huge
                        color: "white"
                        text: "sync"
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: artHover.containsMouse
                    text: Translation.tr("Play on your Spotify")
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            MediaTitle {
                Layout.fillWidth: true
                card: form.card
                lines: 1
            }
            WaveBar {
                objectName: "playerProgress"
                Layout.fillWidth: true
                visible: form.progress >= 0
                color: form.card.contentColor
                to: 1
                value: Math.max(0, form.progress)
                wavy: false
            }
            StyledText {
                objectName: "playerTimes"
                visible: form.showsTimes
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: form.card.mutedContentColor
                text: `${Fresence.stopwatchText(form.positionMs)} / ${Fresence.stopwatchText(form.media?.length_ms ?? 0)}`
            }
        }
    }
}
