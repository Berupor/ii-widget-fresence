pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts

/** A member: face, name, status line, then the row grid of one device's card and its detail grid on click. */
Rectangle {
    id: root
    required property string modelData

    readonly property var member: Fresence.membersById[root.modelData] ?? null
    readonly property string presence: root.member?.presence.kind ?? "offline"
    readonly property bool offline: root.presence === "offline"
    readonly property bool hidden: root.presence === "incognito"
    readonly property bool isSelf: root.member?.isMe ?? false
    readonly property bool canPick: root.isSelf && Fresence.online && Fresence.opt("incognito")
    readonly property bool canShare: root.isSelf && Fresence.canShare
    readonly property var devices: root.member?.shownDevices ?? []

    property string pickedDeviceId: ""
    readonly property var device: root.devices.find(d => d.device_id === root.pickedDeviceId) ?? root.devices[root.member?.firstActiveIndex ?? 0] ?? null
    readonly property bool bodyShown: root.device !== null && !root.hidden && !Fresence.incognitoOf(root.device)
    readonly property bool deviceAway: root.bodyShown && !root.device.online && !root.offline
    readonly property var detailWidgets: root.device?.card?.detail ?? []
    readonly property bool expandable: root.bodyShown && CardLayouts.placed(root.detailWidgets, "detail", root.device, Fresence.now).length > 0
    readonly property bool deviceHidden: root.device !== null && root.device.online && Fresence.incognitoOf(root.device) !== null
    property bool showDetails: false
    property bool showActions: false

    readonly property real cardRadius: 28
    readonly property real sectionGap: 16
    readonly property real handleWidth: 32
    readonly property real handleHeight: 4
    readonly property real handleGap: 10
    readonly property real noCardTextSize: 14
    readonly property real stackChipSize: 18
    readonly property real stackIconSize: 11
    readonly property real stackPeek: 7
    readonly property real stackGapOpen: 4
    readonly property real stackRing: 1.5
    readonly property real stackLabelGap: 8
    readonly property real stackLabelMaxWidth: 96
    readonly property real offlineChipOpacity: 0.6

    function nextDevice(): void {
        const i = root.devices.indexOf(root.device);
        root.pickedDeviceId = root.devices[(i + 1) % root.devices.length]?.device_id ?? "";
    }

    onExpandableChanged: if (!root.expandable)
        root.showDetails = false
    onCanShareChanged: if (!root.canShare)
        root.showActions = false

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + 24 + (root.expandable ? root.handleGap + root.handleHeight : 0)
    radius: root.cardRadius
    color: Appearance.colors.colLayer1
    opacity: root.offline ? 0.6 : 1
    clip: true // Content is full height immediately; without this the bg catches up visibly

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea { // Under everything, so the tiles and the chips get their clicks first
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: (pressedButtons & (Qt.RightButton | Qt.MiddleButton)) !== 0 // else the host sidebar's SwipeView can grab the press as a swipe
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.canShare)
                    root.showActions = !root.showActions;
                return;
            }
            if (root.expandable)
                root.showDetails = !root.showDetails;
        }
    }

    Rectangle {
        objectName: "expandHandle"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        width: root.handleWidth
        height: root.handleHeight
        radius: root.handleHeight / 2
        color: Appearance.colors.colOutlineVariant
        opacity: root.expandable ? 1 : 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PresenceAvatar {
                id: avatar
                Layout.alignment: Qt.AlignVCenter
                member: root.member
                offline: root.offline
                hidden: root.hidden || root.deviceHidden
                interactive: root.canPick
                onHoldStarted: picker.open = true
                onHoldMoved: (x, y) => {
                    const point = avatar.mapToItem(picker, x, y);
                    picker.hoverAt(point.x, point.y);
                }
                onHoldEnded: {
                    picker.apply();
                    picker.open = false;
                    picker.hovered = -1;
                }
                onTapped: if (root.expandable)
                    root.showDetails = !root.showDetails
            }

            Item { // Who they are, or the picker while you're holding your own row
                Layout.fillWidth: true
                implicitHeight: Math.max(info.implicitHeight, picker.implicitHeight)

                ColumnLayout {
                    id: info
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2
                    opacity: picker.open ? 0 : 1

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    StyledText {
                        objectName: "memberName"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        color: Appearance.colors.colOnLayer2
                        text: Fresence.nameFor(root.member)
                    }

                    RowLayout {
                        id: statusLine
                        Layout.fillWidth: true
                        spacing: 4
                        readonly property var covered: rowGrid.visible ? rowGrid.coverage : null
                        readonly property string icon: Fresence.statusIconFor(root.member, root.device, statusLine.covered)

                        MaterialSymbol {
                            visible: statusLine.icon.length > 0
                            text: statusLine.icon
                            iconSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            objectName: "memberStatus"
                            Layout.fillWidth: true
                            visible: text.length > 0
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            text: Fresence.statusFor(root.member, root.device, statusLine.covered)
                        }
                    }
                }

                PresenceIncognitoPicker {
                    id: picker
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                }
            }

            RowLayout { // Which card of the account is shown: a stack of chips that fans out on hover
                id: deviceStack
                objectName: "deviceChip"
                visible: root.devices.length > 1 && !root.hidden
                Layout.alignment: Qt.AlignVCenter
                spacing: root.stackLabelGap

                readonly property bool open: stackHover.hovered
                readonly property int current: root.devices.indexOf(root.device)
                property real spread: open ? 1 : 0
                property int pointed: -1

                onOpenChanged: if (!deviceStack.open)
                    deviceStack.pointed = -1

                Behavior on spread {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                HoverHandler {
                    id: stackHover
                }

                StyledText {
                    visible: deviceStack.spread > 0
                    opacity: deviceStack.spread
                    Layout.maximumWidth: root.stackLabelMaxWidth
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    text: Fresence.deviceNameFor(root.devices[deviceStack.pointed >= 0 ? deviceStack.pointed : deviceStack.current])
                }

                Item {
                    id: chipStrip
                    readonly property real gap: -(root.stackChipSize - root.stackPeek) + (root.stackGapOpen + root.stackChipSize - root.stackPeek) * deviceStack.spread

                    implicitWidth: root.devices.length * root.stackChipSize + (root.devices.length - 1) * chipStrip.gap
                    implicitHeight: root.stackChipSize

                    Repeater {
                        model: root.devices

                        delegate: Rectangle {
                            id: stackChip
                            required property var modelData
                            required property int index
                            readonly property bool active: stackChip.index === deviceStack.current

                            x: stackChip.index * (root.stackChipSize + chipStrip.gap)
                            z: -Math.abs(stackChip.index - deviceStack.current)
                            width: root.stackChipSize
                            height: root.stackChipSize
                            radius: width / 2
                            opacity: stackChip.modelData.online ? 1 : root.offlineChipOpacity
                            color: stackChip.active ? Appearance.colors.colSecondaryContainer : Appearance.colors.colSurfaceContainerHighest
                            border.width: root.stackRing
                            border.color: root.color

                            MaterialSymbol {
                                anchors.centerIn: parent
                                opacity: stackChip.active ? 1 : deviceStack.spread
                                iconSize: root.stackIconSize
                                text: Fresence.deviceIconFor(stackChip.modelData)
                                color: stackChip.active ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: deviceStack.open
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onContainsMouseChanged: if (containsMouse)
                                    deviceStack.pointed = stackChip.index
                                onClicked: root.pickedDeviceId = stackChip.modelData.device_id
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            visible: root.devices.length === 0 && !root.offline && !root.hidden
            Layout.fillWidth: true
            Layout.topMargin: root.sectionGap
            font.pixelSize: root.noCardTextSize
            color: Appearance.colors.colSubtext
            text: Translation.tr("The card has not arrived yet")
        }

        CardGrid {
            id: rowGrid
            Layout.fillWidth: true
            Layout.topMargin: root.sectionGap
            visible: root.bodyShown && rowGrid.rowsUsed > 0
            opacity: root.deviceAway ? 0.6 : 1
            device: root.device
            widgets: root.device?.card?.row ?? []
            grid: "row"
        }

        CardGrid {
            Layout.fillWidth: true
            Layout.topMargin: root.sectionGap
            visible: root.showDetails && root.expandable
            opacity: root.deviceAway ? 0.6 : 1
            device: root.device
            widgets: root.showDetails ? root.detailWidgets : []
            grid: "detail"
        }

        PresenceActions { // Middle click, own card only
            Layout.fillWidth: true
            Layout.topMargin: 12
            visible: root.showActions && root.canShare
        }
    }
}
