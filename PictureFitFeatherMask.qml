import QtQuick

/** Rounded mask that fades a fitted image out along the axis with margins, so it has no hard seam against the blurred backdrop. */
Rectangle {
    id: root
    required property real paintedWidth
    required property real paintedHeight
    property real featherFraction: 0.13

    readonly property bool hasMarginX: root.paintedWidth > 1 && root.width - root.paintedWidth > 1
    readonly property bool hasMarginY: root.paintedHeight > 1 && root.height - root.paintedHeight > 1
    readonly property bool hasMargin: root.hasMarginX || root.hasMarginY
    readonly property bool vertical: root.hasMarginY && !root.hasMarginX
    readonly property real extent: Math.max(1, root.vertical ? root.height : root.width)
    readonly property real painted: root.hasMargin ? (root.vertical ? root.paintedHeight : root.paintedWidth) : root.extent
    readonly property real start: (root.extent - root.painted) / 2
    readonly property real feather: root.painted * root.featherFraction
    readonly property color edge: root.hasMargin ? "transparent" : "white"

    gradient: Gradient {
        orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal

        GradientStop {
            position: 0
            color: root.edge
        }
        GradientStop {
            position: root.start / root.extent
            color: root.edge
        }
        GradientStop {
            position: (root.start + root.feather) / root.extent
            color: "white"
        }
        GradientStop {
            position: (root.start + root.painted - root.feather) / root.extent
            color: "white"
        }
        GradientStop {
            position: (root.start + root.painted) / root.extent
            color: root.edge
        }
        GradientStop {
            position: 1
            color: root.edge
        }
    }
}
