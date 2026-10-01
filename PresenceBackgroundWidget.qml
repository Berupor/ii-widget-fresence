pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import "CardLayouts.js" as CardLayouts

// Same room presence rows as the left sidebar, as a card on the wallpaper.
AbstractBackgroundWidget {
    id: root

    configEntryName: "presence"
    // Placement comes from the widget store, not from Config
    configEntry: QtObject {
        readonly property string placementStrategy: Fresence.opt("wallpaperPlacement")
        readonly property real x: Fresence.opt("wallpaperX")
        readonly property real y: Fresence.opt("wallpaperY")
    }
    onReleased: { // Store writes only on drop, a binding back into the store would loop
        root.targetX = root.x;
        root.targetY = root.y;
        WidgetsStore.setOption(Fresence.widgetId, "wallpaperX", root.x);
        WidgetsStore.setOption(Fresence.widgetId, "wallpaperY", root.y);
    }

    readonly property bool shown: Fresence.opt("wallpaperCard") && Fresence.available
    readonly property var freshAccountIds: {
        if (!root.shown)
            return [];
        const maxRows = Fresence.opt("wallpaperMaxRows");
        const ids = Fresence.memberIds.filter(id => !Fresence.opt("wallpaperHideOffline") || Fresence.membersById[id].presence.kind !== "offline");
        return maxRows > 0 ? ids.slice(0, maxRows) : ids;
    }
    property var shownAccountIds: []
    onFreshAccountIdsChanged: {
        if (!CardLayouts.sameArray(root.shownAccountIds, root.freshAccountIds))
            root.shownAccountIds = root.freshAccountIds;
    }
    Component.onCompleted: root.shownAccountIds = root.freshAccountIds

    // The host keeps the card loaded, so switching it off is opacity, not unloading
    opacity: (root.shown && !(GlobalStates.screenLocked && !root.visibleWhenLocked)) ? 1 : 0
    visible: root.opacity > 0
    implicitWidth: Fresence.opt("wallpaperWidth")
    implicitHeight: card.implicitHeight

    StyledDropShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: column.implicitHeight + 24
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0
        clip: true // Content is full height immediately; without this the bg catches up visibly

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: column
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            StyledText {
                Layout.leftMargin: 6
                font.pixelSize: 14
                color: Appearance.colors.colSubtext
                text: Fresence.headerText()
            }

            Repeater {
                model: root.shownAccountIds
                delegate: PresenceRow {}
            }
        }
    }
}
