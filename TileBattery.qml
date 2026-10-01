import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

Item {
    id: form
    required property var card
    readonly property int cols: form.card.widget?.place?.cols ?? 1
    readonly property int rows: form.card.widget?.place?.rows ?? 1
    readonly property real pad: form.card.tileInset
    readonly property bool upward: form.rows > 1 || form.cols === 1
    readonly property bool single: form.cols === 1
    readonly property bool tall: form.rows > 1
    readonly property bool centered: form.cols === form.rows && form.card.shape !== "rounded"
    readonly property real levelAlpha: form.card.lowBattery ? 0.3 : 0.16
    readonly property string label: form.card.labelText || Translation.tr("Battery")
    readonly property string glyph: form.card.charging ? "bolt" : (form.card.lowBattery ? "battery_alert" : "battery_full")
    readonly property real glyphSize: 16
    readonly property real progress: form.card.hasData ? form.card.fill : 0
    property real shown: form.progress

    Behavior on shown {
        NumberAnimation {
            duration: CardLayouts.fillAnimationMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: CardLayouts.fillEasing
        }
    }

    component Percent: RowLayout {
        property real size
        property bool bolt: form.card.charging
        spacing: Math.round(size * 0.08)

        StyledText {
            objectName: "batteryValue"
            text: form.card.shownValueText
            font.pixelSize: size
            font.weight: Font.Medium
            font.letterSpacing: -0.02 * size
            font.features: ({
                    "tnum": 1
                })
            color: form.card.contentColor
        }
        MaterialSymbol {
            objectName: "batteryBolt"
            visible: bolt
            text: "bolt"
            iconSize: size * 0.8
            color: form.card.contentColor
        }
    }

    component Status: StyledText {
        objectName: "batteryStatus"
        text: form.card.batteryStatus
        font.pixelSize: Appearance.font.pixelSize.small
        color: form.card.lowBattery ? form.card.levelColor : form.card.mutedContentColor
    }

    component Label: StyledText {
        objectName: "batteryLabel"
        text: form.label
        font.pixelSize: Appearance.font.pixelSize.smaller
        elide: Text.ElideRight
        color: form.card.mutedContentColor
    }

    Rectangle {
        objectName: "batteryLevel"
        x: 0
        y: form.upward ? form.height * (1 - form.shown) : 0
        width: form.upward ? form.width : form.width * form.shown
        height: form.upward ? form.height * form.shown : form.height
        color: Qt.rgba(form.card.levelColor.r, form.card.levelColor.g, form.card.levelColor.b, form.card.levelColor.a * form.levelAlpha)
    }

    ColumnLayout {
        visible: form.centered
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            objectName: "batteryGlyph"
            Layout.alignment: Qt.AlignHCenter
            text: form.glyph
            iconSize: form.tall ? 24 : form.glyphSize
            color: form.card.levelColor
        }
        Percent {
            Layout.alignment: Qt.AlignHCenter
            size: form.tall ? 40 : 22
            bolt: false
        }
        Status {
            Layout.alignment: Qt.AlignHCenter
            visible: form.tall
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: form.pad
        visible: !form.centered && form.single && !form.tall

        MaterialSymbol {
            objectName: "batteryGlyph"
            anchors.top: parent.top
            anchors.left: parent.left
            text: form.glyph
            iconSize: form.glyphSize
            color: form.card.levelColor
        }
        Percent {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            size: 22
            bolt: false
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: form.pad
        visible: !form.centered && form.tall

        Label {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
        }
        ColumnLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            spacing: 0

            Percent {
                size: Math.min(48, (form.width - 2 * form.pad) / 3.1)
            }
            Status {}
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: form.pad
        anchors.right: parent.right
        anchors.rightMargin: form.pad
        anchors.verticalCenter: parent.verticalCenter
        visible: !form.centered && !form.single && !form.tall && form.cols === 2
        spacing: 0

        Label {
            Layout.fillWidth: true
        }
        Percent {
            size: 28
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: form.pad
        anchors.right: parent.right
        anchors.rightMargin: form.pad
        anchors.verticalCenter: parent.verticalCenter
        visible: !form.centered && !form.single && !form.tall && form.cols > 2

        Percent {
            size: 30
        }
        Item {
            Layout.fillWidth: true
        }
        ColumnLayout {
            spacing: 0

            Label {
                Layout.alignment: Qt.AlignRight
            }
            Status {
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
