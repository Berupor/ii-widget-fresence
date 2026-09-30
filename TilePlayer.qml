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
    readonly property bool tracked: CardLayouts.mediaProgress(form.media, form.card.now) >= 0
    readonly property bool edge: form.card.fullBleed || form.card.edgeToEdge
    readonly property real pad: form.edge ? form.card.tileInset : 0
    readonly property real timesMinWidth: 240
    readonly property real artShare: 0.3
    readonly property real videoAspect: 16 / 9
    readonly property real videoGlyphLift: 14
    readonly property real framedRadius: 10
    readonly property bool times: form.card.width >= form.timesMinWidth
    readonly property bool videoFrame: form.times && form.video
    readonly property bool bleed: form.edge && form.card.shape === "rounded" && !form.videoFrame
    readonly property real aspect: form.videoFrame ? form.videoAspect : 1
    readonly property real artHeight: Math.max(0, Math.min(form.height - 2 * form.pad, form.width * form.artShare / form.aspect))

    RowLayout {
        anchors.fill: parent
        spacing: 0

        PresenceArt {
            id: art
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: form.bleed ? 0 : form.pad
            Layout.preferredWidth: form.bleed ? form.height : form.artHeight * form.aspect
            Layout.preferredHeight: form.bleed ? form.height : form.artHeight
            radius: form.bleed ? 0 : form.framedRadius
            source: form.media?.art_url ?? ""
            media: form.media
            fallbackLift: form.videoFrame ? form.videoGlyphLift : 0
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
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: form.pad

            MediaTitle {
                width: parent.width
                anchors.top: form.tracked ? parent.top : undefined
                anchors.verticalCenter: form.tracked ? undefined : parent.verticalCenter
                card: form.card
                stateMark: !form.tracked
                markAlignment: Qt.AlignTop
            }
            MediaTitle.Progress {
                objectName: "playerProgress"
                visible: form.tracked
                width: parent.width
                anchors.bottom: parent.bottom
                card: form.card
                times: form.times
            }
        }
    }
}
