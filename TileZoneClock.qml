import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** A member's clock by app/shared ui/card/Clock.kt: the place picks the layout, the day bar shows their next 24 hours in the viewer's time. */
Item {
    id: form
    required property var card

    readonly property var place: form.card.widget?.place ?? ({
            "cols": 1,
            "rows": 1
        })
    readonly property string layout: CardLayouts.clockLayout(form.card.form, form.place.cols, form.place.rows)
    readonly property real pad: form.card.tileInset
    readonly property real segmentsPad: Math.max(6, form.pad - 10)

    readonly property real offsetS: form.card.state?.utc_offset_s ?? 0
    readonly property real viewerOffsetS: -new Date(Fresence.now).getTimezoneOffset() * 60
    readonly property int minute: CardLayouts.minuteOfDayAt(form.offsetS, Fresence.now)
    readonly property int viewerMinute: CardLayouts.minuteOfDayAt(form.viewerOffsetS, Fresence.now)
    readonly property bool night: CardLayouts.isNight(form.minute)
    readonly property string glyph: form.night ? "bedtime" : "light_mode"
    readonly property string timeText: CardLayouts.hhmm(form.minute)
    readonly property string viewerTimeText: CardLayouts.hhmm(form.viewerMinute)
    readonly property string stackedText: form.timeText.replace(":", "\n")
    readonly property var dayParts: CardLayouts.dayPartsAhead(form.minute)

    readonly property string dot: " · "
    readonly property string city: (form.card.state?.weather?.place ?? "").trim()
    readonly property bool hasCity: form.city.length > 0
    readonly property int gapMinutes: CardLayouts.offsetGapMinutes(form.offsetS, form.viewerOffsetS)
    readonly property bool sameTime: form.gapMinutes === 0
    readonly property string gap: form.sameTime ? Translation.tr("same time") : Translation.tr("%1 h").arg(CardLayouts.signedHours(form.gapMinutes))
    readonly property string dayName: Qt.locale().dayName(CardLayouts.weekdayAt(form.offsetS, Fresence.now), Locale.ShortFormat)
    readonly property int dayShift: CardLayouts.dayShift(Fresence.now, form.offsetS, form.viewerOffsetS)
    readonly property string weekday: form.dayShift > 0 ? Translation.tr("already %1").arg(form.dayName) : form.dayShift < 0 ? Translation.tr("still %1").arg(form.dayName) : form.dayName
    readonly property var weekdays: form.distinct([form.weekday, form.dayName])
    readonly property string title: form.hasCity ? form.city : form.gap
    readonly property string titleWithGap: form.hasCity ? form.city + form.dot + form.gap : form.gap
    readonly property var details: form.hasCity ? [form.unbreakable(form.gap + form.dot + form.weekday), form.gap + "\n" + form.weekday] : form.weekdays
    readonly property var compactDetails: form.hasCity ? form.distinct([form.unbreakable(form.gap + form.dot + form.weekday), form.unbreakable(form.gap + form.dot + form.dayName)].concat(form.sameTime ? [form.dayName] : [])) : form.weekdays
    readonly property string nextChangeHint: {
        const change = CardLayouts.nextPhaseChange(form.minute);
        const span = CardLayouts.shortSpanMinutes(change.afterMin);
        const amount = span.unit === "minutes" ? Translation.tr("%1 min").arg(span.n) : Translation.tr("%1 h").arg(span.n);
        return change.morning ? Translation.tr("Morning in %1").arg(amount) : Translation.tr("Night in %1").arg(amount);
    }

    function distinct(list: var): var {
        return Array.from(new Set(list));
    }

    function unbreakable(text: string): string {
        return text.replace(/ /g, "\u00a0");
    }

    function partText(part: var, index: int): string {
        const from = CardLayouts.hhmm(form.viewerMinute + part.from);
        const to = CardLayouts.hhmm(form.viewerMinute + part.to);
        if (index === 0)
            return Translation.tr("until %1").arg(to);
        if (index === form.dayParts.length - 1)
            return Translation.tr("since %1").arg(from);
        return `${from}-${to}`;
    }

    component Fit: ShrinkThenWrapText {
        id: fit
        property var choices: []
        readonly property string choicesKey: JSON.stringify(fit.choices)
        property int pick: 0
        property bool fillHeight: false

        minSize: 12
        maxLines: 1
        fitHeight: fit.fillHeight ? fit.height : -1
        text: fit.choices.length > 0 ? fit.choices[Math.min(fit.pick, fit.choices.length - 1)] : ""
        onChoicesKeyChanged: fit.pick = 0
        onFitted: {
            if (!fit.fits && fit.pick < fit.choices.length - 1)
                fit.pick += 1;
        }
    }

    component Title: Fit {
        largestSize: 14
        font.weight: Font.Medium
        color: form.card.contentColor
    }

    component Detail: Fit {
        largestSize: 14
        color: form.card.mutedContentColor
    }

    component Quiet: Fit {
        largestSize: 12
        color: form.card.mutedContentColor
    }

    component Digits: Fit {
        value: true
        lineHeight: 1
        lineHeightMode: Text.ProportionalHeight
        color: form.card.contentColor
    }

    component FillDigits: Digits {
        Layout.fillWidth: true
        Layout.fillHeight: true
        fillHeight: true
        verticalAlignment: Text.AlignVCenter
    }

    component Glyph: MaterialSymbol {
        text: form.glyph
        iconSize: 14
        color: form.card.mutedContentColor
    }

    component Segment: Rectangle {
        id: seg
        property real inkAlpha: 0.1
        property bool centerContent: false
        readonly property real contentWidth: seg.width - 2 * seg.padX
        readonly property real padX: 10
        readonly property real padY: 4
        default property alias body: column.data

        color: ColorUtils.applyAlpha(form.card.contentColor, seg.inkAlpha)
        implicitHeight: column.implicitHeight + 2 * seg.padY

        ColumnLayout {
            id: column
            x: seg.padX
            y: seg.centerContent ? (seg.height - column.implicitHeight) / 2 : seg.padY
            width: seg.contentWidth
            height: seg.centerContent ? column.implicitHeight : seg.height - 2 * seg.padY
            spacing: 0
        }
    }

    component ThereBody: ColumnLayout {
        property real digitsSize: 32
        property bool compact: false
        spacing: 0

        Title {
            Layout.fillWidth: true
            choices: [form.title]
        }
        FillDigits {
            largestSize: parent.digitsSize
            choices: [form.timeText]
        }
        Quiet {
            Layout.fillWidth: true
            maxLines: parent.compact ? 1 : 2
            choices: parent.compact ? form.compactDetails : form.details
        }
    }

    component YouTime: ColumnLayout {
        spacing: 0

        Digits {
            Layout.fillWidth: true
            largestSize: 22
            choices: [form.viewerTimeText]
        }
        Quiet {
            Layout.fillWidth: true
            choices: [Translation.tr("you")]
        }
    }

    component DayBar: Row {
        id: bar
        property real barHeight: 26
        property bool labeled: true
        property bool glyphs: true
        readonly property real partsWidth: bar.width - bar.spacing * (form.dayParts.length - 1)

        spacing: 2
        height: bar.barHeight
        Layout.preferredHeight: bar.barHeight

        Repeater {
            model: form.dayParts

            Rectangle {
                id: part
                required property var modelData
                required property int index
                readonly property bool strong: CardLayouts.dayPartStrong(part.modelData, form.card.contentColor)
                readonly property color tint: part.strong ? form.card.tint : form.card.contentColor
                readonly property string text: bar.labeled ? form.partText(part.modelData, part.index) : ""
                readonly property real room: part.width - 8
                readonly property bool textFits: part.text.length > 0 && part.room >= label.implicitWidth
                readonly property bool glyphFits: bar.glyphs && part.room >= (part.textFits ? label.implicitWidth + 18 : 14)

                width: bar.partsWidth * (part.modelData.to - part.modelData.from) / CardLayouts.minutesPerDay
                height: bar.barHeight
                radius: Math.min(8, Math.min(part.width, part.height) / 2)
                color: ColorUtils.applyAlpha(form.card.contentColor, part.strong ? 0.7 : 0.16)

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        visible: part.glyphFits
                        anchors.verticalCenter: parent.verticalCenter
                        text: part.modelData.night ? "bedtime" : "light_mode"
                        iconSize: 14
                        color: part.tint
                    }
                    StyledText {
                        id: label
                        visible: part.textFits
                        anchors.verticalCenter: parent.verticalCenter
                        text: part.text
                        font.pixelSize: 12
                        font.features: ({
                                "tnum": 1
                            })
                        color: part.tint
                    }
                }
            }
        }
    }

    component DayBarWithLabels: ColumnLayout {
        spacing: 4

        DayBar {
            Layout.fillWidth: true
        }
        Item {
            id: labels
            Layout.fillWidth: true
            implicitHeight: yourTime.implicitHeight
            readonly property bool narrow: labels.width < 200

            StyledText {
                visible: !labels.narrow
                text: Translation.tr("now")
                font.pixelSize: 12
                color: form.card.mutedContentColor
            }
            StyledText {
                id: yourTime
                x: labels.narrow ? 0 : labels.width - yourTime.width
                text: Translation.tr("your time")
                font.pixelSize: 12
                color: form.card.mutedContentColor
            }
        }
    }

    Component {
        id: stackedLayout

        Item {
            Digits {
                anchors.fill: parent
                anchors.margins: form.pad
                fillHeight: true
                largestSize: 30
                maxLines: 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: form.night ? form.card.mutedContentColor : form.card.contentColor
                choices: [form.stackedText]
            }
        }
    }

    Component {
        id: cornerLayout

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: form.pad
                spacing: 0

                FillDigits {
                    largestSize: 40
                    maxLines: 2
                    verticalAlignment: Text.AlignTop
                    choices: [form.stackedText]
                }
                Title {
                    Layout.fillWidth: true
                    choices: [form.title]
                }
                Quiet {
                    Layout.fillWidth: true
                    maxLines: 2
                    choices: form.details
                }
            }
            Glyph {
                visible: form.card.shape === "rounded"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: form.pad
            }
        }
    }

    Component {
        id: shortRowLayout

        Item {
            id: shortRow
            property bool glyphShown: true
            readonly property string gapKey: form.gap
            onGapKeyChanged: shortRow.glyphShown = true

            Item {
                id: shortArea
                anchors.fill: parent
                anchors.leftMargin: form.pad
                anchors.rightMargin: form.pad

                ColumnLayout {
                    id: side
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(shortArea.width * 0.4, Math.max(sideHead.implicitWidth + (shortRow.glyphShown ? 17 : 0), sideWeekday.implicitWidth))
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Glyph {
                            visible: shortRow.glyphShown
                        }
                        Quiet {
                            id: sideHead
                            Layout.fillWidth: true
                            choices: [form.sameTime ? form.weekday : form.gap]
                        }
                    }
                    Connections {
                        target: sideHead

                        function onFitted() {
                            if (!sideHead.fits)
                                shortRow.glyphShown = false;
                        }
                    }
                    Quiet {
                        id: sideWeekday
                        visible: !form.sameTime
                        Layout.fillWidth: true
                        choices: form.weekdays
                    }
                }
                Digits {
                    anchors.left: parent.left
                    anchors.right: side.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    largestSize: 30
                    choices: [form.timeText]
                }
            }
        }
    }

    Component {
        id: longRowLayout

        Item {
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: form.pad
                anchors.rightMargin: form.pad
                spacing: 12

                Digits {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: implicitWidth
                    largestSize: 40
                    choices: [form.timeText]
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Title {
                        Layout.fillWidth: true
                        choices: [form.titleWithGap]
                    }
                    Detail {
                        Layout.fillWidth: true
                        choices: [form.nextChangeHint]
                    }
                }
            }
        }
    }

    Component {
        id: bigLayout

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: form.pad
                spacing: 0

                Title {
                    Layout.fillWidth: true
                    choices: [form.title]
                }
                FillDigits {
                    largestSize: 72
                    choices: [form.timeText]
                }
                Quiet {
                    Layout.fillWidth: true
                    choices: form.compactDetails
                }
            }
            Glyph {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: form.pad
            }
        }
    }

    Component {
        id: dayRowShortLayout

        Item {
            id: dayShort
            readonly property bool roomy: form.height >= 70

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: form.pad
                anchors.rightMargin: form.pad
                anchors.verticalCenter: parent.verticalCenter
                spacing: dayShort.roomy ? 6 : 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Digits {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        largestSize: dayShort.roomy ? 26 : 20
                        choices: [form.timeText]
                    }
                    Quiet {
                        Layout.alignment: Qt.AlignBottom
                        Layout.preferredWidth: implicitWidth
                        choices: [form.sameTime ? form.weekday : form.gap]
                    }
                }
                DayBar {
                    Layout.fillWidth: true
                    barHeight: dayShort.roomy ? 20 : 10
                    labeled: false
                    glyphs: dayShort.roomy
                }
            }
        }
    }

    Component {
        id: dayRowLongLayout

        Item {
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: form.pad
                anchors.rightMargin: form.pad
                spacing: 12

                Digits {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: implicitWidth
                    largestSize: 34
                    choices: [form.timeText]
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Title {
                        Layout.fillWidth: true
                        choices: [form.titleWithGap]
                    }
                    DayBar {
                        Layout.fillWidth: true
                        barHeight: 24
                    }
                }
            }
        }
    }

    Component {
        id: dayCornerLayout

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: form.pad
                spacing: 0

                Digits {
                    Layout.fillWidth: true
                    largestSize: 36
                    choices: [form.timeText]
                }
                Title {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    choices: [form.title]
                }
                Quiet {
                    Layout.fillWidth: true
                    choices: form.compactDetails
                }
                Item {
                    id: dayFoot
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property bool captioned: dayFoot.height >= 26 + 4 + caption.implicitHeight

                    ColumnLayout {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        spacing: 4

                        DayBar {
                            Layout.fillWidth: true
                        }
                        Quiet {
                            id: caption
                            visible: dayFoot.captioned
                            Layout.fillWidth: true
                            choices: [Translation.tr("your time")]
                        }
                    }
                }
            }
        }
    }

    Component {
        id: sideBySideLayout

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: form.segmentsPad
                spacing: 2

                Item {
                    id: pair
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Segment {
                        id: there
                        readonly property bool wide: there.contentWidth - 20 >= 160
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: (pair.width - 2) * 2 / 3
                        inkAlpha: 0.10
                        topLeftRadius: 12
                        topRightRadius: 4
                        bottomRightRadius: 4
                        bottomLeftRadius: 12

                        RowLayout {
                            visible: there.wide
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            Digits {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: implicitWidth
                                largestSize: 32
                                choices: [form.timeText]
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Title {
                                    Layout.fillWidth: true
                                    choices: [form.title]
                                }
                                Quiet {
                                    Layout.fillWidth: true
                                    maxLines: 2
                                    choices: form.details
                                }
                            }
                        }
                        ThereBody {
                            visible: !there.wide
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            digitsSize: 32
                            compact: true
                        }
                    }
                    Segment {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: pair.width - there.width - 2
                        inkAlpha: 0.05
                        centerContent: true
                        topLeftRadius: 4
                        topRightRadius: 12
                        bottomRightRadius: 12
                        bottomLeftRadius: 4

                        YouTime {
                            Layout.fillWidth: true
                        }
                    }
                }
                DayBarWithLabels {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }
            }
        }
    }

    Component {
        id: tallLayout

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: form.segmentsPad
                spacing: 2

                Segment {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    inkAlpha: 0.10
                    topLeftRadius: 12
                    topRightRadius: 12
                    bottomRightRadius: 4
                    bottomLeftRadius: 4

                    ThereBody {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        digitsSize: form.place.cols >= 3 ? 64 : 46
                    }
                }
                Segment {
                    Layout.fillWidth: true
                    inkAlpha: 0.05
                    topLeftRadius: 4
                    topRightRadius: 4
                    bottomRightRadius: 12
                    bottomLeftRadius: 12

                    YouTime {
                        Layout.fillWidth: true
                    }
                }
                DayBarWithLabels {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({
                "stacked": stackedLayout,
                "corner": cornerLayout,
                "rowShort": shortRowLayout,
                "rowLong": longRowLayout,
                "big": bigLayout,
                "dayRowShort": dayRowShortLayout,
                "dayRowLong": dayRowLongLayout,
                "dayCorner": dayCornerLayout,
                "sideBySide": sideBySideLayout,
                "tall": tallLayout
            })[form.layout]
    }
}
