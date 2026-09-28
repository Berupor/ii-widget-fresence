pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/**
 * Steam art of the game in four forms, after app/shared ui/card/GameTiles.kt. Colors come
 * from the cover like a music tile's, unless the widget sets its own. Steam serves a header
 * for every title, the rest only where the publisher uploaded them, so each form falls back
 * a picture at a time. The logo stands in for the name where there is one.
 */
Item {
    id: form
    required property var card
    readonly property var game: form.card.game
    readonly property var art: form.game?.art ?? {}
    readonly property string shownForm: form.card.form
    readonly property real startedMs: Date.parse(form.game?.started_at ?? "")
    readonly property real elapsedMs: isNaN(form.startedMs) ? 0 : Math.max(0, form.card.now - form.startedMs)
    readonly property string sessionText: Fresence.stopwatchText(form.elapsedMs)
    readonly property real inset: CardLayouts.tileInset(form.width, form.height, form.card.shape)
    readonly property bool rowBanner: form.height < 120

    readonly property var wideUrls: [form.art.hero, form.art.header, form.art.cover].filter(url => !!url)
    readonly property var tallUrls: [form.art.cover, form.art.header, form.art.hero].filter(url => !!url)

    readonly property real scrimStart: 0.3
    readonly property real scrimAlpha: 0.92
    readonly property real pillScrimAlpha: 0.45
    readonly property color neutralContent: Appearance.colors[form.card.colorKeys[1]]
    readonly property color content: art.tinted ? art.content : form.neutralContent
    readonly property color mutedContent: ColorUtils.transparentize(form.content, 0.35)
    readonly property color scrimEdge: ColorUtils.transparentize(art.shade, 1)
    readonly property color scrimFull: ColorUtils.transparentize(art.shade, 1 - form.scrimAlpha)

    ArtPalette {
        id: art
        url: neutral ? "" : (form.art.cover ?? form.art.header ?? form.art.hero ?? "")
        key: neutral ? "" : (form.game?.name ?? "")
        neutral: !!form.card.widget?.color
        neutralContent: form.neutralContent
    }

    Rectangle {
        anchors.fill: parent
        color: art.tinted ? art.fill : form.card.tint
        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
            }
        }
    }

    component GameArt: PresenceArt {
        required property var urls
        anchors.fill: parent
        radius: 0
        color: "transparent"
        fallbackIcon: "sports_esports"
        source: urls[0] ?? ""
        fallbacks: urls.slice(1)
        playing: form.card.animating
    }

    component Scrim: Rectangle {
        id: scrim
        property bool horizontal: false
        anchors.fill: parent
        gradient: Gradient {
            orientation: scrim.horizontal ? Gradient.Horizontal : Gradient.Vertical
            GradientStop {
                position: form.scrimStart
                color: form.scrimEdge
            }
            GradientStop {
                position: 1
                color: form.scrimFull
            }
        }
    }

    component GameLogo: Item {
        id: logo
        property int alignment: Qt.AlignVCenter | Qt.AlignLeft
        property int nameSize: Appearance.font.pixelSize.normal
        property color nameColor: "white"
        readonly property bool pictured: !!form.art.logo && picture.status !== Image.Error

        PresenceArt {
            id: picture
            visible: logo.pictured
            anchors.fill: parent
            radius: 0
            color: "transparent"
            fallbackIcon: ""
            source: form.art.logo ?? ""
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: logo.alignment & Qt.AlignHCenter ? Image.AlignHCenter : Image.AlignLeft
            verticalAlignment: logo.alignment & Qt.AlignBottom ? Image.AlignBottom : Image.AlignVCenter
        }
        StyledText {
            objectName: "gameName"
            visible: !logo.pictured
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: logo.alignment & Qt.AlignBottom ? parent.bottom : undefined
            anchors.verticalCenter: logo.alignment & Qt.AlignBottom ? undefined : parent.verticalCenter
            horizontalAlignment: logo.alignment & Qt.AlignHCenter ? Text.AlignHCenter : Text.AlignLeft
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.pixelSize: logo.nameSize
            font.weight: Font.DemiBold
            color: logo.nameColor
            text: form.game?.name ?? ""
        }
    }

    component SessionPill: Rectangle {
        implicitWidth: pillRow.implicitWidth + 15
        implicitHeight: pillRow.implicitHeight + 6
        radius: height / 2
        color: art.tinted ? art.fill : Qt.rgba(0, 0, 0, form.pillScrimAlpha)

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 4
            MaterialSymbol {
                text: "sports_esports"
                iconSize: 14
                color: art.tinted ? art.accent : "white"
            }
            StyledText {
                objectName: "gameSession"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: art.tinted ? art.content : "white"
                text: form.sessionText
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({
                "hero": hero,
                "ring": ring,
                "cover": cover
            })[form.shownForm] ?? (form.rowBanner ? bannerRow : bannerTall)
    }

    Component {
        id: bannerTall
        Item {
            GameArt {
                urls: form.wideUrls
            }
            Scrim {}
            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: form.inset
                }
                spacing: 8
                GameLogo {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    alignment: Qt.AlignBottom | Qt.AlignLeft
                }
                SessionPill {
                    Layout.alignment: Qt.AlignBottom
                }
            }
        }
    }

    Component {
        id: bannerRow
        Item {
            GameArt {
                urls: form.wideUrls
            }
            Scrim {
                horizontal: true
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: form.inset
                spacing: 8
                GameLogo {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                ColumnLayout {
                    spacing: 0
                    StyledText {
                        objectName: "gameSession"
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.Medium
                        color: "white"
                        text: form.sessionText
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: ColorUtils.transparentize("white", 0.35)
                        text: Translation.tr("in game")
                    }
                }
            }
        }
    }

    Component {
        id: hero
        Item {
            readonly property bool hasArt: form.wideUrls.length > 0
            GameArt {
                visible: parent.hasArt
                urls: form.wideUrls
            }
            Rectangle {
                visible: parent.hasArt
                anchors.fill: parent
                color: ColorUtils.transparentize(art.shade, 0.7)
            }
            GameLogo {
                anchors.centerIn: parent
                width: parent.width * 0.6
                height: parent.height * 0.55
                alignment: Qt.AlignVCenter | Qt.AlignHCenter
                nameSize: Appearance.font.pixelSize.title
                nameColor: parent.hasArt ? "white" : form.content
            }
            SessionPill {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    margins: form.inset
                }
            }
        }
    }

    Component {
        id: cover
        Item {
            GameArt {
                urls: form.tallUrls
            }
            Scrim {}
            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: form.inset
                }
                spacing: 1
                StyledText {
                    objectName: "gameName"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: "white"
                    text: form.game?.name ?? ""
                }
                StyledText {
                    objectName: "gameSession"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: ColorUtils.transparentize("white", 0.35)
                    text: Translation.tr("%1 in game").arg(form.sessionText)
                }
            }
        }
    }

    Component {
        id: ring
        Item {
            id: ringForm
            readonly property real pad: form.inset
            readonly property bool sideBySide: width > height
            readonly property real diameter: Math.min(width, height) - pad * 2
            readonly property real strokeWidth: 3
            readonly property real artGap: 4
            readonly property real hour: (form.elapsedMs % 3600000) / 3600000

            component SessionRing: Item {
                implicitWidth: ringForm.diameter
                implicitHeight: ringForm.diameter

                WavyRing {
                    anchors.fill: parent
                    implicitSize: ringForm.diameter
                    lineWidth: ringForm.strokeWidth
                    value: ringForm.hour
                    enableAnimation: false
                    colPrimary: art.accent
                    colSecondary: ColorUtils.transparentize(art.accent, 0.75)
                }
                GameArt {
                    anchors.centerIn: parent
                    anchors.fill: undefined
                    width: parent.width - (ringForm.strokeWidth + ringForm.artGap) * 2
                    height: width
                    radius: width / 2
                    urls: form.tallUrls
                }
            }

            RowLayout {
                visible: ringForm.sideBySide
                anchors.fill: parent
                anchors.margins: ringForm.pad
                spacing: 8
                SessionRing {}
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        objectName: "gameName"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: form.content
                        text: form.game?.name ?? ""
                    }
                    StyledText {
                        objectName: "gameSession"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: form.mutedContent
                        text: Translation.tr("%1 in game").arg(form.sessionText)
                    }
                }
            }

            SessionRing {
                visible: !ringForm.sideBySide
                anchors.centerIn: parent
            }
            Rectangle {
                visible: !ringForm.sideBySide
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 3
                }
                width: sessionLabel.implicitWidth + 12
                height: sessionLabel.implicitHeight
                radius: height / 2
                color: art.tinted ? art.fill : Qt.rgba(0, 0, 0, form.pillScrimAlpha)
                StyledText {
                    id: sessionLabel
                    objectName: "gameSession"
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Medium
                    color: art.tinted ? art.content : "white"
                    text: form.sessionText
                }
            }
        }
    }
}
