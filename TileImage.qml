import QtQuick

PresenceArt {
    required property var card
    radius: 0
    color: Qt.alpha(card.contentColor, backingAlpha)
    source: card.widget.url ?? ""
    fallbackIcon: "image"
    playing: card.animating
    settleGif: Fresence.opt("pauseGifs")
    settleSeconds: Fresence.opt("gifPauseSeconds")
}
