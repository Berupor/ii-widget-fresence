import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

/** A record with the cover as its label: beside the title on a wide tile, over it on a tall one, alone on a small one. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property bool tracked: CardLayouts.mediaProgress(form.media, form.card.now) >= 0
    readonly property bool edge: form.card.fullBleed || form.card.edgeToEdge
    readonly property real inset: form.edge ? form.card.tileInset : 0
    readonly property real discMargin: 6
    readonly property real pad: form.card.polygonMasked ? form.inset : form.discMargin
    readonly property real side: Math.max(0, Math.min(form.width, form.height) - 2 * form.pad)
    readonly property real wideAspect: 1.4
    readonly property real tallMinHeight: 120
    readonly property real discTitleHeight: 44
    readonly property bool wideRow: form.card.width > form.card.height * form.wideAspect
    readonly property bool tallColumn: !form.wideRow && form.card.height >= form.tallMinHeight

    component Disc: Item {
        id: disc
        required property var card
        property bool tracked: false
        property bool labelGlyph: true
        readonly property var media: disc.card.media
        readonly property bool playing: disc.media?.playing === true
        readonly property bool hasArt: (disc.media?.art_url ?? "").length > 0
        readonly property real mediaProgress: CardLayouts.mediaProgress(disc.media, disc.card.now)
        readonly property real progress: Math.max(0, disc.mediaProgress)
        readonly property real ringStroke: 3
        readonly property real ringGap: 3
        readonly property real diameter: Math.max(0, disc.width - (disc.tracked ? 2 * (disc.ringStroke + disc.ringGap) : 0))
        readonly property real labelFraction: 0.5
        readonly property real holeFraction: 0.06
        readonly property real glyphFraction: 0.2
        readonly property color vinylBlack: "#141416"
        readonly property var grooveRadii: [0.92, 0.82, 0.72, 0.62]
        readonly property int turnDurationMs: 12000
        readonly property real smallestAnimatedStep: 0.05

        function showProgress(): void {
            ring.enableAnimation = Math.abs(disc.progress - ring.value) >= disc.smallestAnimatedStep;
            ring.value = disc.progress;
        }
        onProgressChanged: disc.showProgress()
        Component.onCompleted: {
            ring.enableAnimation = false;
            ring.value = disc.progress;
        }

        CircularProgress {
            id: ring
            visible: disc.tracked
            anchors.centerIn: parent
            implicitSize: Math.round(disc.width)
            lineWidth: disc.ringStroke
            colPrimary: disc.playing ? disc.card.contentColor : disc.card.mutedContentColor
            colSecondary: ColorUtils.transparentize(disc.card.contentColor, 0.75)
        }

        Item {
            id: plate
            anchors.centerIn: parent
            width: disc.diameter
            height: disc.diameter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: disc.vinylBlack
            }

            Repeater {
                model: disc.grooveRadii

                Rectangle {
                    required property real modelData
                    anchors.centerIn: parent
                    width: plate.width * modelData
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.07)
                }
            }

            Item {
                id: label
                anchors.centerIn: parent
                width: Math.round(plate.width * disc.labelFraction)
                height: label.width

                Item {
                    id: spinner
                    anchors.fill: parent

                    RotationAnimation on rotation {
                        running: true
                        paused: !disc.playing || !disc.card.animating
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: disc.turnDurationMs
                    }

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: label.width
                                height: label.height
                                radius: label.width / 2
                            }
                        }

                        PresenceArt {
                            id: labelArt
                            anchors.fill: parent
                            radius: 0
                            color: disc.card.artPlaceholder
                            source: disc.media?.art_url ?? ""
                            media: disc.media
                            fallbackIcon: ""
                            playing: disc.card.animating
                        }
                    }
                }

                MaterialSymbol {
                    visible: disc.labelGlyph && labelArt.status !== Image.Ready
                    anchors.centerIn: parent
                    iconSize: Math.round(plate.width * disc.glyphFraction)
                    color: Qt.alpha(disc.card.artAccent, labelArt.idle ? labelArt.idleGlyphAlpha : 1)
                    text: labelArt.mediaSymbol
                }
            }

            Rectangle {
                visible: disc.hasArt
                anchors.centerIn: parent
                width: plate.width * disc.holeFraction
                height: width
                radius: width / 2
                color: disc.vinylBlack
            }
        }
    }

    RowLayout {
        visible: form.wideRow
        anchors.fill: parent
        anchors.margins: form.pad
        spacing: 12

        Disc {
            Layout.preferredWidth: form.side
            Layout.preferredHeight: form.side
            Layout.alignment: Qt.AlignVCenter
            card: form.card
            tracked: form.tracked
        }
        MediaTitle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            card: form.card
        }
    }

    ColumnLayout {
        visible: form.tallColumn
        anchors.fill: parent
        anchors.margins: form.inset
        spacing: 6

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Disc {
                anchors.centerIn: parent
                width: Math.max(0, form.side - form.discTitleHeight)
                height: width
                card: form.card
                tracked: form.tracked
            }
        }
        MediaTitle {
            Layout.fillWidth: true
            card: form.card
            centered: true
        }
    }

    Disc {
        visible: !form.wideRow && !form.tallColumn
        anchors.centerIn: parent
        width: form.side
        height: form.side
        card: form.card
        tracked: form.tracked
    }
}
