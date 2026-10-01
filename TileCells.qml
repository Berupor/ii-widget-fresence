import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/** Load as a grid of cells, one per part or a fill in cells, by app/shared ui/card/Gauges.kt CellsForm. */
ColumnLayout {
    id: form
    required property var card
    readonly property bool wide: (form.card.widget?.place?.cols ?? 1) > 1
    readonly property var parts: form.card.hasData && form.card.value?.parts?.length > 0 ? form.card.value.parts : null
    readonly property int count: form.parts ? form.parts.length : (form.wide ? 32 : 16)
    readonly property real gap: 3
    readonly property real valueMaxSize: 14
    readonly property real trackAlpha: 0.22
    readonly property var layoutOfCells: form.cellGrid(form.count, cells.width, cells.height)
    readonly property int cols: form.layoutOfCells.cols
    readonly property int rows: form.layoutOfCells.rows
    readonly property bool byColumn: !form.parts && form.cols >= form.rows * 2
    readonly property int lit: Math.round(form.card.hasData ? form.card.fill * form.count : 0)
    spacing: 6

    function cellGrid(count: int, width: real, height: real): var {
        let best = {
            "cols": count,
            "rows": 1
        };
        let bestScore = Infinity;
        for (let rows = 1; rows <= count; rows++) {
            if (count % rows !== 0)
                continue;
            const cols = count / rows;
            const score = Math.abs(Math.log((width / cols) / Math.max(1, height / rows)));
            if (score < bestScore) {
                bestScore = score;
                best = {
                    "cols": cols,
                    "rows": rows
                };
            }
        }
        return best;
    }

    function levelAt(index: int): real {
        if (form.parts)
            return Math.max(0, Math.min(1, form.parts[index]));
        return index < form.lit ? 1 : 0;
    }

    function colOf(index: int): int {
        return form.byColumn ? Math.floor(index / form.rows) : index % form.cols;
    }

    function rowOf(index: int): int {
        if (form.parts)
            return Math.floor(index / form.cols);
        return form.byColumn ? form.rows - 1 - index % form.rows : form.rows - 1 - Math.floor(index / form.cols);
    }

    RowLayout {
        Layout.fillWidth: true

        TileLabel {
            Layout.fillWidth: true
            shown: form.wide
            card: form.card
        }
        ShrinkThenWrapText {
            objectName: "cellsValue"
            largestSize: form.valueMaxSize
            maxLines: 1
            value: true
            text: form.wide ? form.card.shownValueText : form.card.shortValueText
            color: form.card.contentColor
        }
    }
    Item {
        id: cells
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property real cellWidth: (cells.width - form.gap * (form.cols - 1)) / form.cols
        readonly property real cellHeight: (cells.height - form.gap * (form.rows - 1)) / form.rows

        Repeater {
            model: form.count

            Rectangle {
                id: cell
                required property int index
                x: form.colOf(cell.index) * (cells.cellWidth + form.gap)
                y: form.rowOf(cell.index) * (cells.cellHeight + form.gap)
                width: cells.cellWidth
                height: cells.cellHeight
                radius: 2
                color: Qt.rgba(form.card.contentColor.r, form.card.contentColor.g, form.card.contentColor.b, form.card.contentColor.a * (form.trackAlpha + (1 - form.trackAlpha) * form.levelAt(cell.index)))
            }
        }
    }
}
