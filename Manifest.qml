import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "fresence"
    name: Translation.tr("Fresence")
    description: Translation.tr("Who's around in your fresence room")
    icon: "groups"
    version: "2.0"
    author: "Berupor"
    minShellVersion: "1.0"
    available: Fresence.available
    settingsPage: "FresenceSettings.qml"
    options: [ // Values only, FresenceSettings draws them
        { "key": "incognito", "default": true },
        { "key": "incognitoIndicator", "default": true },
        { "key": "photoShare", "default": true },
        { "key": "pauseGifs", "default": true },
        { "key": "gifPauseSeconds", "default": 4 },
        { "key": "wallpaperCard", "default": false },
        { "key": "wallpaperPlacement", "default": "free" },
        { "key": "wallpaperX", "default": 100 },
        { "key": "wallpaperY", "default": 500 },
        { "key": "wallpaperWidth", "default": 360 },
        { "key": "wallpaperHideOffline", "default": false },
        { "key": "wallpaperMaxRows", "default": 0 },
        { "key": "room", "default": "" }
    ]
    slots: ({
        "barIndicator": "FresenceIncognitoIndicator.qml",
        "sidebarLeftTab": { "name": Translation.tr("Room"), "icon": "groups", "path": "PresenceTab.qml" },
        "backgroundWidget": "PresenceBackgroundWidget.qml",
        "regionAction": { "name": "share", "path": "ShareRegionAction.qml" }
    })
}
