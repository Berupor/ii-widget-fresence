pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Steam art of the game with its name and session over it. Steam serves a header for
 * every title, the rest only where the publisher uploaded them, so each form falls back
 * a picture at a time. A banner carries the logo instead of the name where there is one.
 */
Item {
    id: form
    required property var card
    readonly property var game: form.card.game
    readonly property var art: form.game?.art ?? {}
    readonly property bool banner: form.card.form === "banner"
    readonly property var urls: (form.banner ? [form.art.header, form.art.hero, form.art.cover] : [form.art.cover, form.art.header]).filter(url => !!url)
    readonly property string logo: form.banner ? (form.art.logo ?? "") : ""
    readonly property real startedMs: Date.parse(form.game?.started_at ?? "")

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer2
    }

    PresenceArt {
        id: picture
        anchors.fill: parent
        radius: 0
        color: "transparent"
        fallbackIcon: "sports_esports"
        source: form.urls[0] ?? ""
        fallbacks: form.urls.slice(1)
        playing: form.card.animating
    }

    Rectangle {
        anchors.fill: parent
        // Black, not colScrim: a light logo over a white sky needs it, and the palette has no say in someone else's art
        gradient: Gradient {
            GradientStop {
                position: 0.35
                color: Qt.rgba(0, 0, 0, 0)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0, 0, 0, 0.78)
            }
        }
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Math.max(6, Math.round(Math.min(form.width, form.height) * 0.1))
        }
        spacing: 2

        PresenceArt {
            visible: form.logo.length > 0 && form.height >= 64
            Layout.preferredWidth: Math.round(form.width * 0.45)
            Layout.preferredHeight: Math.round(form.height * 0.35)
            radius: 0
            color: "transparent"
            fallbackIcon: ""
            source: form.logo
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignBottom
        }
        StyledText {
            objectName: "gameName"
            Layout.fillWidth: true
            visible: form.logo.length === 0 || form.height < 64
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.pixelSize: Appearance.font.pixelSize.normal
            color: "white"
            text: form.game?.name ?? ""
        }
        StyledText {
            objectName: "gameSession"
            Layout.fillWidth: true
            visible: !isNaN(form.startedMs) && form.height >= 48
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: form.card.mutedContentColor
            text: Translation.tr("%1 in game").arg(Fresence.stopwatchText(form.card.now - form.startedMs))
        }
    }
}
