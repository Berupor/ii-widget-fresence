import QtQuick

PresencePhoto {
    required property var card
    radius: 0
    color: Qt.alpha(card.contentColor, backingAlpha)
    cropped: true
    path: card.photoFile
    expiresAt: Date.parse(card.photo?.expires_at ?? "")
    badge: card.widget.place.cols > 1 || card.widget.place.rows > 1
    shape: card.shape
    tileInset: card.tileInset
    settleGif: Fresence.opt("pauseGifs")
    settleSeconds: Fresence.opt("gifPauseSeconds")
}
