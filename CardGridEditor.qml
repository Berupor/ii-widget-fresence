pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Shapes
import "CardLayouts.js" as CardLayouts
import "CardRules.js" as Rules

/** One grid of the card editor: pick, drag, resize, remove, add in an empty cell. */
Item {
    id: root
    required property var widgets
    required property string grid
    required property var device
    required property var previewDevice
    property int selectedIndex: -1

    signal selected(int index)
    signal edited(var widgets)
    signal removeRequested(int index)
    signal emptyCellClicked(int col, int row)

    readonly property int columns: CardLayouts.columns
    readonly property int rows: CardLayouts.gridRows[root.grid]
    readonly property real spacing: CardLayouts.gap
    readonly property real cellSize: Math.max(0, (root.width - (root.columns - 1) * root.spacing) / root.columns)
    readonly property real step: root.cellSize + root.spacing
    readonly property real handleSize: 22
    property var stretched: null

    function span(cells: int): real {
        return cells > 0 ? cells * root.cellSize + (cells - 1) * root.spacing : 0;
    }

    implicitHeight: root.span(root.rows)

    Repeater {
        model: root.columns * root.rows

        delegate: MouseArea {
            id: emptyCell
            required property int index
            readonly property int col: emptyCell.index % root.columns
            readonly property int row: Math.floor(emptyCell.index / root.columns)
            visible: Rules.isFree(root.widgets, emptyCell.col, emptyCell.row)
            x: emptyCell.col * root.step
            y: emptyCell.row * root.step
            width: root.cellSize
            height: root.cellSize
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.emptyCellClicked(emptyCell.col, emptyCell.row)

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.large
                color: emptyCell.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Appearance.colors.colOutlineVariant
                    strokeWidth: 1.5
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [5, 4]
                    fillColor: "transparent"

                    PathRectangle {
                        x: 0.75
                        y: 0.75
                        width: emptyCell.width - 1.5
                        height: emptyCell.height - 1.5
                        radius: Appearance.rounding.large
                    }
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "add"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOutlineVariant
            }
        }
    }

    Repeater {
        model: root.widgets

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property var place: root.stretched ? root.stretched[cell.index].place : cell.modelData.place
            readonly property bool isSelected: cell.index === root.selectedIndex
            readonly property bool dimmed: CardLayouts.missing(cell.modelData, root.device, Fresence.now)

            // move | resize while a pointer drags, dx and dy in cells
            property string drag: ""
            property real dx: 0
            property real dy: 0
            readonly property var target: cell.drag ? Rules.draggedPlace(cell.place, cell.drag, cell.dx, cell.dy) : null
            readonly property bool targetValid: cell.drag !== "move" || !cell.target || Rules.moveOrSwap(root.widgets, cell.index, cell.target.col, cell.target.row, root.grid) !== null

            function stretchTo(): void {
                root.stretched = Rules.stretchedToward(root.widgets, cell.index, Rules.size(cell.target.cols, cell.target.rows), root.grid);
            }

            function finish(): void {
                const next = cell.drag === "move" ? Rules.moveOrSwap(root.widgets, cell.index, cell.target.col, cell.target.row, root.grid) : root.stretched;
                cell.drag = "";
                root.stretched = null;
                if (next)
                    root.edited(next);
            }

            function cancel(): void {
                cell.drag = "";
                root.stretched = null;
            }

            z: cell.drag ? 2 : cell.isSelected ? 1 : 0

            Item {
                id: body
                x: cell.place.col * root.step + (cell.drag === "move" ? cell.dx * root.step : 0)
                y: cell.place.row * root.step + (cell.drag === "move" ? cell.dy * root.step : 0)
                width: root.span(cell.place.cols)
                height: root.span(cell.place.rows)
                scale: cell.drag === "move" ? 1.03 : 1
                opacity: cell.dimmed && !cell.drag ? 0.6 : 1

                CardTile {
                    anchors.fill: parent
                    widget: Object.assign({}, cell.modelData, {
                        "place": cell.place
                    })
                    device: root.previewDevice
                }

                Rectangle {
                    anchors.fill: parent
                    visible: cell.isSelected
                    radius: Appearance.rounding.large
                    color: "transparent"
                    border.width: 2
                    border.color: Appearance.colors.colPrimary
                }

                MouseArea {
                    id: bodyArea
                    anchors.fill: parent
                    cursorShape: cell.isSelected ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
                    preventStealing: true
                    property point pressedAt
                    onPressed: mouse => bodyArea.pressedAt = mapToItem(root, mouse.x, mouse.y)
                    onPositionChanged: mouse => {
                        if (!cell.isSelected)
                            return;
                        const at = mapToItem(root, mouse.x, mouse.y);
                        if (!cell.drag && Math.hypot(at.x - bodyArea.pressedAt.x, at.y - bodyArea.pressedAt.y) < Qt.styleHints.startDragDistance)
                            return;
                        cell.drag = "move";
                        cell.dx = (at.x - bodyArea.pressedAt.x) / root.step;
                        cell.dy = (at.y - bodyArea.pressedAt.y) / root.step;
                    }
                    onReleased: {
                        if (cell.drag)
                            cell.finish();
                        else
                            root.selected(cell.isSelected ? -1 : cell.index);
                    }
                    onCanceled: cell.cancel()
                }
            }

            Rectangle {
                visible: cell.drag === "move"
                x: (cell.target?.col ?? 0) * root.step
                y: (cell.target?.row ?? 0) * root.step
                width: root.span(cell.target?.cols ?? 0)
                height: root.span(cell.target?.rows ?? 0)
                z: 3
                radius: Appearance.rounding.large
                color: "transparent"
                border.width: 2
                border.color: cell.targetValid ? Appearance.colors.colPrimary : Appearance.colors.colError
            }

            CornerHandle {
                visible: cell.isSelected && cell.drag !== "move"
                x: (cell.place.col + cell.place.cols) * root.step - root.spacing - root.handleSize * 0.75
                y: cell.place.row * root.step - root.handleSize * 0.25
                symbol: "close"
                fill: Appearance.colors.colError
                content: Appearance.colors.colOnError
                toolTip: Translation.tr("Remove")
                onClicked: root.removeRequested(cell.index)
            }

            CornerHandle {
                id: resizeHandle
                visible: cell.isSelected
                x: (cell.place.col + cell.place.cols) * root.step - root.spacing - root.handleSize * 0.75
                y: (cell.place.row + cell.place.rows) * root.step - root.spacing - root.handleSize * 0.75
                symbol: "open_in_full"
                fill: Appearance.colors.colPrimary
                content: Appearance.colors.colOnPrimary
                cursor: Qt.SizeFDiagCursor
                onClicked: {
                    const next = Rules.nextSize(root.widgets, cell.index, root.grid);
                    if (next)
                        root.edited(next);
                }
                onDragged: (dx, dy) => {
                    cell.drag = "resize";
                    cell.dx = dx / root.step;
                    cell.dy = dy / root.step;
                    cell.stretchTo();
                }
                onDropped: cell.finish()
                onCanceled: cell.cancel()
            }
        }
    }

    component CornerHandle: Rectangle {
        id: handle
        property string symbol
        property color fill
        property color content
        property string toolTip: ""
        property int cursor: Qt.PointingHandCursor

        signal clicked
        signal dragged(real dx, real dy)
        signal dropped
        signal canceled

        z: 4
        width: root.handleSize
        height: root.handleSize
        radius: width / 2
        color: handle.fill
        border.width: 2
        border.color: Appearance.colors.colLayer1

        MaterialSymbol {
            anchors.centerIn: parent
            text: handle.symbol
            iconSize: Appearance.font.pixelSize.smaller
            color: handle.content
        }

        MouseArea {
            id: handleArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            preventStealing: true
            cursorShape: handle.cursor
            property point pressedAt
            property bool moving: false
            onPressed: mouse => {
                handleArea.pressedAt = mapToItem(root, mouse.x, mouse.y);
                handleArea.moving = false;
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const at = mapToItem(root, mouse.x, mouse.y);
                if (!handleArea.moving && Math.hypot(at.x - handleArea.pressedAt.x, at.y - handleArea.pressedAt.y) < Qt.styleHints.startDragDistance)
                    return;
                handleArea.moving = true;
                handle.dragged(at.x - handleArea.pressedAt.x, at.y - handleArea.pressedAt.y);
            }
            onReleased: handleArea.moving ? handle.dropped() : handle.clicked()
            onCanceled: handle.canceled()
        }

        StyledToolTip {
            extraVisibleCondition: false
            alternativeVisibleCondition: handleArea.containsMouse && handle.toolTip !== ""
            text: handle.toolTip
        }
    }
}
