pragma ComponentBehavior: Bound

import QtQuick
import "CardLayouts.js" as CardLayouts

/** One of a card's grids, row or detail, drawn from the device's state. */
Item {
    id: root
    required property var device
    required property var widgets
    property string grid: "row"

    readonly property int columns: CardLayouts.columns
    readonly property real spacing: CardLayouts.gap
    readonly property real cellSize: Math.max(0, (root.width - (root.columns - 1) * root.spacing) / root.columns)

    readonly property var freshPlaced: CardLayouts.placed(root.widgets, root.grid, root.device, Fresence.now)
    property var placed: []
    onFreshPlacedChanged: {
        if (!CardLayouts.samePlaced(root.placed, root.freshPlaced))
            root.placed = root.freshPlaced;
    }
    Component.onCompleted: root.placed = root.freshPlaced

    readonly property int rowsUsed: CardLayouts.rowsUsed(root.placed)

    // What the grid shows right now, for the status line to leave out
    readonly property var coverage: {
        const covered = new Set();
        for (const p of root.placed) {
            if (!p.dimmed)
                covered.add(p.widget.type === "value" ? `value:${p.widget.source}` : p.widget.type);
        }
        return covered;
    }

    function span(cells: int): real {
        return cells * root.cellSize + (cells - 1) * root.spacing;
    }

    implicitHeight: root.rowsUsed > 0 ? root.span(root.rowsUsed) : 0

    Repeater {
        model: root.placed

        delegate: CardTile {
            required property var modelData
            widget: modelData.widget
            device: root.device
            dimmed: modelData.dimmed
            x: modelData.col * (root.cellSize + root.spacing)
            y: modelData.row * (root.cellSize + root.spacing)
            width: root.span(modelData.cols)
            height: root.span(modelData.rows)
        }
    }
}
