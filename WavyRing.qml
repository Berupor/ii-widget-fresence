import QtQuick
import QtQuick.Shapes
import qs.modules.common
import "CardLayouts.js" as CardLayouts

Item {
    id: root

    property int implicitSize: 30
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance.m3colors.m3onSecondaryContainer
    property color colSecondary: Appearance.colors.colSecondaryContainer
    readonly property real gapAngle: root.degree > 0.001 * 360 && root.degree < 0.999 * 360 ? 2 * root.lineWidth / root.arcRadius * 180 / Math.PI : 0
    property bool enableAnimation: true
    property int animationDuration: CardLayouts.fillAnimationMs

    property real waveAmplitude: 1.6
    property real waveLength: 40

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property real degree: value * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth / 2 - root.waveAmplitude
    property real startAngle: -90
    property real waveFrequency: (2 * Math.PI * root.arcRadius) / root.waveLength

    Behavior on degree {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: CardLayouts.fillEasing
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.colSecondary
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.centerX
                centerY: root.centerY
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle - root.gapAngle
                sweepAngle: -Math.max(0, 360 - root.degree - 2 * root.gapAngle)
            }
        }

        ShapePath {
            strokeColor: root.colPrimary
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            fillColor: "transparent"
            PathPolyline {
                path: {
                    const rad = root.startAngle * Math.PI / 180;
                    if (root.degree <= 0)
                        return [Qt.point(root.centerX + root.arcRadius * Math.cos(rad), root.centerY + root.arcRadius * Math.sin(rad))];

                    const steps = Math.max(20, Math.floor(root.degree * 1.5));
                    const pts = [];
                    for (let i = 0; i <= steps; i++) {
                        const currentDeg = root.startAngle + root.degree * i / steps;
                        const currentRad = currentDeg * Math.PI / 180;
                        const waveOffset = root.waveAmplitude * Math.sin((currentDeg - root.startAngle) * root.waveFrequency * Math.PI / 180);
                        const r = root.arcRadius + waveOffset;
                        pts.push(Qt.point(root.centerX + r * Math.cos(currentRad), root.centerY + r * Math.sin(currentRad)));
                    }
                    return pts;
                }
            }
        }
    }
}
