import QtQuick

PresencePhoto {
    required property var card
    radius: 0
    cropped: true
    path: card.photoFile
    expiresAt: Date.parse(card.photo?.expires_at ?? "")
    settleGif: Fresence.opt("pauseGifs")
    settleSeconds: Fresence.opt("gifPauseSeconds")
}
