import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import "CardLayouts.js" as CardLayouts

/** An analog clock in the card owner's time zone, from state.utc_offset_s. */
Item {
    id: form
    required property var card

    readonly property var time: CardLayouts.clockAt(form.card.state?.utc_offset_s ?? 0, Fresence.now)
    readonly property real side: Math.min(form.width, form.height)
    readonly property real dialAlpha: 0.14
    readonly property real numeralAlpha: 0.16
    readonly property real hourBadgeAlpha: 0.22
    readonly property real minuteBadgeAlpha: 0.12
    readonly property real badgeSize: form.side * 0.28
    readonly property real handWidthHour: form.side * 0.08
    readonly property real handWidthMinute: form.side * 0.05
    readonly property real handLengthHour: form.side * 0.24
    readonly property real handLengthMinute: form.side * 0.36

    function ink(alpha: real): color {
        return ColorUtils.applyAlpha(form.card.contentColor, alpha);
    }

    Item {
        id: face
        objectName: "analogFace"
        anchors.centerIn: parent
        width: form.side
        height: form.side

        MaterialShape {
            anchors.fill: parent
            shape: MaterialShape.Shape.Cookie12Sided
            color: form.ink(form.dialAlpha)
        }

        Repeater {
            model: [12, 3, 6, 9]

            StyledText {
                required property int modelData
                readonly property real angle: modelData / 12 * 2 * Math.PI - Math.PI / 2
                x: face.width / 2 + face.width * 0.33 * Math.cos(angle) - width / 2
                y: face.height / 2 + face.width * 0.33 * Math.sin(angle) - height / 2
                font.pixelSize: face.width * 0.2
                font.weight: Font.Medium
                color: form.ink(form.numeralAlpha)
                text: modelData
            }
        }

        Repeater {
            model: [
                {
                    "turns": form.time.hourTurns,
                    "length": form.handLengthHour,
                    "width": form.handWidthHour
                },
                {
                    "turns": form.time.minuteTurns,
                    "length": form.handLengthMinute,
                    "width": form.handWidthMinute
                }
            ]

            Item {
                required property var modelData
                x: face.width / 2
                y: face.height / 2
                rotation: modelData.turns * 360

                Rectangle {
                    x: -modelData.width / 2
                    y: -modelData.length - modelData.width / 2
                    width: modelData.width
                    height: modelData.length + modelData.width
                    radius: modelData.width / 2
                    color: form.card.contentColor
                }
            }
        }

        Rectangle {
            objectName: "analogHourBadge"
            anchors.left: parent.left
            anchors.top: parent.top
            width: form.badgeSize
            height: form.badgeSize
            radius: width / 2
            color: form.ink(form.hourBadgeAlpha)

            StyledText {
                anchors.centerIn: parent
                font.pixelSize: form.side * 0.13
                font.weight: Font.Medium
                color: form.card.contentColor
                text: form.time.hour
            }
        }

        Rectangle {
            objectName: "analogMinuteBadge"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: form.badgeSize
            height: form.badgeSize
            radius: width / 2
            color: form.ink(form.minuteBadgeAlpha)

            StyledText {
                anchors.centerIn: parent
                font.pixelSize: form.side * 0.13
                font.weight: Font.Medium
                color: form.card.contentColor
                text: String(form.time.minute).padStart(2, "0")
            }
        }
    }
}
