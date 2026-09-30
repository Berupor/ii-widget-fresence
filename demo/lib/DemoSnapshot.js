.pragma library

// Snapshots by protocol/schema/snapshot.json for the scenes, times relative to a
// pinned local moment that the scenes also give Fresence.frozenAt, so clocks,
// "last seen", timers and media positions read the same on every run.

const now = Date.parse("2026-09-30T12:00:00");
const selfAccount = "acc-self";
const selfDevice = "dev-self";

function iso(offsetMs) {
    return new Date(now + offsetMs).toISOString();
}

function minutes(n) {
    return n * 60000;
}

function clockText(atMs) {
    const at = new Date(atMs);
    const time = Qt.formatTime(at, "HH:mm");
    return at.toDateString() === new Date(now).toDateString() ? time : `${Qt.formatDate(at, "dd.MM")} ${time}`;
}

function widget(type, place, extra) {
    return Object.assign({
        "type": type,
        "place": {
            "col": place[0],
            "row": place[1],
            "cols": place[2],
            "rows": place[3]
        }
    }, extra ?? {});
}

function value(source, place, extra) {
    return widget("value", place, Object.assign({
        "source": source
    }, extra ?? {}));
}

// d: { id, account, name, kind, online, seenAgo (ms), row, detail, status, state, photo }
function device(d) {
    const online = d.online !== false;
    const out = {
        "device_id": d.id,
        "online": online,
        "seen_at": iso(-(d.seenAgo ?? (online ? 5000 : minutes(42))))
    };
    if (d.card !== false)
        out.card = {
            "account_name": d.account,
            "device_name": d.name ?? "tower",
            "device_kind": d.kind ?? "desktop",
            "device_list_version": 1,
            "room_heads": {},
            "row": d.row ?? [],
            "detail": d.detail ?? []
        };
    if (d.status)
        out.card.status = d.status;
    if (d.state)
        out.state = d.state;
    if (d.photo)
        out.photo_file = d.photo;
    return out;
}

function member(accountId, devices, role) {
    return {
        "account_id": accountId,
        "role": role ?? "member",
        "devices": devices
    };
}

function room(roomId, members) {
    return {
        "room_id": roomId,
        "members": members
    };
}

// The own member is listed in the room without card/state, the account carries them
function snapshot(selfDevices, rooms, state) {
    const bare = selfDevices.map(d => ({
                "device_id": d.device_id,
                "online": d.online
            }));
    return {
        "status": {
            "state": state ?? "online",
            "version": "demo"
        },
        "account": {
            "account_id": selfAccount,
            "device_id": selfDevices[0]?.device_id ?? selfDevice,
            "server": "https://fresence.invalid",
            "devices": selfDevices
        },
        "rooms": rooms.map(r => room(r.room_id, [member(selfAccount, bare, "admin")].concat(r.members)))
    };
}

function playing(title, artist, artUrl, positionMs, lengthMs, extra) {
    return Object.assign({
        "kind": "music",
        "playing": true,
        "title": title,
        "artist": artist,
        "art_url": artUrl,
        "position_ms": positionMs,
        "position_at": iso(0),
        "length_ms": lengthMs
    }, extra ?? {});
}

function game(name, startedAgoMs, art) {
    return {
        "name": name,
        "source": "steam",
        "started_at": iso(-startedAgoMs),
        "art": art ?? {}
    };
}

function weather(place, tempC, condition, extra) {
    return Object.assign({
        "place": place,
        "temp_c": tempC,
        "condition": condition
    }, extra ?? {});
}

// game: { fen, color, result, ending, opponent, opponent_rating, moves, delta }
function chess(mode, rating, history, extra) {
    return Object.assign({
        "user": "gil_plays",
        "mode": mode,
        "rating": rating,
        "history": history
    }, extra ?? {});
}

function chessGame(fen, color, result, extra) {
    return Object.assign({
        "fen": fen,
        "color": color,
        "result": result,
        "ended_at": iso(-minutes(90))
    }, extra ?? {});
}
