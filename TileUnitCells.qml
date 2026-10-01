import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** The span to or from a moment as days, hours, minutes and seconds cells, by app/shared ui/card/UnitCells.kt. */
Item {
    id: form
    required property var card

    readonly property int cols: form.card.widget?.place?.cols ?? 1
    readonly property int rows: form.card.widget?.place?.rows ?? 1
    readonly property bool wide: form.cols >= 4
    readonly property bool halved: form.cols === 2 && form.rows > 1
    readonly property var cells: CardLayouts.unitValues(form.card.now - form.card.valueTimeMs).slice(0, CardLayouts.unitCellCapacity(form.cols, form.rows)).map(c => Object.assign({
            "size": form.numberSize
        }, c))
    readonly property var lines: form.halved ? [form.cells.slice(0, 2), form.cells.slice(2)].filter(l => l.length > 0) : [form.cells]
    readonly property real numberSize: form.cols === 1 ? 28 : form.wide && form.rows > 1 ? 40 : 24
    readonly property real gap: 6
    readonly property real cellAlpha: 0.08
    readonly property real captionWidth: 88
    readonly property string label: form.card.labelText
    readonly property string dayText: {
        const mark = CardLayouts.dayMark(form.card.valueTimeMs, form.card.now);
        if (!mark)
            return "";
        return mark.weekday !== undefined ? Qt.locale().dayName(mark.weekday, Locale.ShortFormat) : mark.date;
    }
    readonly property string timeText: Qt.formatTime(new Date(form.card.valueTimeMs), "HH:mm")
    readonly property string clockText: form.dayText ? `${form.dayText} ${form.timeText}` : form.timeText

    function unitName(unit: string): string {
        return ({
                "days": Translation.tr("days"),
                "hours": Translation.tr("hours"),
                "minutes": Translation.tr("min"),
                "seconds": Translation.tr("sec")
            })[unit];
    }

    component Caption: ShrinkThenWrapText {
        minSize: 12
        color: form.card.mutedContentColor
    }

    component Grid: ColumnLayout {
        spacing: form.gap

        Repeater {
            model: form.lines

            RowLayout {
                id: line
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 0
                spacing: form.gap

                Repeater {
                    model: line.modelData

                    Rectangle {
                        id: cell
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                        Layout.preferredHeight: 0
                        radius: 10
                        color: ColorUtils.applyAlpha(form.card.contentColor, form.cellAlpha)

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 4
                            width: parent.width - 8
                            spacing: 0

                            ShrinkThenWrapText {
                                objectName: "unitCell"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                minSize: 12
                                largestSize: cell.modelData.size
                                fitHeight: cell.height - unitName.implicitHeight
                                maxLines: 1
                                value: true
                                text: String(cell.modelData.value)
                                color: form.card.contentColor
                            }
                            Caption {
                                id: unitName
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                largestSize: 11
                                maxLines: 1
                                text: form.unitName(cell.modelData.unit)
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: form.cols === 1

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            spacing: 2

            TileLabel {
                Layout.fillWidth: true
                card: form.card
                centered: true
                largestSize: Math.max(Appearance.font.pixelSize.smallest, Math.round(form.height * 0.15))
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 3

                ShrinkThenWrapText {
                    objectName: "unitCell"
                    Layout.alignment: Qt.AlignBottom
                    Layout.maximumWidth: form.width
                    largestSize: form.numberSize
                    maxLines: 1
                    value: true
                    text: form.cells.length > 0 ? String(form.cells[0].value) : "-"
                    color: form.card.contentColor
                }
                Caption {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 4
                    largestSize: 11
                    maxLines: 1
                    text: form.cells.length > 0 ? form.unitName(form.cells[0].unit) : ""
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: form.wide && form.rows === 1
        spacing: form.gap

        ColumnLayout {
            Layout.preferredWidth: form.captionWidth
            Layout.maximumWidth: form.captionWidth
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Caption {
                objectName: "unitLabel"
                Layout.fillWidth: true
                visible: form.label.length > 0
                largestSize: 14
                maxLines: 2
                text: form.label
            }
            Caption {
                objectName: "unitMoment"
                Layout.fillWidth: true
                largestSize: 12
                maxLines: 1
                text: form.dayText || form.timeText
            }
        }
        Grid {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: form.wide && form.rows > 1
        spacing: form.gap

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: form.gap

            Caption {
                objectName: "unitLabel"
                Layout.fillWidth: true
                largestSize: 14
                maxLines: 1
                text: form.label
            }
            Caption {
                objectName: "unitMoment"
                horizontalAlignment: Text.AlignRight
                largestSize: 14
                maxLines: 1
                text: form.clockText
            }
        }
        Grid {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: form.halved
        spacing: form.gap

        Caption {
            objectName: "unitLabel"
            Layout.fillWidth: true
            Layout.leftMargin: 4
            visible: form.label.length > 0
            largestSize: 14
            maxLines: 1
            text: form.label
        }
        Grid {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Grid {
        anchors.fill: parent
        visible: form.cols > 1 && !form.wide && !form.halved
    }
}
