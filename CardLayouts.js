.pragma library

const columns = 4;
const gap = 8;
const gridRows = {
    "row": 1,
    "detail": 4
};

// builtinSymbol in app/shared ui/card/Resolve.kt
const sourceSymbols = {
    "cpu": "memory",
    "memory": "memory_alt",
    "disk": "hard_drive",
    "load": "speed",
    "battery": "battery_full",
    "packages": "inventory_2",
    "window": "web_asset",
    "app": "apps",
    "workspace": "desktop_windows",
    "uptime": "schedule",
    "alarm": "alarm",
    "meeting": "event_busy"
};

// protocol.md: the first form of a type is its fallback
const formFiles = {
    "value": {
        "text": "TileText.qml",
        "number": "TileNumber.qml",
        "bar": "TileBar.qml",
        "ring": "TileRing.qml",
        "dial": "TileDial.qml",
        "figure": "TileFigure.qml",
        "cells": "TileCells.qml",
        "clock": "TileClock.qml",
        "timer": "TileTimer.qml"
    },
    "media": {
        "player": "TilePlayer.qml",
        "vinyl": "TileVinyl.qml"
    },
    "game": {
        "banner": "TileGame.qml",
        "hero": "TileGame.qml",
        "ring": "TileGame.qml",
        "cover": "TileGame.qml"
    },
    "weather": {
        "sky": "TileWeatherLive.qml",
        "temp": "TileWeather.qml",
        "moon": "TileMoon.qml",
        "sun": "TileSun.qml"
    },
    "chess": {
        "board": "TileChessBoard.qml",
        "rating": "TileChessRating.qml"
    },
    "photo": {},
    "clip": {},
    "image": {},
    "clock": {
        "clock": "TileZoneClock.qml",
        "day": "TileZoneClock.qml"
    }
};
const formlessFiles = {
    "photo": "TilePhoto.qml",
    "clip": "TileClip.qml",
    "image": "TileImage.qml"
};

const fullBleedTypes = ["game", "photo", "image", "clip"];
const mediaFiles = {
    "cover": "TileCover.qml",
    "poster": "TilePoster.qml",
    "player": "TilePlayer.qml",
    "strip": "TileWave.qml",
    "vinyl": "TileVinyl.qml",
    "sleeve": "TileSleeve.qml",
    "video": "TileVideo.qml"
};
const edgeToEdgeMediaFiles = [mediaFiles.cover, mediaFiles.player, mediaFiles.vinyl, mediaFiles.sleeve, mediaFiles.video];
const batteryTankFile = "TileBattery.qml";
const batteryTankPlaces = ["1x1", "2x1", "2x2", "4x1"];
const lowBatteryPercent = 20;

function takesBatteryTank(widget) {
    const place = widget?.place;
    return widget?.type === "value" && widget.source === "battery" && shownForm(widget) === "ring" && batteryTankPlaces.includes(`${place?.cols}x${place?.rows}`);
}

function isLowBattery(fill, charging) {
    return !charging && Math.round(fill * 100) <= lowBatteryPercent;
}

function formsOf(type) {
    return Object.keys(formFiles[type] ?? {});
}

// app/shared ui/card/Tiles.kt UnrecognizedTile: a type from a newer peer keeps its
// place as an update placeholder.
function knownType(type) {
    return type in formFiles;
}

// app/shared ui/card/Resolve.kt RetiredMediaForms
const retiredMediaForms = {
    "cover": "player",
    "poster": "player",
    "wave": "player",
    "sleeve": "vinyl"
};

// app/shared ui/card/Resolve.kt Widget.defaultForm: a tall clock keeps the day bar
const tallClockRows = 3;

function defaultForm(widget, forms) {
    return widget?.type === "clock" && widget.place?.rows >= tallClockRows ? "day" : (forms[0] ?? "");
}

// app/shared ui/card/Resolve.kt ValueShape: the forms a value can fill
const valueShapeForms = {
    "text": ["text", "number"],
    "fill": ["ring", "figure", "cells", "dial", "bar", "number"],
    "time": ["clock", "timer"]
};

function valueShape(value) {
    if (value?.time !== undefined && value?.time !== null)
        return "time";
    return value?.fill !== undefined && value?.fill !== null ? "fill" : "text";
}

// app/shared ui/editor/Labels.kt statusSymbol: the icon of a tile with that source, else the built-in one, else one by value shape
const shapeSymbols = {
    "text": "text_fields",
    "fill": "data_usage",
    "time": "timer"
};

function statusSymbol(widgets, id, shape) {
    return widgets.find(w => w.source === id && w.icon)?.icon ?? sourceSymbols[id] ?? shapeSymbols[shape];
}

// app/shared ui/card/Resolve.kt Widget.shownForm(value): a form the value cannot fill gives way to one it can
function shownValueForm(widget, value) {
    const form = shownForm(widget);
    if (widget?.type !== "value" || !value)
        return form;
    const forms = valueShapeForms[valueShape(value)];
    return form === "text" || forms.includes(form) ? form : forms[0];
}

function shownForm(widget) {
    const forms = formsOf(widget?.type);
    const form = widget?.type === "media" ? (retiredMediaForms[widget?.form] ?? widget?.form) : widget?.form;
    return forms.includes(form) ? form : defaultForm(widget, forms);
}

// app/shared ui/card/Resolve.kt Widget.shownShape: cookie/clover only draw their
// polygon on a square place, elsewhere they fall back to a circle. The chess board
// and a square player past 1x1 take no shape.
function takesShape(widget) {
    const form = shownForm(widget);
    if (widget?.type === "chess")
        return form !== "board";
    if (widget?.type === "media")
        return !(form === "player" && widget.place?.cols === widget.place?.rows && widget.place?.cols > 1);
    return true;
}

function shownShape(widget) {
    const shape = takesShape(widget) ? (widget?.shape ?? "rounded") : "rounded";
    if (shape === "cookie" || shape === "clover")
        return widget.place?.cols === widget.place?.rows ? shape : "circle";
    return shape === "circle" ? shape : "rounded";
}

// app/shared ui/card/Gauges.kt BuiltinFigures: figure draws only these sources
const figures = {
    "cpu": "chip",
    "memory": "stick",
    "disk": "drive",
    "battery": "battery"
};

function figureOf(source) {
    return figures[source] ?? "";
}

const stripMaxCols = 2;

// app/shared ui/card/YoutubeTile.kt: a video counts as YouTube by its player or its url
function isYoutube(media) {
    return media?.kind === "video" && [media.player, media.url].some(source => /youtube|youtu\.be\//i.test(source ?? ""));
}

// app/shared ui/card/MediaTiles.kt MusicForm and VinylForm: the place picks the layout
function mediaFile(widget, media) {
    const place = widget?.place ?? {};
    const square = place.rows >= place.cols;
    const tall = square && place.rows >= 2;
    if (shownForm(widget) === "vinyl")
        return tall ? mediaFiles.sleeve : mediaFiles.vinyl;
    if (isYoutube(media))
        return mediaFiles.video;
    if (square)
        return tall ? mediaFiles.poster : mediaFiles.cover;
    return place.cols <= stripMaxCols ? mediaFiles.strip : mediaFiles.player;
}

// app/shared ui/card/Tiles.kt ValueTile: a figure without a picture is drawn as a ring
function formFile(widget, value, media) {
    const form = shownValueForm(widget, value);
    if (widget?.type === "value" && form === "figure" && !figureOf(widget.source))
        return formFiles.value.ring;
    if (widget?.type === "media")
        return mediaFile(widget, media);
    if (takesBatteryTank(widget) && form === "ring")
        return batteryTankFile;
    return formFiles[widget?.type]?.[form] ?? formlessFiles[widget?.type] ?? "";
}

const bytesPerGiB = Math.pow(2, 30);
const bytesPerTiB = Math.pow(2, 40);
const wholeFromAmount = 10;

// app/shared ui/card/Gauges.kt amount: one decimal only below 10
function amount(bytes, scale) {
    const x = bytes / scale;
    if (x >= wholeFromAmount)
        return String(Math.round(x));
    const tenths = Math.round(x * 10);
    return tenths % 10 === 0 ? String(tenths / 10) : `${Math.floor(tenths / 10)}.${tenths % 10}`;
}

function hasBytes(value) {
    return value?.used_bytes !== undefined && value?.total_bytes !== undefined;
}

function bytesText(value) {
    if (!hasBytes(value))
        return "";
    const scale = value.total_bytes >= bytesPerTiB ? bytesPerTiB : bytesPerGiB;
    return `${amount(value.used_bytes, scale)} of ${amount(value.total_bytes, scale)} ${scale === bytesPerTiB ? "TB" : "GB"}`;
}

function compactBytesText(value) {
    if (value?.used_bytes === undefined)
        return "";
    const scale = value.used_bytes >= bytesPerTiB ? bytesPerTiB : bytesPerGiB;
    return `${amount(value.used_bytes, scale)} ${scale === bytesPerTiB ? "TB" : "GB"}`;
}

const insetBaseFraction = 0.14;
const insetMin = 10;
const insetMax = 16;
const insetMarginFraction = 0.2;
const roundedRadius = 16;
const fillAnimationMs = 600;
const fillEasing = [0.4, 0, 0.2, 1, 1, 1];
// Half-size of the largest centered square inside the cookie/clover polygons, from
// app/shared ui/card/Tiles.kt RoundedPolygon.contentHalfSide.
const cookieEdgeFraction = 0.1787;
const cloverEdgeFraction = 0.1113;

function arcInset(radius, margin) {
    return radius - (radius - margin) / Math.SQRT2;
}

// app/shared ui/card/Tiles.kt tileInset: keeps a form's text and icons clear of the
// tile's silhouette.
function tileInset(width, height, shape) {
    const side = Math.min(width, height);
    const base = Math.max(insetMin, Math.min(insetMax, side * insetBaseFraction));
    const margin = base * insetMarginFraction;
    let edge;
    switch (shape) {
    case "circle":
        edge = arcInset(side / 2, margin);
        break;
    case "cookie":
        edge = side * cookieEdgeFraction + margin;
        break;
    case "clover":
        edge = side * cloverEdgeFraction + margin;
        break;
    default:
        edge = arcInset(roundedRadius, margin);
    }
    return Math.max(base, edge);
}

// The chess board, rating and clock pad themselves, edge to edge like ChessTiles.kt and Clock.kt
function edgeToEdge(widget, media) {
    const file = formFile(widget, undefined, media);
    return widget?.type === "chess" || widget?.type === "clock" || edgeToEdgeMediaFiles.includes(file) || file === batteryTankFile;
}

function fullBleed(widget, media) {
    return fullBleedTypes.includes(widget?.type) || formFile(widget, undefined, media) === mediaFiles.poster;
}

// protocol.md: background is ignored by a widget that paints its own art or scene
function takesBackground(widget) {
    switch (widget?.type) {
    case "media":
        return shownForm(widget) === "vinyl" || widget.place?.cols !== widget.place?.rows;
    case "weather":
        return shownForm(widget) !== "sky";
    case "chess":
        return shownForm(widget) !== "board";
    case "value":
        return true;
    default:
        return false;
    }
}

function backgroundKind(widget) {
    return takesBackground(widget) ? (widget.background?.kind ?? "") : "";
}

// The url a music/game/url background shows, empty when the source has no picture; a
// photo background is a local file, not a url, see photoValid()
function backgroundUrl(widget, device) {
    const state = device?.state ?? null;
    switch (backgroundKind(widget)) {
    case "music":
        return state?.media?.art_url ?? "";
    case "game":
        return state?.game?.art?.hero ?? state?.game?.art?.header ?? state?.game?.art?.cover ?? "";
    case "url":
        return widget.background?.url ?? "";
    default:
        return "";
    }
}

// Material role in snake_case -> [fill, content on it], keys of Appearance.colors
const colorRoles = {
    "primary": ["colPrimary", "colOnPrimary"],
    "secondary": ["colSecondary", "colOnSecondary"],
    "tertiary": ["colTertiary", "colOnTertiary"],
    "error": ["colError", "colOnError"],
    "primary_container": ["colPrimaryContainer", "colOnPrimaryContainer"],
    "secondary_container": ["colSecondaryContainer", "colOnSecondaryContainer"],
    "tertiary_container": ["colTertiaryContainer", "colOnTertiaryContainer"],
    "error_container": ["colErrorContainer", "colOnErrorContainer"]
};
const noColorRole = ["colLayer2", "colOnLayer2"];

function colorKeysOf(role) {
    return colorRoles[role] ?? noColorRole;
}

function timeDirection(mode, atMs, nowMs) {
    if (isNaN(atMs))
        return "";
    if (mode === "until")
        return atMs > nowMs ? "until" : "";
    if (mode === "since")
        return atMs <= nowMs ? "since" : "";
    return atMs > nowMs ? "until" : "since";
}

// app/shared ui/time/Time.kt unitValues: days, hours, minutes and seconds of a span, leading zeros dropped but the seconds
function unitValues(spanMs) {
    const total = Math.floor(Math.abs(spanMs) / 1000);
    const all = [
        {
            "unit": "days",
            "value": Math.floor(total / 86400)
        },
        {
            "unit": "hours",
            "value": Math.floor(total / 3600) % 24
        },
        {
            "unit": "minutes",
            "value": Math.floor(total / 60) % 60
        },
        {
            "unit": "seconds",
            "value": total % 60
        }
    ];
    const lead = all.slice(0, -1).findIndex(c => c.value > 0);
    return all.slice(lead < 0 ? all.length - 1 : lead);
}

// app/shared ui/card/UnitCells.kt cellCapacity
function unitCellCapacity(cols, rows) {
    if (cols === 1)
        return 1;
    return cols === 2 && rows === 1 ? 2 : 4;
}

const weekdayReachDays = 6;

// app/shared ui/time/Local.kt dayMark: null for today, a weekday (0 is Sunday) within a week, else a date
function dayMark(atMs, nowMs) {
    const at = new Date(atMs);
    const now = new Date(nowMs);
    const days = Math.round((new Date(at.getFullYear(), at.getMonth(), at.getDate()) - new Date(now.getFullYear(), now.getMonth(), now.getDate())) / 86400000);
    if (days === 0)
        return null;
    if (Math.abs(days) <= weekdayReachDays)
        return {
            "weekday": at.getDay()
        };
    const two = n => String(n).padStart(2, "0");
    const date = `${two(at.getDate())}.${two(at.getMonth() + 1)}`;
    return {
        "date": at.getFullYear() === now.getFullYear() ? date : `${date}.${at.getFullYear()}`
    };
}

function valueOf(widget, state) {
    return widget?.source ? (state?.values?.[widget.source] ?? null) : null;
}

// app/shared ui/card/Resolve.kt Widget.media
function mediaOf(widget, state) {
    const media = state?.media ?? null;
    return media?.kind === "video" && shownForm(widget) === "vinyl" ? null : media;
}

function valueMissing(widget, value, nowMs) {
    if (!value)
        return true;
    if (value.time !== undefined)
        return timeDirection(widget.time_mode, Date.parse(value.time), nowMs) === "";
    return !value.text && value.fill === undefined;
}

function photoValid(device, nowMs) {
    const state = device?.state ?? null;
    return !!device?.photo_file && !!state?.photo && Date.parse(state.photo.expires_at) > nowMs;
}

function backgroundIsPhoto(widget, device, nowMs) {
    return backgroundKind(widget) === "photo" && photoValid(device, nowMs);
}

// A clip widget stays on the grid for its whole life even before the file is
// local: clipMetaValid gates the widget, clipFileValid additionally gates the
// background variant, which has no in-between "downloading" look of its own.
function clipMetaValid(device, nowMs) {
    const clip = device?.state?.clip ?? null;
    return !!clip && Date.parse(clip.expires_at) > nowMs;
}

function clipFileValid(device, nowMs) {
    return !!device?.clip_file && clipMetaValid(device, nowMs);
}

function backgroundIsClip(widget, device, nowMs) {
    return backgroundKind(widget) === "clip" && clipFileValid(device, nowMs);
}

function missing(widget, device, nowMs) {
    const state = device?.state ?? null;
    switch (widget?.type) {
    case "value":
        return valueMissing(widget, valueOf(widget, state), nowMs);
    case "media":
        return !mediaOf(widget, state);
    case "game":
        return !state?.game;
    case "weather":
        return shownForm(widget) !== "moon" && !state?.weather;
    case "chess":
        return shownForm(widget) === "board" ? !state?.chess?.last : !state?.chess;
    case "photo":
        return !photoValid(device, nowMs);
    case "clip":
        return !clipMetaValid(device, nowMs);
    case "image":
        return !widget.url;
    case "clock":
        return state?.utc_offset_s === undefined;
    default:
        return false;
    }
}

function fits(place, grid) {
    const rows = gridRows[grid] ?? 0;
    return !!place && place.col >= 0 && place.row >= 0 && place.cols >= 1 && place.rows >= 1 && place.col + place.cols <= columns && place.row + place.rows <= rows;
}

// Widgets slide up and left into holes left by hidden ones, the same way app/shared
// card/Grid.kt collapses them: only into cells some widget of the card covered.
function placed(widgets, grid, device, nowMs) {
    const shown = [];
    const room = [];
    for (const [index, widget] of (widgets ?? []).entries()) {
        if (!fits(widget?.place, grid))
            continue;
        room.push(widget.place);
        const absent = missing(widget, device, nowMs);
        if (absent && widget.on_missing !== "dim")
            continue;
        shown.push({
            "index": index,
            "widget": widget,
            "dimmed": absent,
            "col": widget.place.col,
            "row": widget.place.row,
            "cols": widget.place.cols,
            "rows": widget.place.rows
        });
    }
    let moved;
    do {
        moved = false;
        for (const p of shown.slice().sort((a, b) => a.row - b.row || a.col - b.col)) {
            while (true) {
                if (freeFor(shown, room, p, p.col, p.row - 1))
                    p.row--;
                else if (freeFor(shown, room, p, p.col - 1, p.row))
                    p.col--;
                else
                    break;
                moved = true;
            }
        }
    } while (moved);
    return shown;
}

// coversAll() in app/shared ui/card/Grid.kt
function covered(room, col, row, cols, rows) {
    for (let c = col; c < col + cols; c++) {
        for (let r = row; r < row + rows; r++) {
            if (!room.some(o => c >= o.col && c < o.col + o.cols && r >= o.row && r < o.row + o.rows))
                return false;
        }
    }
    return true;
}

function freeFor(shown, room, p, col, row) {
    return col >= 0 && row >= 0 && covered(room, col, row, p.cols, p.rows) && shown.every(o => o === p || col >= o.col + o.cols || o.col >= col + p.cols || row >= o.row + o.rows || o.row >= row + p.rows);
}

function rowsUsed(items) {
    return items.reduce((max, p) => Math.max(max, p.row + p.rows), 0);
}

function samePlaced(a, b) {
    return a.length === b.length && a.every((p, i) => p.widget === b[i].widget && p.dimmed === b[i].dimmed && p.col === b[i].col && p.row === b[i].row && p.cols === b[i].cols && p.rows === b[i].rows);
}

function shared(prev, next) {
    if (prev === next)
        return prev;
    if (typeof prev !== "object" || typeof next !== "object" || prev === null || next === null || Array.isArray(prev) !== Array.isArray(next))
        return next;
    const keys = Object.keys(next);
    const merged = Array.isArray(next) ? [] : {};
    let identical = keys.length === Object.keys(prev).length;
    for (const key of keys) {
        merged[key] = shared(prev[key], next[key]);
        identical = identical && key in prev && merged[key] === prev[key];
    }
    return identical ? prev : merged;
}

// picture path on disk -> isGif. A path keeps its content: the host empties the cover cache only
// at shell start, and its thumbnails are keyed by path the same way
const sniffedGifs = new Map();

// Spotify serves one cover from both hosts, and clients differ in which one they report
const spotifyArtHosts = /^https:\/\/(i\.scdn\.co|image-cdn\.spotifycdn\.com)\/image\//;

function artKey(url) {
    return url.replace(spotifyArtHosts, "https://i.scdn.co/image/");
}

function isHttpsUrl(url) {
    return typeof url === "string" && /^https:\/\/\S+$/.test(url);
}

function sameArray(a, b) {
    return a.length === b.length && a.every((v, i) => v === b[i]);
}

function mediaPositionMs(media, nowMs) {
    if (media?.position_ms === undefined)
        return -1;
    const at = Date.parse(media.position_at ?? "");
    const moved = media.playing && !isNaN(at) ? media.position_ms + Math.max(0, nowMs - at) : media.position_ms;
    return media.length_ms > 0 ? Math.min(moved, media.length_ms) : moved;
}

function mediaProgress(media, nowMs) {
    const position = mediaPositionMs(media, nowMs);
    return media?.length_ms > 0 && position >= 0 ? Math.min(1, position / media.length_ms) : -1;
}

// The schematic day skyClock draws sunrise at, regardless of its real clock time -
// only the elapsed time from sunrise/to sunset matters for the sun's arc.
const sunriseAtMin = 360;
const defaultSkyClock = {
    "sunriseMin": 390,
    "sunsetMin": 1170,
    "nowMin": 780
};

function wrapDay(min) {
    return ((min % 1440) + 1440) % 1440;
}

// Maps real sunrise/sunset/now onto that schematic day; falls back to a fixed
// midday when state.weather has no sunrise/sunset to place them by.
function skyClock(weather, nowMs) {
    const sunrise = Date.parse(weather?.sunrise ?? "");
    const sunset = Date.parse(weather?.sunset ?? "");
    if (isNaN(sunrise) || isNaN(sunset) || sunset <= sunrise)
        return defaultSkyClock;
    return {
        "sunriseMin": sunriseAtMin,
        "sunsetMin": sunriseAtMin + (sunset - sunrise) / 60000,
        "nowMin": wrapDay(sunriseAtMin + (nowMs - sunrise) / 60000)
    };
}

const knownNewMoonMs = Date.parse("2000-01-06T18:14:00Z");
const synodicMonthDays = 29.530588853;

function moonPhase(nowMs) {
    const lunations = (nowMs - knownNewMoonMs) / 86400000 / synodicMonthDays;
    const age = lunations - Math.floor(lunations);
    return {
        "illumination": (1 - Math.cos(2 * Math.PI * age)) / 2,
        "waxing": age < 0.5
    };
}

const dayMs = 86400000;

function nextAfter(dailyMs, nowMs) {
    return dailyMs + (Math.floor((nowMs - dailyMs) / dayMs) + 1) * dayMs;
}

function daylight(weather, nowMs) {
    const sunrise = Date.parse(weather?.sunrise ?? "");
    const sunset = Date.parse(weather?.sunset ?? "");
    if (isNaN(sunrise) || isNaN(sunset) || sunset <= sunrise)
        return null;
    const clock = skyClock(weather, nowMs);
    if (clock.nowMin >= clock.sunriseMin && clock.nowMin < clock.sunsetMin)
        return {
            "isDay": true,
            "progress": (clock.nowMin - clock.sunriseMin) / (clock.sunsetMin - clock.sunriseMin),
            "next": nextAfter(sunset, nowMs)
        };
    return {
        "isDay": false,
        "progress": 0,
        "next": nextAfter(sunrise, nowMs)
    };
}

// app/shared ui/time/Local.kt
const nightFromMin = 23 * 60;
const nightToMin = 7 * 60;
const minutesPerDay = 1440;
const lightInkLuminance = 0.5;

function minuteOfDayAt(utcOffsetS, nowMs) {
    return wrapDay(Math.floor((nowMs + utcOffsetS * 1000) / 60000));
}

function isNight(minute) {
    return minute >= nightFromMin || minute < nightToMin;
}

function nextPhaseChange(minute) {
    const night = isNight(minute);
    const left = (night ? nightToMin : nightFromMin) - minute;
    return {
        "morning": night,
        "afterMin": left <= 0 ? left + minutesPerDay : left
    };
}

function dayPartsAhead(minute) {
    const parts = [];
    for (let from = 0; from < minutesPerDay;) {
        const at = wrapDay(minute + from);
        const length = nextPhaseChange(at).afterMin;
        parts.push({
            "from": from,
            "to": Math.min(from + length, minutesPerDay),
            "night": isNight(at)
        });
        from += length;
    }
    return parts;
}

function hhmm(minute) {
    const m = wrapDay(minute);
    return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

function offsetGapMinutes(memberOffsetS, viewerOffsetS) {
    return Math.trunc((memberOffsetS - viewerOffsetS) / 60);
}

function signedHours(gapMinutes) {
    const sign = gapMinutes < 0 ? "-" : "+";
    const abs = Math.abs(gapMinutes);
    return abs % 60 === 0 ? `${sign}${abs / 60}` : `${sign}${Math.floor(abs / 60)}:${String(abs % 60).padStart(2, "0")}`;
}

function dayIndexAt(utcOffsetS, nowMs) {
    return Math.floor((nowMs + utcOffsetS * 1000) / 86400000);
}

// -1, 0 or 1: the member's date is behind, the same as, or ahead of the viewer's
function dayShift(nowMs, memberOffsetS, viewerOffsetS) {
    return Math.sign(dayIndexAt(memberOffsetS, nowMs) - dayIndexAt(viewerOffsetS, nowMs));
}

// 0 is Sunday, as Locale.dayName counts; 1970-01-01 was a Thursday
function weekdayAt(utcOffsetS, nowMs) {
    return (dayIndexAt(utcOffsetS, nowMs) + 4) % 7;
}

function shortSpanMinutes(minutes) {
    return minutes < 60 ? {
        "unit": "minutes",
        "n": Math.max(1, minutes)
    } : {
        "unit": "hours",
        "n": Math.floor(minutes / 60)
    };
}

function relativeLuminance(color) {
    const linear = c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
}

// A part of the day bar is drawn in the tile fill when it is dark on a light ink or light on a dark one
function dayPartStrong(part, ink) {
    return part.night !== (relativeLuminance(ink) > lightInkLuminance);
}

// app/shared ui/card/Clock.kt clockLayout: the form and the place pick the layout
function clockLayout(form, cols, rows) {
    if (cols <= 1)
        return "stacked";
    if (form === "day") {
        if (rows >= 3)
            return "tall";
        if (rows === 2)
            return cols >= 3 ? "sideBySide" : "dayCorner";
        return cols >= 4 ? "dayRowLong" : "dayRowShort";
    }
    if (rows >= 2)
        return cols >= 3 ? "big" : "corner";
    return cols >= 4 ? "rowLong" : "rowShort";
}

const boardSide = 8;

// Outlines in a 24x24 viewport, mirror Silhouettes in app/shared ui/card/ChessTiles.kt
const pieceBase = "M4.5 18h15v3h-15z";
const chessPieces = {
    "k": {
        "body": ["M10.75 1.5h2.5v2h2v2.5h-2v3h-2.5v-3h-2v-2.5h2z", "M6.5 8h11v2.5h-1.5l1.2 9h-10.4l1.2-9h-1.5z", pieceBase],
        "cuts": []
    },
    "q": {
        "body": ["M4 7.5l4.5 3.5 3.5-6 3.5 6 4.5-3.5-1.7 12h-12.6z", "M4 4.3a1.7 1.7 0 1 1 0 3.4a1.7 1.7 0 1 1 0-3.4z", "M12 1.6a1.7 1.7 0 1 1 0 3.4a1.7 1.7 0 1 1 0-3.4z", "M20 4.3a1.7 1.7 0 1 1 0 3.4a1.7 1.7 0 1 1 0-3.4z", pieceBase],
        "cuts": []
    },
    "r": {
        "body": ["M5.5 3.5h3v2.5h2v-2.5h3v2.5h2v-2.5h3v6h-2l0.6 10h-9.2l0.6-10h-2z", pieceBase],
        "cuts": []
    },
    "b": {
        "body": ["M12 2.5C16.2 5.5 17.5 8.2 17.5 10.5 17.5 13 15 14.5 12 14.5S6.5 13 6.5 10.5C6.5 8.2 7.8 5.5 12 2.5z", "M9.5 13h5l1.8 6.5h-8.6z", pieceBase],
        "cuts": ["M13.8 5.4l1.3 1.3-3.3 3.3-1.3-1.3z"]
    },
    "n": {
        "body": ["M18.2 19.5C18.8 12.5 18 7.5 13.8 4.3L13.25 2.7Q13 2 12.45 2.5L10.6 4.3C7.5 5.3 5.5 8.3 4.2 11.8 3.9 13.3 4.8 14.7 6.3 14.7 7.6 14.7 8.5 14.2 9.6 13.6C10 15.8 8.8 17.8 7.4 19.5Z", pieceBase],
        "cuts": ["M11.3 6.4a1 1 0 1 1 0 2a1 1 0 1 1 0-2z"]
    },
    "p": {
        "body": ["M12 3a3.8 3.8 0 1 1 0 7.6a3.8 3.8 0 1 1 0-7.6z", "M9 19.5l1.4-9.5h3.2l1.4 9.5z", "M5.5 18h13v3h-13z"],
        "cuts": []
    }
};

// Rows top to bottom, "" for an empty square; the player's own side is at the bottom
function boardSquares(fen, side) {
    const ranks = (fen ?? "").split(" ")[0].split("/").map(rank => rank.split("").reduce((squares, ch) => squares.concat(/\d/.test(ch) ? Array(Number(ch)).fill("") : [ch]), []));
    const last = boardSide - 1;
    return Array.from({
        "length": boardSide
    }, (_, row) => Array.from({
            "length": boardSide
        }, (_, col) => (side === "black" ? ranks[last - row]?.[last - col] : ranks[row]?.[col]) ?? ""));
}

const chessCorners = [
    {
        "top": true,
        "start": false
    },
    {
        "top": true,
        "start": true
    },
    {
        "top": false,
        "start": false
    },
    {
        "top": false,
        "start": true
    }
];

// The first corner whose cols x rows squares are all empty, null when there is none
function freeCorner(squares, cols, rows) {
    if (!(cols >= 1 && cols <= boardSide && rows >= 1 && rows <= boardSide))
        return null;
    return chessCorners.find(corner => {
        const from = corner.top ? 0 : boardSide - rows;
        const fromCol = corner.start ? 0 : boardSide - cols;
        for (let row = from; row < from + rows; row++)
            for (let col = fromCol; col < fromCol + cols; col++)
                if (squares[row]?.[col])
                    return false;
        return true;
    }) ?? null;
}

function deltaText(delta) {
    return delta > 0 ? `+${delta}` : `${delta}`;
}

const summaryDropOrder = ["opponent", "rating", "caption"];

// ChessTiles.kt keptParts: the parts of a game summary that fit next to the result line
function keptParts(heights, resultHeight, available) {
    const kept = Object.keys(heights).filter(part => heights[part] > 0);
    for (const part of summaryDropOrder) {
        if (kept.reduce((sum, p) => sum + heights[p], 0) + resultHeight > available && kept.includes(part))
            kept.splice(kept.indexOf(part), 1);
    }
    return kept;
}

const chartMinSpan = 240;
const chartFloor = 1;
const chartHeadroom = 0.6;
const bestMinSpan = 120;

// ChessTiles.kt RatingChart: y of each rating in a chart `height` tall, the best line at y = top
function chartYs(history, best, height, top) {
    const hiRating = Math.max(...history);
    const loRating = Math.min(...history);
    const visible = Math.max(hiRating - loRating, chartMinSpan);
    const middle = (hiRating + loRating) / 2;
    const hasBest = best !== undefined && best !== null;
    const hi = hasBest ? Math.max(best, hiRating) : middle + visible * chartHeadroom;
    const lo = hasBest ? Math.min(loRating, hi - bestMinSpan) : middle - visible * chartFloor;
    const from = hasBest ? top : 0;
    return history.map(v => from + (height - from) * (1 - (v - lo) / (hi - lo)));
}

// ChessTiles.kt monotoneSlopes: y change per step at each point, flat at turning points
function monotoneSlopes(values) {
    const secants = values.slice(1).map((v, i) => v - values[i]);
    return values.map((_, i) => {
        const before = secants[i - 1];
        const after = secants[i];
        if (before === undefined)
            return after ?? 0;
        if (after === undefined)
            return before;
        return before * after <= 0 ? 0 : 2 * before * after / (before + after);
    });
}
