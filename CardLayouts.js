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
        "weather": "TileWeather.qml",
        "weather_live": "TileWeatherLive.qml",
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

// Hidden widgets leave no empty rows behind, and in a row grid no empty columns either,
// the same way app/shared card/Grid.kt collapses them.
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
    const used = new Set();
    for (const p of shown)
        for (let r = p.row; r < p.row + p.rows; r++)
            used.add(r);
    for (const p of shown)
        p.row = [...used].filter(r => r < p.row).length;
    if (grid !== "row")
        return shown;
    let col = 0;
    return shown.slice().sort((a, b) => a.col - b.col).map(p => {
        p.col = col;
        col += p.cols;
        return p;
    });
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

// Weather value as a custom command prints it: temp;code;precip;wind;windDir;isDay;moonIllum;moonPhase;sunrise;sunset;now;city
const weatherCompactPattern = /^(-?\d+);(\d+);(\d+(?:\.\d+)?);(\d+(?:\.\d+)?);(\d+(?:\.\d+)?);([01]);(\d+);([^;]*);(\d+);(\d+);(\d+);(.*)$/;

function weatherFieldsOf(value) {
    const m = weatherCompactPattern.exec(String(value));
    if (!m)
        return null;
    return {
        "temp": parseInt(m[1], 10),
        "code": parseInt(m[2], 10),
        "precipMM": parseFloat(m[3]),
        "windKmph": parseFloat(m[4]),
        "windDirDeg": parseFloat(m[5]),
        "isDay": m[6] === "1",
        "moonIllum": parseInt(m[7], 10),
        "moonPhase": m[8],
        "sunriseMin": parseInt(m[9], 10),
        "sunsetMin": parseInt(m[10], 10),
        "nowMin": parseInt(m[11], 10),
        "city": m[12]
    };
}

// wttr.in's weatherCode -> condition, https://www.worldweatheronline.com/weather-api/api/docs/weather-icons.aspx
const weatherConditionByCode = {
    113: "clear",
    116: "clouds",
    119: "clouds",
    122: "clouds",
    143: "fog",
    176: "rain",
    179: "snow",
    182: "snow",
    185: "snow",
    200: "clouds",
    227: "snow",
    230: "snow",
    248: "fog",
    260: "fog",
    263: "rain",
    266: "rain",
    281: "rain",
    284: "rain",
    293: "rain",
    296: "rain",
    299: "rain",
    302: "rain",
    305: "rain",
    308: "rain",
    311: "rain",
    314: "rain",
    317: "snow",
    320: "snow",
    323: "snow",
    326: "snow",
    329: "snow",
    332: "snow",
    335: "snow",
    338: "snow",
    350: "snow",
    353: "rain",
    356: "rain",
    359: "rain",
    362: "snow",
    365: "snow",
    368: "snow",
    371: "snow",
    374: "snow",
    377: "snow",
    386: "thunder",
    389: "thunder",
    392: "thunder",
    395: "thunder"
};

const possiblePrecipCodes = new Set([176, 179, 182, 185]);

function weatherConditionOf(value) {
    const fields = weatherFieldsOf(value);
    if (!fields)
        return null;
    if (possiblePrecipCodes.has(fields.code) && !(fields.precipMM > 0))
        return "clouds";
    return weatherConditionByCode[fields.code] ?? null;
}
