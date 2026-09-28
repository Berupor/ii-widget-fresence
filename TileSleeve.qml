import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

/** A record sliding out of its sleeve, the title and progress underneath. */
Item {
    id: form
    required property var card
    readonly property var media: form.card.media
    readonly property real mediaProgress: CardLayouts.mediaProgress(form.media, form.card.now)
    readonly property real discShift: 0.42
    readonly property real textHeight: 48
    readonly property real sleeveSide: Math.max(0, Math.min(form.width / (1 + form.discShift), form.height - form.textHeight))
    readonly property color vinylBlack: "#141416"
    readonly property var grooveRadii: [0.92, 0.82, 0.72, 0.62]
    readonly property int turnDurationMs: 9000

    Item {
        id: disc
        x: form.sleeveSide * form.discShift
        width: form.sleeveSide
        height: form.sleeveSide

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: form.vinylBlack
        }

        Repeater {
            model: form.grooveRadii

            Rectangle {
                required property real modelData
                anchors.centerIn: parent
                width: disc.width * modelData
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.07)
            }
        }

        Item {
            id: label
            anchors.centerIn: parent
            width: Math.round(disc.width * 0.5)
            height: label.width

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: label.width
                    height: label.height
                    radius: label.width / 2
                }
            }

            PresenceArt {
                anchors.fill: parent
                color: form.card.artPlaceholder
                source: form.media?.art_url ?? ""
                fallbackIcon: ""
                playing: form.card.animating
            }

            RotationAnimation on rotation {
                running: form.media?.playing === true
                paused: running && !form.card.animating
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: form.turnDurationMs
            }
        }

        Rectangle {
            visible: (form.media?.art_url ?? "").length > 0
            anchors.centerIn: parent
            width: disc.width * 0.06
            height: width
            radius: width / 2
            color: form.vinylBlack
        }
    }

    PresenceArt {
        objectName: "sleeveArt"
        width: form.sleeveSide
        height: form.sleeveSide
        radius: 6
        color: form.card.artPlaceholder
        fallbackColor: form.card.artAccent
        source: form.media?.art_url ?? ""
        fallbackIcon: form.media?.kind === "video" ? "smart_display" : "music_note"
        playing: form.card.animating
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 6

        MediaTitle {
            Layout.fillWidth: true
            card: form.card
            lines: 1
        }
        WaveBar {
            objectName: "sleeveProgress"
            Layout.fillWidth: true
            visible: form.mediaProgress >= 0
            color: form.card.contentColor
            to: 1
            value: Math.max(0, form.mediaProgress)
            wavy: false
        }
    }
}
