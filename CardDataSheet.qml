pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardRules.js" as Rules

/** "What to show": a gallery of live tile previews - device sources, custom values, new values and the other widget types. */
Item {
    id: root
    required property var config
    property var state: null
    property var otherTypes: Rules.otherTypes

    signal picked(string type, var source)
    signal valueCreated(string name, var source)
    signal valueDeleted(string id)
    signal dismissed

    property var target: null
    property var widgets: []
    property string grid: "row"
    property string photoFile: ""
    property string clipFile: ""

    readonly property real maxDialogHeight: 640
    readonly property real dialogChromeHeight: 70
    readonly property real dialogRadius: 26
    readonly property real sidePadding: 16
    readonly property real offerGap: 8
    readonly property real offerCell: 64
    readonly property real unfitOpacity: 0.38
    readonly property real sectionTitleSize: 14
    readonly property string commandMark: "terminal"
    implicitHeight: Math.min(root.maxDialogHeight, list.implicitHeight + root.dialogChromeHeight) + 32

    readonly property var categories: [
        {
            "id": "load",
            "title": "Resources"
        },
        {
            "id": "system",
            "title": "System"
        },
        {
            "id": "windows",
            "title": "Screen"
        },
        {
            "id": "schedule",
            "title": "Schedule"
        },
        {
            "id": "media",
            "title": "Now playing"
        },
        {
            "id": "chess",
            "title": "Chess"
        },
        {
            "id": "weather",
            "title": "Weather"
        },
        {
            "id": "photos",
            "title": "Photos and videos"
        }
    ]
    readonly property var sourceCategories: ({
            "cpu": "load",
            "memory": "load",
            "disk": "load",
            "battery": "system",
            "uptime": "system",
            "packages": "system",
            "window": "windows",
            "app": "windows",
            "workspace": "windows"
        })
    readonly property var typeCategories: ({
            "media": "media",
            "game": "media",
            "chess": "chess",
            "weather": "weather",
            "photo": "photos",
            "image": "photos",
            "clock": "schedule"
        })
    readonly property var kindShapes: ({
            "text": "text",
            "fill": "fill",
            "time": "time",
            "command": "text"
        })

    property real openedAt: 0
    readonly property var customIds: Object.keys(root.config?.values ?? {}).filter(id => !Rules.builtinSources.includes(id))

    readonly property var builtinOffers: Rules.builtinSources.map(id => root.offer("value", id, Translation.tr(Rules.sourceNames[id] ?? id), Rules.formsOffered(root.config, "value", id, root.state), {})).concat(root.otherTypes.map(t => root.offer(t, null, Translation.tr(Rules.typeNames[t] ?? t), Rules.formsOffered(root.config, t, null, root.state), {})))
    readonly property var customOffers: root.customIds.map(id => {
        const name = Rules.valueName(root.config, id);
        return root.offer("value", id, name || Translation.tr(Rules.sourceNames[id] ?? id), Rules.formsOffered(root.config, "value", id, root.state), {
            "label": name || null,
            "removable": true
        });
    })
    readonly property var newOffers: Rules.newValueKinds.map(kind => {
        const name = Translation.tr(Rules.valueKindNames[kind] ?? kind);
        return root.offer("value", `new_${kind}`, name, Rules.shapeForms[root.kindShapes[kind]], {
            "label": name,
            "newKind": kind,
            "mark": kind === "command" ? root.commandMark : ""
        });
    })
    readonly property var sections: root.categories.map(c => ({
                "title": Translation.tr(c.title),
                "offers": root.builtinOffers.filter(o => root.categoryOf(o) === c.id)
            })).concat([
        {
            "title": Translation.tr("Custom values"),
            "offers": root.customOffers
        },
        {
            "title": Translation.tr("New value"),
            "offers": root.newOffers
        }
    ]).filter(s => s.offers.length > 0)

    readonly property var previewDevice: {
        const samples = Rules.sampleValues(root.openedAt);
        const values = {};
        for (const id of root.customIds) {
            const own = root.config.values[id];
            values[id] = own.value ?? (own.command ? {
                "text": `$ ${own.command}`
            } : Rules.placeholderValue(Rules.shapeOf(root.config, id, root.state), root.openedAt));
        }
        for (const kind of Rules.newValueKinds) {
            const source = Rules.newValueSource(kind, Translation.tr(Rules.valueKindNames[kind] ?? kind), root.openedAt);
            values[`new_${kind}`] = source.value ?? {
                "text": `$ ${source.command}`
            };
        }
        const shown = Rules.preview(root.config, root.state, root.openedAt);
        return {
            "state": Object.assign({}, shown, {
                "chess": root.state?.chess ?? Rules.sampleChess(root.openedAt),
                "values": Object.assign({}, samples, values, root.state?.values ?? {})
            }),
            "photo_file": root.photoFile,
            "clip_file": root.clipFile
        };
    }

    Keys.onEscapePressed: root.dismissed()
    onVisibleChanged: if (root.visible) {
        root.openedAt = Fresence.now;
        root.forceActiveFocus();
    }

    function sizesOf(form, type, rows): var {
        return Rules.preferredSizes(form, type).filter(s => s.rows <= rows).sort((a, b) => b.cols * b.rows - a.cols * a.rows);
    }

    function canHold(size): bool {
        if (root.target.replace !== undefined)
            return Rules.resized(root.widgets, root.target.replace, size, root.grid) !== null;
        if (!root.target.at)
            return Rules.firstFree(root.widgets, size, root.grid) !== null;
        return Rules.canPlace(root.widgets, {
            "col": root.target.at[0],
            "row": root.target.at[1],
            "cols": size.cols,
            "rows": size.rows
        }, root.grid);
    }

    function fits(type, form, size): bool {
        if (!root.target || root.target.status)
            return true;
        return Rules.distinctSizes([size].concat(root.sizesOf(form, type, Rules.rowsOf(root.grid)))).some(s => root.canHold(s));
    }

    function offer(type, source, title, forms, extra): var {
        const form = forms[0] ?? null;
        const size = root.sizesOf(form, type, 1)[0] ?? Rules.preferredSizes(form, type)[0];
        return Object.assign({
            "type": type,
            "source": source,
            "title": title,
            "removable": false,
            "mark": "",
            "fits": root.fits(type, form, size),
            "tile": Rules.withFields({
                "type": type,
                "place": {
                    "col": 0,
                    "row": 0,
                    "cols": size.cols,
                    "rows": size.rows
                }
            }, {
                "source": type === "value" ? source : null,
                "form": form,
                "label": extra.label ?? null
            })
        }, extra);
    }

    function categoryOf(offer): string {
        return typeCategories[offer.type] ?? sourceCategories[offer.source] ?? "system";
    }

    function activate(offer): void {
        if (offer.newKind)
            root.valueCreated(offer.title, Rules.newValueSource(offer.newKind, offer.title, Fresence.now));
        else
            root.picked(offer.type, offer.type === "value" ? offer.source : null);
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
        radius: root.dialogRadius
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
                    spacing: root.offerGap

                    Repeater {
                        model: root.sections

                        delegate: ColumnLayout {
                            id: section
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: root.sidePadding
                            Layout.rightMargin: root.sidePadding
                            spacing: 4

                            StyledText {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                text: section.modelData.title
                                color: Appearance.colors.colPrimary
                                font.pixelSize: root.sectionTitleSize
                                font.weight: Font.Medium
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: root.offerGap

                                Repeater {
                                    model: section.modelData.offers

                                    delegate: Offer {
                                        required property var modelData
                                        title: modelData.title
                                        tile: modelData.tile
                                        mark: modelData.mark
                                        removable: modelData.removable
                                        opacity: modelData.fits ? 1 : root.unfitOpacity
                                        onClicked: root.activate(modelData)
                                        onRemoveRequested: root.valueDeleted(modelData.source)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component Offer: Rectangle {
        id: offer
        required property string title
        required property var tile
        property string mark: ""
        property bool removable: false
        signal clicked
        signal removeRequested

        readonly property real tileWidth: offer.span(offer.tile.place.cols)
        readonly property color captionColor: offer.mark !== "" ? Appearance.colors.colPrimary : Appearance.colors.colSubtext

        function span(cells): real {
            return cells * root.offerCell + (cells - 1) * root.offerGap;
        }

        implicitWidth: offer.tileWidth + 2 * root.offerGap
        implicitHeight: body.implicitHeight + 2 * root.offerGap
        radius: root.dialogRadius
        color: Appearance.m3colors.m3surfaceContainerLow

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: offer.clicked()
        }

        ColumnLayout {
            id: body
            anchors {
                fill: parent
                margins: root.offerGap
            }
            spacing: 6

            CardTile {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: offer.tileWidth
                Layout.preferredHeight: offer.span(offer.tile.place.rows)
                widget: offer.tile
                device: root.previewDevice
            }

            RowLayout {
                Layout.preferredWidth: offer.tileWidth
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Item {
                    Layout.fillWidth: true
                }

                MaterialSymbol {
                    visible: offer.mark !== ""
                    text: offer.mark
                    iconSize: 16
                    color: offer.captionColor
                }

                StyledText {
                    Layout.maximumWidth: offer.tileWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: offer.title
                    elide: Text.ElideRight
                    color: offer.captionColor
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                }

                MaterialSymbol {
                    visible: offer.removable
                    text: "delete"
                    iconSize: 16
                    color: Appearance.colors.colSubtext

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: offer.removeRequested()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
