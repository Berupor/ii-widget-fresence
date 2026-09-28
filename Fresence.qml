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
        return left < 3600000 ? Translation.tr("%1 min left").arg(Math.max(1, Math.floor(left / 60000))) : Translation.tr("%1 h left").arg(Math.floor(left / 3600000));
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

    // A hidden member still says something, picked by account id so it stays with the person
    readonly property var hiddenLines: [Translation.tr("off the radar"), Translation.tr("somewhere else"), Translation.tr("heads down"), Translation.tr("out of frame"), Translation.tr("keeping it quiet"), Translation.tr("doing something")]

    function hiddenLineFor(member): string {
        const id = member?.id ?? "";
        let sum = 0;
        for (let i = 0; i < id.length; i++)
            sum += id.charCodeAt(i);
        return root.hiddenLines[sum % root.hiddenLines.length];
    }

    // covered: what the row's visible tiles already show, so the line does not repeat it
    function statusFor(member, device, covered): string {
        const p = member?.presence;
        if (!p)
            return "";
        if (p.kind === "offline")
            return isNaN(p.seenAt) ? Translation.tr("Offline") : Translation.tr("Last seen %1").arg(root.agoText(p.seenAt));
        if (p.kind === "incognito") {
            const head = !isNaN(p.until) ? Translation.tr("Hidden until %1").arg(root.clockText(p.until)) : root.hiddenLineFor(member);
            return p.note ? `${head} · ${p.note}` : head;
        }
        const speaks = device && device.online && !root.incognitoOf(device) ? device : member.activeDevice;
        const skip = speaks === device ? (covered ?? new Set()) : new Set();
        const state = speaks?.state ?? {};
        if (state.game && !skip.has("game")) {
            const started = Date.parse(state.game.started_at);
            return isNaN(started) ? Translation.tr("Playing %1").arg(state.game.name) : Translation.tr("Playing %1 · %2").arg(state.game.name).arg(root.sessionText(started));
        }
        const media = state.media;
        if (media?.playing && !skip.has("media")) {
            if (media.kind === "video")
                return Translation.tr("Watching %1").arg(media.title);
            return media.artist ? Translation.tr("Listening to %1 - %2").arg(media.title).arg(media.artist) : Translation.tr("Listening to %1").arg(media.title);
        }
        for (const id of ["window", "app"]) {
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
            return root.online ? Translation.tr("Not in a room yet.\nPaste an invite from a friend") : Translation.tr("Connecting to the server…");
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

    function headerText(): string {
        if (root.agentState === "connecting")
            return Translation.tr("Connecting to the server…");
        return Translation.tr("%1 of %2 online").arg(root.onlineCount).arg(root.memberCount);
    }

    property var _pending: null

    function ingest(line: string): void {
        const text = line.trim();
        if (!text)
            return;
        try {
            const snapshot = JSON.parse(text);
            if (!snapshot?.status)
                return;
            root._pending = snapshot;
            root.retryDelay = root.retryMin;
            if (!flushTimer.running)
                flushTimer.start();
        } catch (e) {
            // A torn line keeps the last good snapshot
        }
    }

    // Several Changed signals can land back to back, one rebuild covers them all
    Timer {
        id: flushTimer
        interval: 250
        onTriggered: {
            if (root._pending === null)
                return;
            root.snapshot = root._pending;
            root._pending = null;
            root.now = Date.now();
        }
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
            root._pending = null;
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
