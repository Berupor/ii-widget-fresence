pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

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
    readonly property bool expandable: root.bodyShown && root.detailWidgets.length > 0
    property bool showDetails: false
    property bool showActions: false

    function nextDevice(): void {
        const i = root.devices.indexOf(root.device);
        root.pickedDeviceId = root.devices[(i + 1) % root.devices.length]?.device_id ?? "";
    }

    onExpandableChanged: if (!root.expandable)
        root.showDetails = false
    onCanShareChanged: if (!root.canShare)
        root.showActions = false

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + 24
    radius: Appearance.rounding.normal
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

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PresenceAvatar {
                id: avatar
                Layout.alignment: Qt.AlignVCenter
                member: root.member
                offline: root.offline
                hidden: root.hidden
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

                    StyledText {
                        objectName: "memberStatus"
                        Layout.fillWidth: true
                        visible: text.length > 0
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: Fresence.statusFor(root.member, root.device, rowGrid.visible ? rowGrid.coverage : null)
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

            Rectangle { // Which card of the account is shown, and the way to the next one
                objectName: "deviceChip"
                visible: root.devices.length > 1 && !root.hidden
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 140
                radius: Appearance.rounding.full
                color: chipArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                implicitWidth: deviceChip.implicitWidth + 14
                implicitHeight: deviceChip.implicitHeight + 6

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                RowLayout {
                    id: deviceChip
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 14)
                    spacing: 3

                    MaterialSymbol {
                        text: Fresence.deviceIconFor(root.device)
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: Fresence.deviceNameFor(root.device)
                    }
                }

                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextDevice()
                }

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: chipArea.containsMouse
                    text: Translation.tr("%1 devices, click for the next one").arg(root.devices.length)
                }
            }
        }

        StyledText {
            visible: root.deviceAway && !isNaN(Date.parse(root.device?.seen_at ?? ""))
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            text: Translation.tr("Last seen %1").arg(Fresence.agoText(Date.parse(root.device?.seen_at ?? "")))
        }

        StyledText {
            visible: root.devices.length === 0 && !root.offline && !root.hidden
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            text: Translation.tr("The card has not arrived yet")
        }

        CardGrid {
            id: rowGrid
            Layout.fillWidth: true
            visible: root.bodyShown && rowGrid.rowsUsed > 0
            opacity: root.deviceAway ? 0.6 : 1
            device: root.device
            widgets: root.device?.card?.row ?? []
            grid: "row"
        }

        CardGrid {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.showDetails && root.expandable
            opacity: root.deviceAway ? 0.6 : 1
            device: root.device
            widgets: root.showDetails ? root.detailWidgets : []
            grid: "detail"
        }

        PresenceActions { // Middle click, own card only
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.showActions && root.canShare
        }
    }
}
