import qs.modules.common.widgets
import QtQuick
import "CardLayouts.js" as CardLayouts

Item {
    id: root
    property string shape: "rounded"
    property color color
    property real borderWidth: 2

    readonly property bool polygon: root.shape === "cookie" || root.shape === "clover"
    readonly property real side: Math.min(root.width, root.height)
    readonly property real strokeCenteredOnEdge: 2

    Rectangle {
        anchors.fill: parent
        visible: !root.polygon
        radius: root.shape === "circle" ? root.side / 2 : CardLayouts.roundedRadius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.color
    }

    MaterialShape {
        anchors.fill: parent
        visible: root.polygon
        color: "transparent"
        borderColor: root.color
        borderWidth: root.side > 0 ? root.borderWidth * root.strokeCenteredOnEdge / root.side : 0
        shape: root.shape === "cookie" ? MaterialShape.Shape.Cookie9Sided : MaterialShape.Shape.Clover4Leaf
    }
}
