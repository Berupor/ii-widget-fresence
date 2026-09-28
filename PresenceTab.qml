pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Who's around in the room: live presence, activity, now playing.
Item {
    id: root

    property bool pickingRoom: false
    readonly property bool switchable: Fresence.rooms.length > 1

    onSwitchableChanged: if (!root.switchable)
        root.pickingRoom = false

    PagePlaceholder {
        shown: Fresence.memberIds.length === 0
        icon: "groups"
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
        description: Fresence.placeholderText()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 4
        }
        spacing: 6
        visible: Fresence.memberIds.length > 0

        RowLayout { // Opens the room list when there is more than one room
            objectName: "roomHeader"
            Layout.leftMargin: 12 // On the axis the rows' content starts at
            spacing: 2

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: Fresence.headerText()
            }

            MaterialSymbol {
                visible: root.switchable
                text: root.pickingRoom ? "unfold_less" : "unfold_more"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }

            TapHandler {
                enabled: root.switchable
                cursorShape: Qt.PointingHandCursor
                onTapped: root.pickingRoom = !root.pickingRoom
            }
        }

        ColumnLayout {
            objectName: "roomList"
            Layout.fillWidth: true
            visible: root.pickingRoom
            spacing: 2

            Repeater {
                model: root.pickingRoom ? Fresence.rooms : []

                delegate: RippleButton {
                    id: roomButton
                    required property var modelData
                    readonly property bool current: roomButton.modelData.room_id === Fresence.room?.room_id
                    Layout.fillWidth: true
                    implicitHeight: roomLine.implicitHeight + 12
                    buttonRadius: Appearance.rounding.small
                    colBackground: roomButton.current ? Appearance.colors.colLayer2 : "transparent"
                    onClicked: {
                        Fresence.selectRoom(roomButton.modelData.room_id);
                        root.pickingRoom = false;
                    }

                    contentItem: RowLayout {
                        id: roomLine
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 10

                        MaterialSymbol {
                            text: roomButton.current ? "radio_button_checked" : "radio_button_unchecked"
                            iconSize: Appearance.font.pixelSize.larger
                            color: roomButton.current ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                color: Appearance.colors.colOnLayer1
                                text: Fresence.roomTitle(roomButton.modelData)
                            }
                            StyledText {
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("%1 of %2 online").arg(Fresence.roomOnlineCount(roomButton.modelData)).arg(roomButton.modelData.members.length)
                            }
                        }
                    }
                }
            }
        }

        StyledFlickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: column.implicitHeight
            clip: true

            ColumnLayout {
                id: column
                width: flickable.width
                spacing: 12

                Repeater {
                    model: Fresence.memberIds
                    delegate: Item {
                        id: rowSlot
                        required property string modelData
                        readonly property bool inView: rowSlot.y + rowSlot.height > flickable.contentY && rowSlot.y < flickable.contentY + flickable.height
                        Layout.fillWidth: true
                        implicitHeight: row.implicitHeight

                        PresenceRow {
                            id: row
                            width: rowSlot.width
                            modelData: rowSlot.modelData
                            visible: rowSlot.inView
                        }
                    }
                }
            }
        }
    }
}
