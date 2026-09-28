.pragma library

const columns = 4;
const gap = 8;
const gridRows = {
    "row": 1,
    "detail": 4
};

// protocol.md: the first form of a type is its fallback
const formFiles = {
    "value": {
        "text": "TileText.qml",
        "number": "TileNumber.qml",
        "big": "TileBig.qml",
        "bar": "TileBar.qml",
        "ring": "TileRing.qml",
        "dial": "TileDial.qml",
        "banner": "TileBanner.qml",
        "clock": "TileClock.qml",
        "timer": "TileTimer.qml",
        "moon": "TileMoon.qml",
        "sun": "TileSun.qml"
    },
    "media": {
        "cover": "TileCover.qml",
        "player": "TilePlayer.qml",
        "vinyl": "TileVinyl.qml",
        "wave": "TileWave.qml"
    },
    "game": {
        "banner": "TileGame.qml",
        "cover": "TileGame.qml"
    },
    "weather": {
        "sky": "TileWeatherLive.qml",
        "temp": "TileWeather.qml"
    },
    "photo": {},
    "image": {}
};
const formlessFiles = {
    "photo": "TilePhoto.qml",
    "image": "TileImage.qml"
};

const fullBleedTypes = ["game", "photo", "image"];

function formsOf(type) {
    return Object.keys(formFiles[type] ?? {});
}

function shownForm(widget) {
    const forms = formsOf(widget?.type);
    return forms.includes(widget?.form) ? widget.form : (forms[0] ?? "");
}

function formFile(widget) {
    return formFiles[widget?.type]?.[shownForm(widget)] ?? formlessFiles[widget?.type] ?? "";
}

function fullBleed(widget) {
    return fullBleedTypes.includes(widget?.type);
}

// protocol.md: background is ignored by a widget that paints its own art or scene
function takesBackground(widget) {
    switch (widget?.type) {
    case "media":
        return shownForm(widget) !== "cover";
    case "weather":
        return shownForm(widget) === "temp";
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

function valueOf(widget, state) {
    return widget?.source ? (state?.values?.[widget.source] ?? null) : null;
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

function missing(widget, device, nowMs) {
    const state = device?.state ?? null;
    switch (widget?.type) {
    case "value":
        return valueMissing(widget, valueOf(widget, state), nowMs);
    case "media":
        return !state?.media;
    case "game":
        return !state?.game;
    case "weather":
        return !state?.weather;
    case "photo":
        return !photoValid(device, nowMs);
    case "image":
        return !widget.url;
    default:
        return true;
    }
}

function fits(place, grid) {
    const rows = gridRows[grid] ?? 0;
    return !!place && place.col >= 0 && place.row >= 0 && place.cols >= 1 && place.rows >= 1 && place.col + place.cols <= columns && place.row + place.rows <= rows;
}

// Widgets slide up and left into holes left by hidden ones, the same way app/shared
// card/Grid.kt collapses them.
function placed(widgets, grid, device, nowMs) {
    const shown = [];
    for (const widget of (widgets ?? [])) {
        if (!fits(widget?.place, grid))
            continue;
        const absent = missing(widget, device, nowMs);
        if (absent && widget.on_missing !== "dim")
            continue;
        shown.push({
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
                if (freeFor(shown, p, p.col, p.row - 1))
                    p.row--;
                else if (freeFor(shown, p, p.col - 1, p.row))
                    p.col--;
                else
                    break;
                moved = true;
            }
        }
    } while (moved);
    return shown;
}

function freeFor(shown, p, col, row) {
    return col >= 0 && row >= 0 && shown.every(o => o === p || col >= o.col + o.cols || o.col >= col + p.cols || row >= o.row + o.rows || o.row >= row + p.rows);
}

function rowsUsed(items) {
    return items.reduce((max, p) => Math.max(max, p.row + p.rows), 0);
}

function samePlaced(a, b) {
    return a.length === b.length && a.every((p, i) => p.widget === b[i].widget && p.dimmed === b[i].dimmed && p.col === b[i].col && p.row === b[i].row && p.cols === b[i].cols && p.rows === b[i].rows);
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
