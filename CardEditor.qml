pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "CardRules.js" as Rules

/** The card editor of the fresence app: this device's row and detail grids, saved to the agent's config. */
Item {
    id: root
    implicitWidth: content.implicitWidth
    implicitHeight: Math.max(content.implicitHeight, sheet.visible ? sheet.implicitHeight : 0)

    // The config as the agent last took it, and the one being edited
    property var stored: null
    property var draft: null
    // idle | pending | saved | invalid | failed
    property string saveState: "idle"
    property var draftProblems: []
    // { user, player } of the chess.com check, player null while it runs
    property var chessCheck: null
    property string saveError: ""

    readonly property int sectionTitleSize: 14
    property string grid: "row"
    property int selectedIndex: -1
    // null, or where the data sheet puts what it picks: { "at": [col, row] | null }, { "replace": index } or { "status": true }
    property var picking: null
    readonly property bool hasRoom: Rules.firstFree(root.widgets, Rules.size(1, 1), root.grid) !== null

    readonly property var widgets: root.draft ? Rules.widgetsOf(root.draft, root.grid) : []
    readonly property var device: Fresence.selfDevice
    readonly property var previewDevice: ({
            "state": Rules.preview(root.draft ?? {}, root.device?.state ?? null, Fresence.now),
            "photo_file": root.device?.photo_file ?? ""
        })

    Component.onCompleted: Fresence.loadConfig()

    Connections {
        target: Fresence
        function onConfigLoaded(config) {
            root.stored = config;
            root.draft = Rules.fitted(config);
        }
        function onConfigSaved(config) {
            if (Rules.sameConfig(config, root.draft)) {
                root.stored = config;
                root.saveState = "saved";
            }
        }
        function onConfigSaveFailed(config, error) {
            if (Rules.sameConfig(config, root.draft)) {
                root.saveError = error;
                root.saveState = "failed";
            }
        }
    }

    readonly property string checkableChessUser: root.draft?.chess_user !== undefined && Rules.isChessUser(root.draft.chess_user) ? root.draft.chess_user : ""

    onCheckableChessUserChanged: {
        chessCheckTimer.stop();
        root.chessCheck = root.checkableChessUser ? {
            "user": root.checkableChessUser,
            "player": null
        } : null;
        if (root.chessCheck)
            chessCheckTimer.restart();
    }

    function runChessCheck(): void {
        if (Fresence.underHarness || chessCheckProc.running || !root.chessCheck)
            return;
        chessCheckProc.user = root.chessCheck.user;
        chessCheckProc.running = true;
    }

    Timer {
        id: chessCheckTimer
        interval: Rules.chessCheckDebounceMs
        onTriggered: root.runChessCheck()
    }

    Process {
        id: chessCheckProc
        property string user: ""
        command: Fresence.agentCommand(["chess", chessCheckProc.user])
        stdout: StdioCollector {
            id: chessReply
        }
        onExited: exitCode => {
            const player = Rules.chessPlayer(exitCode, chessReply.text);
            if (root.chessCheck?.user === chessCheckProc.user)
                root.chessCheck = {
                    "user": chessCheckProc.user,
                    "player": player
                };
            else if (root.chessCheck && !chessCheckTimer.running)
                root.runChessCheck();
        }
    }

    onChessCheckChanged: root.refreshSave()
    onDraftChanged: root.refreshSave()

    function refreshSave(): void {
        saveTimer.stop();
        if (!root.draft)
            return;
        if (Rules.sameConfig(root.draft, root.stored)) {
            if (root.saveState !== "saved")
                root.saveState = "idle";
            return;
        }
        root.draftProblems = Rules.problems(root.draft).concat(Rules.chessUserMissing(root.draft, root.chessCheck, root.stored) ? ["chess_missing"] : []);
        if (root.draftProblems.length > 0) {
            root.saveState = "invalid";
            return;
        }
        root.saveState = "pending";
        if (!Rules.awaitsChessCheck(root.draft, root.chessCheck, root.stored))
            saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: Rules.saveDebounceMs
        onTriggered: Fresence.saveConfig(root.draft)
    }

    function problemText(code: string): string {
        switch (code) {
        case "value_source":
            return Translation.tr("a value widget has no data selected");
        case "image_url":
            return Translation.tr("an image needs an https:// address");
        case "name_length":
            return Translation.tr("a name must be 1 to 64 characters");
        case "value_id":
            return Translation.tr("a value name must use Latin letters, digits and _");
        case "background_url":
            return Translation.tr("a background needs an https:// address");
        case "value_empty":
            return Translation.tr("a value has neither text nor time");
        case "chess_user":
            return Translation.tr("a chess.com username is 3 to 25 Latin letters, digits, _ or -");
        case "chess_missing":
            return Translation.tr("no such player on chess.com");
        default:
            return Translation.tr("a command needs an interval");
        }
    }

    readonly property string saveText: {
        switch (root.saveState) {
        case "pending":
            return Translation.tr("Saving");
        case "saved":
            return Translation.tr("Saved");
        case "invalid":
            return Translation.tr("Not saved: %1").arg(root.draftProblems.map(p => root.problemText(p)).join(", "));
        case "failed":
            return Translation.tr("Not saved: %1").arg(root.saveError);
        default:
            return "";
        }
    }

    function editWidgets(widgets, select): void {
        root.draft = Rules.withWidgets(root.draft, root.grid, widgets);
        root.selectedIndex = select;
    }

    function showGrid(grid: string): void {
        root.grid = grid;
        root.selectedIndex = -1;
    }

    function startAdding(): void {
        root.picking = {
            "at": null
        };
    }

    // base can carry a just-created value, kept even when the widget does not fit
    function pick(base, type, source, label): void {
        const target = root.picking;
        root.picking = null;
        if (!target)
            return;
        if (target.status) {
            const status = Rules.statusOf(base);
            root.draft = type === "value" && !status.includes(source) ? Rules.withStatus(base, status.concat([source])) : base;
            return;
        }
        const state = root.device?.state ?? null;
        if (target.replace !== undefined) {
            const list = Rules.widgetsOf(base, root.grid);
            const next = list.map((w, i) => i === target.replace ? Rules.withData(base, w, type, source, state, label) : w);
            root.draft = Rules.withWidgets(base, root.grid, next);
            return;
        }
        const widget = Rules.newWidget(base, type, source, state, label);
        const list = Rules.widgetsOf(base, root.grid);
        const next = Rules.added(list, widget, root.grid, target.at, Rules.preferredSizes(widget.form, widget.type));
        if (next) {
            root.draft = Rules.withWidgets(base, root.grid, next);
            root.selectedIndex = next.length - 1;
        } else {
            root.draft = base;
        }
    }

    function createValue(name, source): void {
        const id = Rules.valueIdFor(name, Rules.sources(root.draft));
        root.pick(Rules.withValue(root.draft, id, source), "value", id, name);
    }

    function deleteValue(id): void {
        root.draft = Rules.withValue(root.draft, id, null);
    }

    function applyVariant(variant): void {
        const next = Rules.resized(root.widgets, root.selectedIndex, variant.size, root.grid);
        if (next)
            root.editWidgets(next.map((w, i) => i === root.selectedIndex ? Rules.withFields(w, {
                            "form": variant.form
                        }) : w), root.selectedIndex);
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 24
            visible: !root.draft
            spacing: 6

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: Fresence.configLoadError ? "error" : "dashboard_customize"
                iconSize: Appearance.font.pixelSize.hugeass * 1.5
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Fresence.configLoadError ? Translation.tr("Could not open the card settings") : Translation.tr("Opening the card settings…")
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: Fresence.configLoadError
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
        }

        RippleButtonWithIcon {
            visible: !root.draft && Fresence.configLoadError !== ""
            Layout.alignment: Qt.AlignHCenter
            materialIcon: "refresh"
            mainText: Translation.tr("Retry")
            onClicked: Fresence.loadConfig()
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !!root.draft
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: Fresence.nameOf(Fresence.account?.devices ?? []) || Translation.tr("Your name")
                    text: root.draft?.account_name ?? ""
                    onTextChanged: {
                        if (text !== (root.draft?.account_name ?? ""))
                            root.draft = Rules.withFields(root.draft, {
                                "account_name": text
                            });
                    }
                }

                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: Fresence.deviceNameFor(root.device) || Translation.tr("Device name")
                    text: root.draft?.device_name ?? ""
                    onTextChanged: {
                        if (text !== (root.draft?.device_name ?? ""))
                            root.draft = Rules.withFields(root.draft, {
                                "device_name": text
                            });
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: Translation.tr("Instead of Online")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: root.sectionTitleSize
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: Rules.statusOf(root.draft)

                        delegate: RippleButtonWithIcon {
                            required property string modelData
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            materialIcon: "close"
                            mainText: Rules.valueName(root.draft, modelData) || Translation.tr(Rules.sourceNames[modelData] ?? modelData)
                            onClicked: root.draft = Rules.withStatus(root.draft, Rules.statusOf(root.draft).filter(id => id !== modelData))
                        }
                    }

                    RippleButtonWithIcon {
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        materialIcon: "add"
                        mainText: Translation.tr("Add source")
                        onClicked: root.picking = {
                            "status": true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.buttonRadius
                            color: "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Your room sees the first of these with a value, unless you are playing or listening to something")
                    wrapMode: Text.WordWrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            SecondaryTabBar {
                id: gridTabs
                Layout.fillWidth: true
                currentIndex: root.grid === "row" ? 0 : 1
                onCurrentIndexChanged: root.showGrid(gridTabs.currentIndex === 0 ? "row" : "detail")

                SecondaryTabButton {
                    buttonText: Translation.tr("Row")
                }
                SecondaryTabButton {
                    buttonText: Translation.tr("Details")
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.saveText !== ""
                text: root.saveText
                elide: Text.ElideRight
                color: root.saveState === "invalid" || root.saveState === "failed" ? Appearance.colors.colError : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            CardGridEditor {
                id: gridEditor
                Layout.fillWidth: true
                Layout.topMargin: gridEditor.handleOverhang
                Layout.bottomMargin: gridEditor.handleOverhang
                widgets: root.widgets
                grid: root.grid
                device: root.device
                previewDevice: root.previewDevice
                selectedIndex: root.selectedIndex
                onSelected: index => root.selectedIndex = index
                onEdited: widgets => root.editWidgets(widgets, root.selectedIndex)
                onRemoveRequested: index => root.editWidgets(Rules.removed(root.widgets, index), -1)
                onEmptyCellClicked: (col, row) => root.picking = {
                    "at": [col, row]
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.hasRoom
                text: Translation.tr("Click an empty cell to add a widget. Drag a selected widget to move it, drag its corner to resize.")
                wrapMode: Text.WordWrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            CardWidgetPanel {
                Layout.fillWidth: true
                visible: root.selectedIndex >= 0 && root.selectedIndex < root.widgets.length
                config: root.draft
                widgets: root.widgets
                index: root.selectedIndex
                grid: root.grid
                state: root.device?.state ?? null
                previewDevice: root.previewDevice
                onChanged: w => root.editWidgets(root.widgets.map((old, i) => i === root.selectedIndex ? w : old), root.selectedIndex)
                onVariantChosen: v => root.applyVariant(v)
                onValueChanged: v => {
                    const source = root.widgets[root.selectedIndex]?.source;
                    if (source)
                        root.draft = Rules.withValue(root.draft, source, v);
                }
                chessCheck: root.chessCheck
                onChessUserEdited: user => root.draft = Rules.withChessUser(root.draft, user)
                onChangeDataRequested: root.picking = {
                    "replace": root.selectedIndex
                }
            }

            ConfigSwitch {
                buttonIcon: "tune"
                text: Translation.tr("Advanced editor")
                checked: root.draft?.advanced_editor === true
                onCheckedChanged: {
                    if (checked !== (root.draft?.advanced_editor === true))
                        root.draft = Rules.withFields(root.draft, {
                            "advanced_editor": checked ? true : null
                        });
                }
            }

            RippleButtonWithIcon {
                visible: root.hasRoom
                materialIcon: "add"
                mainText: Translation.tr("Add widget")
                onClicked: root.startAdding()
            }
        }
    }

    CardDataSheet {
        id: sheet
        anchors.fill: parent
        visible: root.picking !== null
        config: root.draft ?? ({})
        state: root.device?.state ?? null
        target: root.picking
        widgets: root.widgets
        grid: root.grid
        photoFile: root.device?.photo_file ?? ""
        clipFile: root.device?.clip_file ?? ""
        otherTypes: root.picking?.status ? [] : Rules.otherTypes
        onPicked: (type, source) => root.pick(root.draft, type, source, null)
        onValueCreated: (name, source) => root.createValue(name, source)
        onValueDeleted: id => root.deleteValue(id)
        onDismissed: root.picking = null
    }
}
