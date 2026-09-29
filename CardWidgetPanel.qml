pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "CardLayouts.js" as CardLayouts
import "CardRules.js" as Rules

/** The selected tile's editor: change data, value fields, a size/form gallery, icon and color, and the extras of the advanced editor. */
ColumnLayout {
    id: root
    objectName: "widgetPanel"
    required property var config
    required property var widgets
    required property int index
    required property string grid
    property var state: null
    property var previewDevice: null
    property var chessCheck: null

    signal changed(var widget)
    signal variantChosen(var variant)
    signal valueChanged(var source)
    signal changeDataRequested
    signal chessUserEdited(string user)

    readonly property var widget: root.widgets[root.index] ?? null
    readonly property string sourceId: root.widget?.type === "value" ? (root.widget.source ?? "") : ""
    readonly property string shape: root.sourceId ? Rules.shapeOf(root.config, root.sourceId, root.state) : ""
    readonly property var valueSource: root.sourceId ? (root.config.values?.[root.sourceId] ?? null) : null
    readonly property string title: root.sourceId ? (Rules.valueName(root.config, root.sourceId) || Translation.tr(Rules.sourceNames[root.sourceId] ?? root.sourceId)) : Translation.tr(Rules.typeNames[root.widget?.type ?? ""] ?? "")
    readonly property string symbol: root.widget ? Rules.widgetSymbol(root.widget, root.shape) : ""
    readonly property var variants: root.widget ? Rules.variants(root.config, root.widgets, root.index, root.grid, root.state) : []

    readonly property bool advanced: root.config?.advanced_editor === true
    readonly property bool showsIcon: root.widget?.type === "value" && !["dial", "figure"].includes(CardLayouts.shownForm(root.widget))

    function withField(fields): void {
        if (root.widget)
            root.changed(Rules.withFields(root.widget, fields));
    }

    spacing: 12

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: content.implicitHeight + 16
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer2

        ColumnLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 12

            RippleButton {
                objectName: "widgetPanelHeader"
                Layout.fillWidth: true
                implicitHeight: 40
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.changeDataRequested()

                contentItem: RowLayout {
                    spacing: 10

                    MaterialSymbol {
                        text: root.symbol
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: root.title
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                    MaterialSymbol {
                        text: "unfold_more"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }

            MaterialTextField {
                Layout.fillWidth: true
                visible: root.widget?.type === "image"
                placeholderText: Translation.tr("Image address https://")
                text: root.widget?.url ?? ""
                onTextChanged: {
                    const url = text.trim();
                    if (url !== (root.widget?.url ?? ""))
                        root.withField({
                            "url": url
                        });
                }
            }

            ChessUserField {
                Layout.fillWidth: true
                visible: root.widget?.type === "chess"
                user: root.config?.chess_user ?? ""
                check: root.chessCheck
                onChanged: user => root.chessUserEdited(user)
            }

            MaterialTextField {
                Layout.fillWidth: true
                visible: root.valueSource !== null
                placeholderText: Translation.tr("Value name")
                text: root.widget?.label ?? ""
                onTextChanged: {
                    if (text !== (root.widget?.label ?? ""))
                        root.withField({
                            "label": text
                        });
                }
            }

            ValueFields {
                Layout.fillWidth: true
                visible: root.valueSource !== null
                source: root.valueSource ?? ({})
                onChanged: v => root.valueChanged(v)
            }

            Gallery {
                Layout.fillWidth: true
                visible: root.variants.length > 1
                widget: root.widget
                variants: root.variants
                device: root.previewDevice
                onPicked: v => root.variantChosen(v)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14

                MaterialTextField {
                    Layout.fillWidth: true
                    visible: root.advanced && root.widget?.type === "value" && root.valueSource === null
                    placeholderText: Translation.tr("Label")
                    text: root.widget?.label ?? ""
                    onTextChanged: {
                        if (text !== (root.widget?.label ?? ""))
                            root.withField({
                                "label": text
                            });
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.showsIcon
                    spacing: 6

                    StyledText {
                        text: Translation.tr("Icon")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    IconPicker {
                        Layout.fillWidth: true
                        selected: root.widget?.icon ?? ""
                        onPicked: icon => root.withField({
                                "icon": icon
                            })
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.widget?.type !== "photo" && root.widget?.type !== "image"
                    spacing: 6

                    StyledText {
                        text: Translation.tr("Color")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    ColorPicker {
                        Layout.fillWidth: true
                        selected: root.widget?.color ?? ""
                        onPicked: role => root.withField({
                                "color": role
                            })
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.advanced
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: Translation.tr("Shape")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        ShapePicker {
                            selected: root.widget?.shape ?? "rounded"
                            onPicked: shape => root.withField({
                                    "shape": shape === "rounded" ? null : shape
                                })
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.shape === "time"
                        spacing: 6

                        StyledText {
                            text: Translation.tr("Time")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: true
                            currentValue: root.widget?.time_mode ?? "auto"
                            onSelected: v => root.withField({
                                    "time_mode": v === "auto" ? null : v
                                })
                            options: [
                                {
                                    "displayName": Translation.tr("Auto"),
                                    "value": "auto"
                                },
                                {
                                    "displayName": Translation.tr("Until"),
                                    "value": "until"
                                },
                                {
                                    "displayName": Translation.tr("Since"),
                                    "value": "since"
                                }
                            ]
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: CardLayouts.takesBackground(root.widget)
                        spacing: 6

                        StyledText {
                            text: Translation.tr("Background")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: true
                            currentValue: root.widget?.background?.kind ?? ""
                            onSelected: v => root.withField({
                                    "background": v === "" ? null : v === "url" ? {
                                        "kind": v,
                                        "url": root.widget?.background?.url ?? ""
                                    } : {
                                        "kind": v
                                    }
                                })
                            options: [""].concat(Rules.backgroundKinds).map(k => ({
                                    "displayName": Translation.tr(Rules.backgroundNames[k]),
                                    "icon": Rules.backgroundSymbols[k],
                                    "value": k
                                }))
                        }
                        MaterialTextField {
                            Layout.fillWidth: true
                            visible: root.widget?.background?.kind === "url"
                            placeholderText: Translation.tr("Picture address https://, a GIF plays for a few seconds")
                            text: root.widget?.background?.url ?? ""
                            onTextChanged: {
                                const url = text.trim();
                                if (url !== (root.widget?.background?.url ?? ""))
                                    root.withField({
                                        "background": {
                                            "kind": "url",
                                            "url": url
                                        }
                                    });
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            text: Translation.tr("When there is no data")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                        ConfigSelectionArray {
                            Layout.fillWidth: true
                            currentValue: root.widget?.on_missing ?? "hide"
                            onSelected: v => root.withField({
                                    "on_missing": v === "hide" ? null : v
                                })
                            options: [
                                {
                                    "displayName": Translation.tr("Dim"),
                                    "value": "dim"
                                },
                                {
                                    "displayName": Translation.tr("Hide"),
                                    "value": "hide"
                                }
                            ]
                        }
                    }
                }
            }
        }
    }

    component ChessUserField: ColumnLayout {
        id: chessField
        property string user
        property var check: null
        signal changed(string user)

        readonly property var player: chessField.check?.user === chessField.user ? chessField.check.player : null
        readonly property bool malformed: chessField.user !== "" && !Rules.isChessUser(chessField.user)
        readonly property string hint: {
            if (chessField.malformed)
                return Translation.tr("A chess.com username is 3 to 25 Latin letters, digits, _ or -");
            if (chessField.user === "" || chessField.check?.user !== chessField.user)
                return "";
            switch (chessField.player?.kind) {
            case undefined:
                return Translation.tr("Checking...");
            case "missing":
                return Translation.tr("No such player on chess.com");
            case "found":
                return [Translation.tr(Rules.chessModeNames[chessField.player.mode] ?? ""), chessField.player.rating].filter(v => v).join(" ") || Translation.tr("Player found");
            default:
                return "";
            }
        }

        spacing: 2

        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: Translation.tr("chess.com username")
            text: chessField.user
            onTextChanged: {
                if (text.trim() !== chessField.user)
                    chessField.changed(text);
            }
        }

        StyledText {
            Layout.leftMargin: 4
            visible: chessField.hint !== ""
            text: chessField.hint
            color: chessField.malformed || chessField.player?.kind === "missing" ? Appearance.colors.colError : Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }

    component ValueFields: ColumnLayout {
        id: fields
        required property var source
        signal changed(var source)

        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            visible: fields.source.command === undefined && fields.source.value?.time === undefined
            spacing: 4

            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Text")
                text: fields.source.value?.text ?? ""
                onTextChanged: {
                    if (text !== (fields.source.value?.text ?? ""))
                        fields.changed(Rules.withFields(fields.source, {
                                "value": Rules.withFields(Object.assign({}, fields.source.value), {
                                        "text": text
                                    })
                            }));
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                visible: fields.source.value?.fill !== undefined
                from: 0
                to: 1
                value: fields.source.value?.fill ?? 0
                onMoved: fields.changed(Rules.withFields(fields.source, {
                            "value": Rules.withFields(Object.assign({}, fields.source.value), {
                                    "fill": Math.round(value * 100) / 100
                                })
                        }))
            }
        }

        TimeField {
            Layout.fillWidth: true
            visible: fields.source.value?.time !== undefined
            time: fields.source.value?.time ?? ""
            onCommitted: iso => fields.changed(Rules.withFields(fields.source, {
                        "value": {
                            "time": iso
                        }
                    }))
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: fields.source.command !== undefined
            spacing: 8

            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Command")
                font.family: Appearance.font.family.monospace
                text: fields.source.command ?? ""
                onTextChanged: {
                    if (text !== (fields.source.command ?? ""))
                        fields.changed(Rules.withFields(fields.source, {
                                "command": text
                            }));
                }
            }

            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Every, seconds")
                inputMethodHints: Qt.ImhDigitsOnly
                text: fields.source.interval_s?.toString() ?? ""
                onTextChanged: {
                    const filtered = text.replace(/\D/g, "").slice(0, 6);
                    if (filtered !== text) {
                        text = filtered;
                        return;
                    }
                    if (filtered !== (fields.source.interval_s?.toString() ?? ""))
                        fields.changed(Rules.withFields(fields.source, {
                                    "interval_s": filtered === "" ? null : parseInt(filtered, 10)
                                }));
                }
            }
        }
    }

    component TimeField: MaterialTextField {
        id: timeField
        required property string time
        signal committed(string iso)

        property string lastTime: ""
        readonly property real parsedMs: Date.parse(timeField.text.trim())
        readonly property bool badInput: timeField.text !== "" && isNaN(timeField.parsedMs)

        placeholderText: Translation.tr("Moment")
        color: timeField.badInput ? Appearance.colors.colError : Appearance.m3colors.m3onSurface

        onTimeChanged: {
            if (timeField.time !== timeField.lastTime) {
                timeField.lastTime = timeField.time;
                timeField.text = timeField.time;
            }
        }
        Component.onCompleted: {
            timeField.lastTime = timeField.time;
            timeField.text = timeField.time;
        }
        onTextChanged: {
            if (!timeField.badInput && timeField.text.trim() !== "")
                timeField.committed(new Date(timeField.parsedMs).toISOString());
        }
    }

    component Gallery: Item {
        id: gallery
        required property var widget
        required property var variants
        property var device: null
        signal picked(var variant)

        readonly property real cell: 40
        readonly property real cellGap: 4
        readonly property int tallestRows: gallery.variants.reduce((m, v) => Math.max(m, v.size.rows), 1)

        function span(cells): real {
            return cells > 0 ? cells * gallery.cell + (cells - 1) * gallery.cellGap : 0;
        }

        implicitHeight: gallery.span(gallery.tallestRows) + 24

        StyledFlickable {
            anchors.fill: parent
            contentWidth: row.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            clip: true

            RowLayout {
                id: row
                height: parent.height
                spacing: 12

                Repeater {
                    model: gallery.variants

                    delegate: ColumnLayout {
                        id: variantCell
                        required property var modelData
                        readonly property var variant: variantCell.modelData
                        readonly property bool isSelected: variantCell.modelData.form === CardLayouts.shownForm(gallery.widget) && variantCell.modelData.size.cols === gallery.widget.place.cols && variantCell.modelData.size.rows === gallery.widget.place.rows

                        function pick(): void {
                            gallery.picked(variantCell.modelData);
                        }

                        spacing: 6

                        Item {
                            Layout.preferredWidth: gallery.span(variantCell.modelData.size.cols)
                            Layout.preferredHeight: gallery.span(gallery.tallestRows)

                            CardTile {
                                width: gallery.span(variantCell.modelData.size.cols)
                                height: gallery.span(variantCell.modelData.size.rows)
                                anchors.bottom: parent.bottom
                                widget: Object.assign({}, gallery.widget, {
                                        "form": variantCell.modelData.form,
                                        "place": Object.assign({}, gallery.widget.place, variantCell.modelData.size)
                                    })
                                device: gallery.device

                                Rectangle {
                                    anchors.fill: parent
                                    visible: variantCell.isSelected
                                    radius: Appearance.rounding.large
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Appearance.colors.colPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: variantCell.pick()
                                }
                            }
                        }

                        StyledText {
                            Layout.preferredWidth: gallery.span(variantCell.modelData.size.cols)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: variantCell.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            text: variantCell.modelData.form ? Translation.tr(Rules.formNames[variantCell.modelData.form] ?? variantCell.modelData.form) : `${variantCell.modelData.size.cols}x${variantCell.modelData.size.rows}`
                        }
                    }
                }
            }
        }
    }

    component IconPicker: ColumnLayout {
        id: iconPicker
        required property string selected
        signal picked(string icon)

        spacing: 8

        Flow {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Rules.popularIcons

                delegate: RippleButton {
                    id: iconButton
                    required property string modelData
                    readonly property bool on: iconButton.modelData === iconPicker.selected

                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    colBackground: iconButton.on ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                    colBackgroundHover: iconButton.on ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer2Hover
                    onClicked: iconPicker.picked(iconButton.on ? "" : iconButton.modelData)

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: iconButton.modelData
                        iconSize: Appearance.font.pixelSize.large
                        color: iconButton.on ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                    }
                }
            }
        }

        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: Translation.tr("A Material Symbols name")
            text: iconPicker.selected
            onTextChanged: {
                const clean = text.trim().toLowerCase();
                const next = Rules.symbolNamePattern.test(clean) ? clean : "";
                if (next !== iconPicker.selected)
                    iconPicker.picked(next);
            }
        }
    }

    component ColorPicker: Flow {
        id: colorPicker
        required property string selected
        signal picked(string role)

        spacing: 8

        Repeater {
            model: [""].concat(Rules.colors)

            delegate: RippleButton {
                id: swatch
                required property string modelData
                readonly property bool on: swatch.modelData === colorPicker.selected
                readonly property var keys: CardLayouts.colorKeysOf(swatch.modelData)

                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: width / 2
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: colorPicker.picked(swatch.modelData)

                contentItem: Item {
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: swatch.on ? 3 : 1
                        border.color: swatch.on ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: width / 2
                        color: Appearance.colors[swatch.keys[0]]

                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: swatch.modelData === ""
                            text: "format_color_reset"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors[swatch.keys[1]]
                        }
                    }
                }
            }
        }
    }

    component ShapePicker: Row {
        id: shapePicker
        required property string selected
        signal picked(string shape)

        readonly property var shapes: ["rounded", "circle", "cookie", "clover"]
        spacing: 8

        Repeater {
            model: shapePicker.shapes

            delegate: RippleButton {
                id: shapeSwatch
                required property string modelData
                readonly property bool on: shapeSwatch.modelData === shapePicker.selected
                readonly property bool polygon: shapeSwatch.modelData === "cookie" || shapeSwatch.modelData === "clover"

                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: shapeSwatch.modelData === "circle" ? width / 2 : Appearance.rounding.large
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: shapePicker.picked(shapeSwatch.modelData)

                contentItem: Item {
                    Rectangle {
                        anchors.fill: parent
                        visible: !shapeSwatch.polygon
                        radius: shapeSwatch.modelData === "circle" ? width / 2 : Appearance.rounding.large
                        color: shapeSwatch.on ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    }
                    MaterialShape {
                        anchors.fill: parent
                        visible: shapeSwatch.polygon
                        shape: shapeSwatch.modelData === "cookie" ? MaterialShape.Shape.Cookie9Sided : MaterialShape.Shape.Clover4Leaf
                        color: shapeSwatch.on ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    }
                }
            }
        }
    }
}
