pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick

/** The round face of a row. Holding your own opens the incognito picker. */
Item {
    id: root

    property var member: null
    property bool offline: true
    property bool hidden: false
    property bool interactive: false
    property real holdProgress: 0

    signal holdStarted
    signal holdMoved(real x, real y)
    signal holdEnded
    signal tapped

    readonly property int holdDuration: 800
    readonly property real ringStroke: 3
    readonly property real ringGap: 4
    readonly property bool sealed: root.member?.sealed ?? false
    readonly property bool showsInitial: !root.hidden && !root.sealed

    implicitWidth: 40
    implicitHeight: 40

    onHiddenChanged: pop.restart()

    SequentialAnimation {
        id: pop
        NumberAnimation { // Shorter than any token on purpose: a squash that reads has to beat the eye
            target: face
            property: "scale"
            to: 0.82
            duration: 90
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: face
            property: "scale"
            to: 1
            duration: Appearance.animation.clickBounce.duration
            easing.type: Appearance.animation.clickBounce.type
            easing.bezierCurve: Appearance.animation.clickBounce.bezierCurve
        }
    }

    CircularProgress { // Fills while you hold, then hands over to the picker
        anchors.centerIn: parent
        implicitSize: root.width + 2 * root.ringGap + 3 * root.ringStroke
        lineWidth: root.ringStroke
        enableAnimation: false
        value: root.holdProgress
        opacity: root.holdProgress > 0 ? 1 : 0
        colPrimary: Appearance.colors.colPrimary
        colSecondary: "transparent"

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Item {
        id: face
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.offline ? Appearance.colors.colLayer2 : Appearance.colors.colSecondaryContainer
        }

        StyledText {
            anchors.centerIn: parent
            opacity: root.showsInitial ? 1 : 0
            font.pixelSize: 16
            font.weight: Font.Medium
            color: root.offline ? Appearance.colors.colSubtext : Appearance.colors.colOnSecondaryContainer
            text: Fresence.initialFor(root.member)

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            opacity: root.showsInitial ? 0 : 1
            fill: 0
            text: root.hidden ? "visibility_off" : "lock"
            iconSize: root.height * 0.5
            color: root.hidden || !root.offline ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    Rectangle {
        id: badge
        width: 13
        height: 13
        radius: 6.5
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        color: {
            if (root.offline)
                return Appearance.colors.colLayer2;
            if (root.hidden)
                return Appearance.colors.colSecondary;
            return Appearance.colors.colPrimary;
        }
        border.width: 2
        border.color: Appearance.colors.colLayer2

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        id: gesture
        anchors.fill: parent
        enabled: root.interactive
        preventStealing: true // The row scrolls under it, and a slid finger belongs to the picker

        property bool picking: false

        onPressed: {
            gesture.picking = false;
            hold.restart();
        }
        onPositionChanged: mouse => {
            if (gesture.picking)
                root.holdMoved(mouse.x, mouse.y);
        }
        onReleased: gesture.finish()
        onCanceled: gesture.finish()

        function finish(): void {
            hold.stop();
            root.holdProgress = 0;
            if (!gesture.picking) {
                root.tapped();
                return;
            }
            gesture.picking = false;
            root.holdEnded();
        }

        NumberAnimation {
            id: hold
            target: root
            property: "holdProgress"
            from: 0
            to: 1
            duration: root.holdDuration
            onFinished: {
                gesture.picking = true;
                root.holdProgress = 0;
                root.holdStarted();
            }
        }
    }
}
