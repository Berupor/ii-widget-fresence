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
    readonly property bool rowBanner: form.height < form.roomyHeight
    readonly property real roomyHeight: 120
    readonly property real titleSmallSize: 14
    readonly property real titleMediumSize: 16
    readonly property real headlineSize: 24
    readonly property real labelMediumSize: 12
    readonly property real labelSmallSize: 11
    readonly property real hourMs: 3600000
    readonly property real minuteMs: 60000
    readonly property real zoneOffsetMs: (form.card.state?.utc_offset_s ?? -new Date().getTimezoneOffset() * 60) * 1000
    readonly property var sessions: form.game?.today ?? []
    readonly property bool eveningHero: form.card.widget?.place?.rows >= 2 && form.sessions.length > 0
    readonly property var labelSteps: [1, 2, 3, 4, 6, 12]
    readonly property int maxLabelGaps: 3
    readonly property real eveningMinWindowMs: 6 * form.hourMs
    readonly property real earlierSessionAlpha: 0.45
    readonly property real trackAlpha: 0.22
    readonly property var evening: form.eveningHero ? form.eveningOf() : null

    function twoDigits(value: real): string {
        return String(Math.floor(value)).padStart(2, "0");
    }

    function hourMinute(ms: real): string {
        return `${Math.floor(ms / form.hourMs)}:${form.twoDigits(ms / form.minuteMs % 60)}`;
    }

    function timeOfDay(atMs: real): string {
        const local = new Date(atMs + form.zoneOffsetMs);
        return `${form.twoDigits(local.getUTCHours())}:${form.twoDigits(local.getUTCMinutes())}`;
    }

    function floorToHour(ms: real): real {
        const local = ms + form.zoneOffsetMs;
        return local - (local % form.hourMs + form.hourMs) % form.hourMs - form.zoneOffsetMs;
    }

    function shortDuration(ms: real): string {
        const minutes = Math.floor(ms / form.minuteMs);
        return minutes < 60 ? Translation.tr("%1m").arg(minutes) : Translation.tr("%1 h %2 min").arg(Math.floor(minutes / 60)).arg(form.twoDigits(minutes % 60));
    }

    function eveningOf(): var {
        const spans = form.sessions.map(session => ({
                    "from": Date.parse(session.started_at),
                    "to": session.ended_at ? Date.parse(session.ended_at) : form.card.now,
                    "current": !session.ended_at
                }));
        const from = form.floorToHour(Math.min(...spans.map(span => span.from)));
        const wanted = Math.max(form.floorToHour(form.card.now) + form.hourMs, from + form.eveningMinWindowMs);
        const hours = Math.ceil((wanted - from) / form.hourMs);
        const step = form.labelSteps.find(candidate => Math.ceil(hours / candidate) <= form.maxLabelGaps) ?? form.labelSteps[form.labelSteps.length - 1];
        const to = from + Math.ceil(hours / step) * step * form.hourMs;
        const window = to - from;
        const share = ms => Math.max(0, Math.min(1, (ms - from) / window));
        const labels = [];
        for (let at = from; at <= to; at += step * form.hourMs)
            labels.push(form.twoDigits(new Date(at + form.zoneOffsetMs).getUTCHours()));
        return {
            "labels": labels,
            "total": spans.reduce((sum, span) => sum + Math.max(0, span.to - span.from), 0),
            "segments": spans.map(span => ({
                        "from": share(span.from),
                        "to": share(span.to),
                        "current": span.current
                    }))
        };
    }

    readonly property var wideUrls: [form.art.hero, form.art.header, form.art.cover].filter(url => !!url)
    readonly property var tallUrls: [form.art.cover, form.art.header, form.art.hero].filter(url => !!url)

    readonly property real scrimStart: 0.3
    readonly property real scrimAlpha: 0.92
    readonly property real pillScrimAlpha: 0.45
    readonly property real chipScrimAlpha: 0.65
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
        property real nameSize: form.titleSmallSize
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
        id: pill
        property string text: form.sessionText
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
                font.pixelSize: form.labelMediumSize
                font.weight: Font.Medium
                color: art.tinted ? art.content : "white"
                text: pill.text
            }
        }
    }

    component SessionLine: StyledText {
        id: line
        readonly property string full: Translation.tr("%1 in game").arg(form.sessionText)
        objectName: "gameSession"
        maximumLineCount: 1
        elide: Text.ElideRight
        font.pixelSize: form.labelSmallSize
        text: fullMetrics.advanceWidth <= line.width ? line.full : form.sessionText

        TextMetrics {
            id: fullMetrics
            font: line.font
            text: line.full
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({
                "hero": form.eveningHero ? eveningHero : hero,
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
                        font.pixelSize: form.titleMediumSize
                        font.weight: Font.Medium
                        color: "white"
                        text: form.sessionText
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: form.labelSmallSize
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
                nameSize: form.headlineSize
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
            readonly property bool tall: form.height >= form.roomyHeight
            readonly property real chipMargin: form.card.shape === "rounded" ? 8 : form.inset

            GameArt {
                urls: form.tallUrls
            }
            Scrim {
                visible: !parent.tall
            }
            ColumnLayout {
                visible: !parent.tall
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
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: form.titleSmallSize
                    font.weight: Font.Medium
                    color: "white"
                    text: form.game?.name ?? ""
                }
                SessionLine {
                    Layout.fillWidth: true
                    color: ColorUtils.transparentize("white", 0.35)
                }
            }
            Rectangle {
                objectName: "gameChip"
                visible: parent.tall
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: parent.chipMargin
                }
                width: chipColumn.implicitWidth + 20
                height: chipColumn.implicitHeight + 10
                radius: 12
                color: Qt.rgba(0, 0, 0, form.chipScrimAlpha)

                ColumnLayout {
                    id: chipColumn
                    anchors.centerIn: parent
                    spacing: 0
                    StyledText {
                        objectName: "gameSession"
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: form.titleMediumSize
                        font.weight: Font.Medium
                        color: "white"
                        text: form.hourMinute(form.elapsedMs)
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: form.labelSmallSize
                        color: ColorUtils.transparentize("white", 0.35)
                        text: Translation.tr("since %1").arg(form.timeOfDay(form.startedMs))
                    }
                }
            }
        }
    }

    Component {
        id: eveningHero
        Item {
            id: eveningForm
            readonly property bool hasArt: form.wideUrls.length > 0
            readonly property color ink: form.content
            readonly property real timelineHeight: 10
            readonly property real logoTop: 10
            readonly property real logoWidth: 110
            readonly property real logoHeight: 34
            readonly property real pillMargin: 8
            readonly property real panelVertical: 8

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GameArt {
                        visible: eveningForm.hasArt
                        urls: form.wideUrls
                    }
                    Rectangle {
                        visible: eveningForm.hasArt
                        anchors.fill: parent
                        color: ColorUtils.transparentize(art.shade, 0.7)
                    }
                    GameLogo {
                        x: form.inset
                        y: eveningForm.logoTop
                        width: eveningForm.logoWidth
                        height: eveningForm.logoHeight
                        alignment: Qt.AlignVCenter | Qt.AlignLeft
                        nameColor: eveningForm.hasArt ? "white" : form.content
                    }
                    SessionPill {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: eveningForm.pillMargin
                        }
                        text: form.hourMinute(form.elapsedMs)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: form.inset
                    Layout.rightMargin: form.inset
                    Layout.topMargin: eveningForm.panelVertical
                    Layout.bottomMargin: eveningForm.panelVertical
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: form.labelMediumSize
                            font.weight: Font.Medium
                            color: form.mutedContent
                            text: Translation.tr("Played today")
                        }
                        StyledText {
                            font.pixelSize: form.labelMediumSize
                            font.weight: Font.Medium
                            color: form.content
                            text: form.shortDuration(form.evening?.total ?? 0)
                        }
                    }
                    Item {
                        id: timeline
                        Layout.fillWidth: true
                        Layout.preferredHeight: eveningForm.timelineHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Qt.alpha(form.content, form.trackAlpha)
                        }
                        Repeater {
                            model: form.evening?.segments ?? []

                            Rectangle {
                                required property var modelData
                                x: modelData.from * timeline.width
                                width: Math.max((modelData.to - modelData.from) * timeline.width, timeline.height)
                                height: timeline.height
                                radius: height / 2
                                color: modelData.current ? art.accent : Qt.alpha(form.content, form.earlierSessionAlpha)
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: form.evening?.labels ?? []

                            Item {
                                required property int index
                                required property string modelData
                                Layout.fillWidth: index < (form.evening?.labels.length ?? 0) - 1
                                implicitWidth: hourText.implicitWidth
                                implicitHeight: hourText.implicitHeight

                                StyledText {
                                    id: hourText
                                    font.pixelSize: form.labelSmallSize
                                    color: form.mutedContent
                                    text: parent.modelData
                                }
                            }
                        }
                    }
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
                        font.pixelSize: form.titleSmallSize
                        font.weight: Font.Medium
                        color: form.content
                        text: form.game?.name ?? ""
                    }
                    SessionLine {
                        Layout.fillWidth: true
                        color: form.mutedContent
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
                    font.pixelSize: form.labelSmallSize
                    font.weight: Font.Medium
                    color: art.tinted ? art.content : "white"
                    text: form.sessionText
                }
            }
        }
    }
}
