pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardRules.js" as Rules

/** "What to show": device sources, custom values, a form to add one, and the other widget types. */
Item {
    id: root
    required property var config
    property var state: null
    property var otherTypes: Rules.otherTypes

    signal picked(string type, var source)
    signal valueCreated(string name, var source)
    signal valueDeleted(string id)
    signal dismissed

    readonly property real maxDialogHeight: 640
    readonly property real dialogChromeHeight: 70
    implicitHeight: Math.min(root.maxDialogHeight, list.implicitHeight + root.dialogChromeHeight) + 32

    readonly property var customIds: Object.keys(root.config?.values ?? {}).filter(id => !Rules.builtinSources.includes(id))
    property bool creating: false

    Keys.onEscapePressed: root.dismissed()
    onVisibleChanged: if (root.visible)
        root.forceActiveFocus()

    function previewTextOf(id, value): string {
        if (!value)
            return "";
        const p = Rules.previewValueText(value);
        if (!p)
            return "";
        switch (p.kind) {
        case "time":
            return Fresence.clockText(p.at);
        case "fill":
            return `${p.percent}%`;
        default:
            return p.text;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colScrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 420)
        height: Math.min(parent.height - 32, root.maxDialogHeight, list.implicitHeight + root.dialogChromeHeight)
        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3surfaceContainerHigh

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                text: Translation.tr("What to show")
                font.pixelSize: Appearance.font.pixelSize.large
                elide: Text.ElideRight
            }

            StyledFlickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: list.implicitHeight

                ColumnLayout {
                    id: list
                    width: parent.width
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.topMargin: 8
                        text: Translation.tr("From the device")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    Repeater {
                        model: Rules.builtinSources

                        delegate: Choice {
                            required property string modelData
                            symbol: Rules.sourceSymbol(modelData, Rules.shapeOf(root.config, modelData, root.state))
                            title: Translation.tr(Rules.sourceNames[modelData] ?? modelData)
                            preview: root.previewTextOf(modelData, root.state?.values?.[modelData])
                            onClicked: root.picked("value", modelData)
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.topMargin: 8
                        text: Translation.tr("Custom values")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    Repeater {
                        model: root.customIds

                        delegate: Choice {
                            required property string modelData
                            symbol: Rules.sourceSymbol(modelData, Rules.shapeOf(root.config, modelData, root.state))
                            title: Rules.valueName(root.config, modelData) || Translation.tr(Rules.sourceNames[modelData] ?? modelData)
                            preview: root.previewTextOf(modelData, root.state?.values?.[modelData] ?? root.config?.values?.[modelData]?.value)
                            removable: true
                            onRemoveRequested: root.valueDeleted(modelData)
                            onClicked: root.picked("value", modelData)
                        }
                    }

                    Choice {
                        symbol: "add"
                        title: Translation.tr("New value")
                        onClicked: root.creating = !root.creating
                    }

                    NewValueForm {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        visible: root.creating
                        onCreate: (name, kind) => {
                            root.creating = false;
                            root.valueCreated(name, Rules.newValueSource(kind, name, Fresence.now));
                        }
                    }

                    TypeGroup {
                        title: Translation.tr("Other")
                        types: root.otherTypes.filter(t => !Rules.chessTypes.includes(t))
                    }

                    TypeGroup {
                        title: Translation.tr("Chess")
                        types: root.otherTypes.filter(t => Rules.chessTypes.includes(t))
                    }
                }
            }
        }
    }

    component TypeGroup: ColumnLayout {
        id: group
        property string title
        property var types: []

        Layout.fillWidth: true
        visible: group.types.length > 0
        spacing: 4

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.topMargin: 8
            text: group.title
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        Repeater {
            model: group.types

            delegate: Choice {
                required property string modelData
                symbol: Rules.typeSymbols[modelData] ?? "widgets"
                title: Translation.tr(Rules.typeNames[modelData] ?? modelData)
                onClicked: root.picked(modelData, null)
            }
        }
    }

    component Choice: RippleButton {
        id: choice
        required property string symbol
        required property string title
        property string preview: ""
        property bool removable: false
        signal removeRequested

        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        implicitHeight: 52
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer2Hover
        buttonRadius: Appearance.rounding.normal

        contentItem: RowLayout {
            spacing: 12

            MaterialSymbol {
                text: choice.symbol
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: choice.title
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: choice.preview !== ""
                    text: choice.preview
                    elide: Text.ElideRight
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            RippleButton {
                visible: choice.removable
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                onClicked: choice.removeRequested()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }

    component NewValueForm: ColumnLayout {
        id: form
        property string name: ""
        property string kind: "text"
        signal create(string name, string kind)

        spacing: 12

        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Name")
            text: form.name
            onTextChanged: form.name = text
        }

        ConfigSelectionArray {
            Layout.fillWidth: true
            currentValue: form.kind
            onSelected: v => form.kind = v
            options: Rules.newValueKinds.map(k => ({
                        "displayName": Translation.tr(Rules.valueKindNames[k] ?? k),
                        "value": k
                    }))
        }

        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: "add"
            mainText: Translation.tr("Add")
            enabled: form.name.trim() !== ""
            onClicked: {
                form.create(form.name.trim(), form.kind);
                form.name = "";
            }
        }
    }
}
