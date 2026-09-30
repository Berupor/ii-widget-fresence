pragma Singleton
pragma ComponentBehavior: Bound

// Room presence from the fresence agent's local api (github.com/Berupor/fresence):
// `fresence watch` prints a Snapshot (protocol/schema/snapshot.json) per line.

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import "CardLayouts.js" as CardLayouts

Singleton {
    id: root

    readonly property string widgetId: "fresence"
    property bool binaryFound: false
    readonly property bool available: root.binaryFound
    readonly property bool enabled: WidgetCatalog.isEnabled(root.widgetId)
    // A demo scene feeds the singleton itself, a real agent on the machine would overwrite it
    readonly property bool underHarness: (Quickshell.env("QS_HARNESS_OUT") ?? "") !== ""
    readonly property bool shouldRun: root.enabled && root.available && !root.underHarness

    /// Widget option by manifest key, for every file of this widget
    function opt(key: string): var {
        return WidgetCatalog.option(root.widgetId, key);
    }

    /// The one clip tile that plays with sound, null when all are muted
    property var loudClip: null

    function releaseLoudClip(owner: var): void {
        if (root.loudClip === owner)
            root.loudClip = null;
    }

    // install.sh puts the agent in ~/.local/bin, which the shell's own PATH may lack
    function agentCommand(args): var {
        return ["bash", "-c", "PATH=\"$HOME/.local/bin:$PATH\" exec fresence \"$@\"", "fresence"].concat(args);
    }

    readonly property int notRunningExitCode: 3

    property var snapshot: null
    property int watchExitCode: 0

    // status.state of the snapshot, or missing | not_running | starting before there is one
    readonly property string agentState: {
        if (root.snapshot)
            return root.snapshot.status.state;
        if (!root.binaryFound)
            return "missing";
        return root.watchExitCode === root.notRunningExitCode ? "not_running" : "starting";
    }
    readonly property bool online: root.agentState === "online"

    readonly property var account: root.snapshot?.account ?? null
    readonly property string selfAccountId: root.account?.account_id ?? ""
    readonly property string selfDeviceId: root.account?.device_id ?? ""
    readonly property var selfDevice: (root.account?.devices ?? []).find(d => d.device_id === root.selfDeviceId) ?? null

    readonly property var rooms: root.snapshot?.rooms ?? []
    // The pick shows at once instead of after the option store round-trips
    property string _pickedRoomId: ""
    readonly property string wantedRoomId: root._pickedRoomId || (root.opt("room") ?? "")
    readonly property var room: root.rooms.find(r => r.room_id === root.wantedRoomId) ?? root.rooms[0] ?? null

    function selectRoom(roomId: string): void {
        root._pickedRoomId = roomId;
        WidgetsStore.setOption(root.widgetId, "room", roomId);
    }

    function isOwnDevice(deviceId: string): bool {
        return (root.account?.devices ?? []).some(d => d.device_id === deviceId);
    }

    // A room roster repeats your own devices without card/state, the account carries them
    function devicesOf(member): var {
        return member.account_id === root.selfAccountId && root.account ? root.account.devices : (member.devices ?? []);
    }

    function nameOf(devices): string {
        return devices.map(d => d.card?.account_name ?? "").find(n => n.length > 0) ?? "";
    }

    function incognitoOf(device): var {
        return device?.state?.incognito ?? null;
    }

    function presenceOf(devices): var {
        const online = devices.filter(d => d.online);
        if (online.some(d => !root.incognitoOf(d)))
            return {
                "kind": "online"
            };
        const hidden = online.find(d => root.incognitoOf(d));
        if (hidden)
            return {
                "kind": "incognito",
                "note": root.incognitoOf(hidden).note ?? "",
                "until": Date.parse(root.incognitoOf(hidden).until ?? "")
            };
        const seen = devices.map(d => Date.parse(d.seen_at ?? "")).filter(t => !isNaN(t));
        return {
            "kind": "offline",
            "seenAt": seen.length > 0 ? Math.max(...seen) : NaN
        };
    }

    function memberOf(m): var {
        const devices = root.devicesOf(m);
        const shown = devices.filter(d => d.card);
        return {
            "id": m.account_id,
            "role": m.role,
            "isMe": m.account_id === root.selfAccountId,
            "name": root.nameOf(devices),
            "devices": devices,
            "shownDevices": shown,
            "sealed": shown.length === 0,
            "activeDevice": devices.find(d => d.online && !root.incognitoOf(d)) ?? null,
            "firstActiveIndex": Math.max(0, shown.findIndex(d => d.online && !root.incognitoOf(d))),
            "presence": root.presenceOf(devices)
        };
    }

    readonly property var membersById: {
        const byId = {};
        for (const m of (root.room?.members ?? []))
            byId[m.account_id] = root.memberOf(m);
        return byId;
    }

    readonly property var presenceOrder: ({
            "online": 0,
            "incognito": 1,
            "offline": 2
        })

    function compareMembers(a, b): int {
        const name = m => m.name ? m.name.toLowerCase() : "￿";
        return (a.isMe ? 0 : 1) - (b.isMe ? 0 : 1) || root.presenceOrder[a.presence.kind] - root.presenceOrder[b.presence.kind] || name(a).localeCompare(name(b)) || a.id.localeCompare(b.id);
    }

    // Rows look themselves up in membersById; reassigning this rebuilds every delegate
    property var memberIds: []

    onMembersByIdChanged: {
        const ids = Object.values(root.membersById).sort(root.compareMembers).map(m => m.id);
        if (!CardLayouts.sameArray(ids, root.memberIds))
            root.memberIds = ids;
    }

    readonly property int memberCount: root.memberIds.length
    readonly property int onlineCount: Object.values(root.membersById).filter(m => m.presence.kind !== "offline").length

    function roomTitle(room): string {
        const names = (room?.members ?? []).filter(m => m.account_id !== root.selfAccountId).map(m => root.nameOf(root.devicesOf(m)) || Translation.tr("No name"));
        if (names.length === 0)
            return Translation.tr("Just you");
        if (names.length <= 2)
            return names.join(", ");
        return Translation.tr("%1 and %2 more").arg(names.slice(0, 2).join(", ")).arg(names.length - 2);
    }

    function roomOnlineCount(room): int {
        return (room?.members ?? []).filter(m => root.presenceOf(root.devicesOf(m)).kind !== "offline").length;
    }

    function nameFor(member): string {
        return member?.name || Translation.tr("No name");
    }

    function initialFor(member): string {
        return member?.name ? member.name.charAt(0).toUpperCase() : "?";
    }

    function deviceNameFor(device): string {
        return device?.card?.device_name || (device?.device_id ?? "").slice(0, 8);
    }

    readonly property var deviceKindIcons: ({
            "phone": "smartphone",
            "laptop": "laptop",
            "desktop": "desktop_windows"
        })

    function deviceIconFor(device): string {
        return root.deviceKindIcons[device?.card?.device_kind] ?? "devices";
    }

    // Re-reads the clock for relative times, time_mode and photo expiry between snapshots
    property real now: Date.now()

    Timer {
        interval: 5000
        running: root.shouldRun
        repeat: true
        onTriggered: root.now = Date.now()
    }

    function spanOf(ms: real): var {
        const d = Math.abs(ms);
        if (d < 60000)
            return {
                "unit": "now",
                "n": 0
            };
        if (d < 3600000)
            return {
                "unit": "minutes",
                "n": Math.floor(d / 60000)
            };
        if (d < 86400000)
            return {
                "unit": "hours",
                "n": Math.floor(d / 3600000)
            };
        return {
            "unit": "days",
            "n": Math.floor(d / 86400000)
        };
    }

    function agoText(atMs: real): string {
        const s = root.spanOf(Math.max(0, root.now - atMs));
        switch (s.unit) {
        case "now":
            return Translation.tr("just now");
        case "minutes":
            return Translation.tr("%1 min ago").arg(s.n);
        case "hours":
            return Translation.tr("%1 h ago").arg(s.n);
        default:
            return s.n === 1 ? Translation.tr("1 day ago") : Translation.tr("%1 days ago").arg(s.n);
        }
    }

    function inText(atMs: real): string {
        const s = root.spanOf(atMs - root.now);
        switch (s.unit) {
        case "now":
            return Translation.tr("now");
        case "minutes":
            return Translation.tr("in %1 min").arg(s.n);
        case "hours":
            return Translation.tr("in %1 h").arg(s.n);
        default:
            return s.n === 1 ? Translation.tr("in 1 day") : Translation.tr("in %1 days").arg(s.n);
        }
    }

    function leftText(atMs: real): string {
        const left = atMs - root.now;
        return left < 3600000 ? Translation.tr("%1m").arg(Math.max(1, Math.floor(left / 60000))) : Translation.tr("%1h").arg(Math.floor(left / 3600000));
    }

    function clockText(atMs: real): string {
        const at = new Date(atMs);
        const time = Qt.formatTime(at, "HH:mm");
        return at.toDateString() === new Date(root.now).toDateString() ? time : `${Qt.formatDate(at, "dd.MM")} ${time}`;
    }

    function stopwatchText(ms: real): string {
        const total = Math.floor(Math.max(0, ms) / 1000);
        const days = Math.floor(total / 86400);
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor(total / 60) % 60;
        const seconds = String(total % 60).padStart(2, "0");
        if (days >= 1)
            return Translation.tr("%1d %2h").arg(days).arg(hours % 24);
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${seconds}` : `${minutes}:${seconds}`;
    }

    function sessionText(startedMs: real): string {
        const s = root.spanOf(Math.max(0, root.now - startedMs));
        switch (s.unit) {
        case "now":
            return Translation.tr("Now");
        case "minutes":
            return Translation.tr("%1m").arg(s.n);
        case "hours":
            return Translation.tr("%1h").arg(s.n);
        default:
            return Translation.tr("%1d").arg(s.n);
        }
    }

    // covered: what the row's visible tiles already show, so the line does not repeat it
    function statusFor(member, device, covered): string {
        const p = member?.presence;
        if (!p)
            return "";
        if (p.kind === "offline" && member.sealed)
            return Translation.tr("The name shows up once they come online");
        if (p.kind === "offline")
            return isNaN(p.seenAt) ? Translation.tr("Offline") : Translation.tr("Last seen %1").arg(root.agoText(p.seenAt));
        if (p.kind === "incognito") {
            const head = !isNaN(p.until) ? Translation.tr("Hidden until %1").arg(root.clockText(p.until)) : Translation.tr("Hidden");
            return p.note ? `${head} · ${p.note}` : head;
        }
        const speaks = device && device.online && !root.incognitoOf(device) ? device : member.activeDevice;
        const skip = speaks === device ? (covered ?? new Set()) : new Set();
        const state = speaks?.state ?? {};
        if (state.game && !skip.has("game")) {
            return Translation.tr("Playing %1").arg(state.game.name);
        }
        const media = state.media;
        if (media?.playing && !skip.has("media")) {
            if (media.kind === "video")
                return media.title;
            return media.artist ? `${media.title} - ${media.artist}` : media.title;
        }
        for (const id of speaks?.card?.status ?? []) {
            const text = state.values?.[id]?.text ?? "";
            if (text && !skip.has(`value:${id}`))
                return text;
        }
        return Translation.tr("Online");
    }

    readonly property var selfIncognito: root.incognitoOf(root.selfDevice)
    readonly property bool hiding: root.selfIncognito !== null
    readonly property string incognitoNote: root.selfIncognito?.note ?? ""
    readonly property real incognitoUntil: Date.parse(root.selfIncognito?.until ?? "")

    function incognitoLabel(): string {
        if (!root.hiding)
            return Translation.tr("Your room sees what you're up to");
        if (root.incognitoNote)
            return Translation.tr("Hidden · %1").arg(root.incognitoNote);
        if (!isNaN(root.incognitoUntil))
            return Translation.tr("Hidden until %1").arg(root.clockText(root.incognitoUntil));
        return Translation.tr("Hidden from your room");
    }

    function setIncognito(on: bool, minutes: int): void {
        incognitoProc.command = root.agentCommand(!on ? ["incognito", "off"] : (minutes > 0 ? ["incognito", "on", "--for", `${minutes}m`] : ["incognito", "on"]));
        incognitoProc.running = true;
    }

    function notify(body: string): void {
        Quickshell.execDetached(["notify-send", Translation.tr("Fresence"), body, "-a", "Shell"]);
    }

    function failureText(exitCode: int, fallback: string): string {
        return exitCode === root.notRunningExitCode ? Translation.tr("The fresence agent is not running") : fallback;
    }

    Process {
        id: incognitoProc
        onExited: exitCode => {
            if (exitCode !== 0)
                root.notify(root.failureText(exitCode, Translation.tr("Could not change incognito")));
        }
    }

    readonly property var selfPhoto: root.selfDevice?.state?.photo ?? null
    readonly property bool canShare: root.online && root.opt("photoShare")
    property bool posting: false
    property string lastPostError: ""

    readonly property string resizeArgs: "-resize '1600x1600>' -quality 88"
    readonly property string postTempPath: `${Directories.screenshotTemp}/fresence-post.jpg`

    function postPhoto(path: string): void {
        if (!path)
            return;
        root.startPost(`magick '${StringUtils.shellSingleQuoteEscape(path)}' ${root.resizeArgs} jpg:'${root.postTempPath}'`);
    }

    // Source is the region selector's throwaway screenshot, so it goes away with the crop
    function postRegion(sourcePath: string, x: real, y: real, width: real, height: real): void {
        const source = StringUtils.shellSingleQuoteEscape(sourcePath);
        const crop = `-crop ${Math.round(width)}x${Math.round(height)}+${Math.round(x)}+${Math.round(y)} +repage`;
        root.startPost(`magick '${source}' ${crop} ${root.resizeArgs} jpg:'${root.postTempPath}' && rm -f '${source}'`);
    }

    function startPost(prepareCommand: string): void {
        if (!root.canShare || root.posting)
            return;
        root.lastPostError = "";
        postProc.command = ["bash", "-c", `mkdir -p '${Directories.screenshotTemp}' && ${prepareCommand} && ` //
            + `PATH="$HOME/.local/bin:$PATH" fresence photo '${root.postTempPath}'; ` //
            + `status=$?; rm -f '${root.postTempPath}'; exit $status`];
        root.posting = true;
        postProc.running = true;
    }

    Process {
        id: postProc
        onExited: exitCode => {
            root.posting = false;
            if (exitCode === 0) {
                root.notify(Translation.tr("Photo shared with your room"));
                return;
            }
            root.lastPostError = root.failureText(exitCode, Translation.tr("Could not share the photo"));
            root.notify(root.lastPostError);
        }
    }

    // Spotify's MPRIS url is an open.spotify.com link, OpenUri wants the spotify: form
    function spotifyUriOf(media): string {
        const m = (media?.url ?? "").match(/^(?:https:\/\/open\.spotify\.com\/|spotify:)(track|episode)[\/:]([A-Za-z0-9]+)/);
        return m ? `spotify:${m[1]}:${m[2]}` : "";
    }

    function canSync(device): bool {
        return root.spotifyUriOf(device?.state?.media) !== "" && !root.isOwnDevice(device?.device_id ?? "");
    }

    function syncSpotify(device): void {
        const uri = root.spotifyUriOf(device?.state?.media);
        if (!uri)
            return;
        Quickshell.execDetached(["dbus-send", "--session", "--type=method_call", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.OpenUri", `string:${uri}`]);
    }

    function placeholderText(): string {
        switch (root.agentState) {
        case "missing":
            return Translation.tr("The fresence agent is not installed");
        case "not_running":
            return Translation.tr("The fresence agent is not running");
        case "starting":
            return Translation.tr("Waiting for the agent…");
        case "unlinked":
            return Translation.tr("This device is not linked yet.\nPaste an invite from a friend, or a code from \"Link a device\" on your other device");
        case "linking":
            return Translation.tr("Linking this device…");
        case "update_required":
            return root.snapshot?.status?.update ? Translation.tr("The agent needs updating to %1").arg(root.snapshot.status.update) : Translation.tr("The agent needs updating");
        }
        if (root.rooms.length === 0)
            return root.online ? Translation.tr("Not in a room yet.\nPaste an invite from a friend or start your own room") : Translation.tr("Connecting to the server…");
        return Translation.tr("Nobody around yet");
    }

    // What the empty tab offers to do about its state: install | start | code | ""
    readonly property string placeholderAction: {
        switch (root.agentState) {
        case "missing":
            return "install";
        case "not_running":
            return "start";
        case "unlinked":
            return "code";
        }
        return root.online && root.rooms.length === 0 ? "code" : "";
    }

    readonly property string installUrl: "https://github.com/Berupor/Fresence#clients"

    function startAgent(): void {
        startProc.running = true;
    }

    Process {
        id: startProc
        command: ["systemctl", "--user", "start", "fresence"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.notify(Translation.tr("Could not start the fresence agent"));
                return;
            }
            root.retryDelay = root.retryMin;
            restartTimer.restart();
        }
    }

    /// invite | link for a fresence:// code, "" when it is not one
    function offerKind(code: string): string {
        const encoded = code.trim().match(/^fresence:\/\/([A-Za-z0-9_-]+)$/)?.[1];
        if (!encoded)
            return "";
        const base64 = encoded.replace(/-/g, "+").replace(/_/g, "/");
        try {
            const kind = JSON.parse(Qt.atob(base64 + "=".repeat((4 - base64.length % 4) % 4)))?.kind;
            return kind === "invite" || kind === "link" ? kind : "";
        } catch (e) {
            return "";
        }
    }

    property bool redeeming: false
    property string redeemError: ""

    signal redeemed

    function redeem(code: string): void {
        const kind = root.offerKind(code);
        if (!kind || root.redeeming)
            return;
        root.redeemError = "";
        redeemProc.command = root.agentCommand([kind === "link" ? "link" : "join", code.trim()]);
        root.redeeming = true;
        redeemProc.running = true;
    }

    Process {
        id: redeemProc
        stderr: StdioCollector {
            id: redeemErrors
        }
        onExited: exitCode => {
            root.redeeming = false;
            if (exitCode === 0) {
                root.redeemed();
                return;
            }
            const said = redeemErrors.text.trim().split("\n").pop().replace(/^fresence: /, "");
            root.redeemError = root.failureText(exitCode, said || Translation.tr("Could not use the code"));
        }
    }

    property bool creatingRoom: false

    function createRoom(): void {
        if (root.underHarness || root.creatingRoom)
            return;
        root.creatingRoom = true;
        createRoomProc.running = true;
    }

    // busctl rather than the CLI: it answers with the full room id, the CLI prints a short one
    Process {
        id: createRoomProc
        command: root.agentBusCall("CreateRoom", [])
        stdout: StdioCollector {
            id: createRoomReply
        }
        stderr: StdioCollector {
            id: createRoomErrors
        }
        onExited: exitCode => {
            root.creatingRoom = false;
            if (exitCode !== 0) {
                root.notify(root.busFailureText(createRoomErrors.text, Translation.tr("Could not create a room")));
                return;
            }
            try {
                root.selectRoom(JSON.parse(createRoomReply.text).data[0]);
            } catch (e) {
                root.notify(Translation.tr("Could not create a room"));
            }
        }
    }

    // The card grids live in the agent's config, only its D-Bus api reads and writes them
    function agentBusCall(method: string, args): var {
        return ["busctl", "--user", "--json=short", "call", "app.fresence.Agent", "/app/fresence/Agent", "app.fresence.Agent1", method].concat(args);
    }

    function busFailureText(stderr: string, fallback: string): string {
        return stderr.trim().split("\n")[0].replace(/^Call failed: /, "") || fallback;
    }

    property bool configLoading: false
    property string configLoadError: ""

    // A demo scene answers a load by emitting configLoaded itself
    signal configLoaded(var config)
    signal configSaved(var config)
    signal configSaveFailed(var config, string error)

    function loadConfig(): void {
        if (root.underHarness || root.configLoading)
            return;
        root.configLoadError = "";
        root.configLoading = true;
        configLoadProc.running = true;
    }

    Process {
        id: configLoadProc
        command: root.agentBusCall("Config", [])
        stdout: StdioCollector {
            id: configReply
        }
        stderr: StdioCollector {
            id: configLoadErrors
        }
        onExited: exitCode => {
            root.configLoading = false;
            if (exitCode !== 0) {
                root.configLoadError = root.busFailureText(configLoadErrors.text, Translation.tr("Could not open the card settings"));
                return;
            }
            try {
                root.configLoaded(JSON.parse(JSON.parse(configReply.text).data[0]));
            } catch (e) {
                root.configLoadError = Translation.tr("Could not open the card settings");
            }
        }
    }

    property bool configSaving: false
    property var _queuedConfig: null

    // A save while another is in flight waits for it, and only the latest one waiting is sent
    function saveConfig(config): void {
        if (root.underHarness) {
            root.configSaved(config);
            return;
        }
        if (root.configSaving) {
            root._queuedConfig = config;
            return;
        }
        root.configSaving = true;
        configSaveProc.sent = config;
        configSaveProc.command = root.agentBusCall("SetConfig", ["s", JSON.stringify(config)]);
        configSaveProc.running = true;
    }

    Process {
        id: configSaveProc
        property var sent: null
        stderr: StdioCollector {
            id: configSaveErrors
        }
        onExited: exitCode => {
            root.configSaving = false;
            if (exitCode === 0)
                root.configSaved(configSaveProc.sent);
            else
                root.configSaveFailed(configSaveProc.sent, root.busFailureText(configSaveErrors.text, Translation.tr("Could not save the card")));
            const next = root._queuedConfig;
            root._queuedConfig = null;
            if (next !== null)
                root.saveConfig(next);
        }
    }

    function headerText(): string {
        if (root.agentState === "connecting")
            return Translation.tr("Connecting to the server…");
        return Translation.tr("%1 of %2 online").arg(root.onlineCount).arg(root.memberCount);
    }

    property string _pending: ""

    function ingest(line: string): void {
        const text = line.trim();
        if (!text)
            return;
        root._pending = text;
        if (!flushTimer.running)
            flushTimer.start();
    }

    function flushPending(): void {
        const text = root._pending;
        root._pending = "";
        try {
            const snapshot = JSON.parse(text);
            if (!snapshot?.status)
                return;
            root.retryDelay = root.retryMin;
            root.snapshot = CardLayouts.shared(root.snapshot, snapshot);
            root.now = Date.now();
        } catch (e) {
            // A torn line keeps the last good snapshot
        }
    }

    // Several Changed signals can land back to back, one rebuild covers them all
    Timer {
        id: flushTimer
        interval: 250
        onTriggered: root.flushPending()
    }

    Process {
        running: true
        command: ["bash", "-c", "PATH=\"$HOME/.local/bin:$PATH\" command -v fresence >/dev/null"]
        onExited: exitCode => root.binaryFound = (exitCode === 0)
    }

    readonly property int retryMin: 2000
    readonly property int retryMax: 30000
    property int retryDelay: root.retryMin
    property bool wantRunning: false

    onShouldRunChanged: {
        restartTimer.stop();
        root.retryDelay = root.retryMin;
        root.wantRunning = root.shouldRun;
    }

    Timer {
        id: restartTimer
        interval: root.retryDelay
        onTriggered: root.wantRunning = true
    }

    // watch outlives a daemon restart on its own, so an exit means no daemon or a broken agent
    Process {
        id: watch
        running: root.shouldRun && root.wantRunning
        command: root.agentCommand(["watch"])
        stdout: SplitParser {
            onRead: line => root.ingest(line)
        }
        onExited: exitCode => {
            flushTimer.stop();
            root._pending = "";
            root.snapshot = null;
            root.watchExitCode = exitCode;
            root.wantRunning = false;
            if (root.shouldRun) {
                root.retryDelay = Math.min(root.retryMax, root.retryDelay * 2);
                restartTimer.restart();
            }
        }
    }
}
