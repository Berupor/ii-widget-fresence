.pragma library
.import "CardLayouts.js" as CardLayouts

// The editing rules of app/shared ui/editor/Choices.kt, Draft.kt and ui/card/Grid.kt, kept in step with them

const builtinSources = ["cpu", "memory", "disk", "load", "battery", "packages", "window", "app", "workspace", "uptime"];

const builtinShapes = {
    "cpu": "fill",
    "memory": "fill",
    "disk": "fill",
    "battery": "fill",
    "load": "text",
    "packages": "text",
    "window": "text",
    "app": "text",
    "workspace": "text",
    "uptime": "time",
    "alarm": "time",
    "meeting": "time"
};

const sourceForms = {
    "weather": ["weather_live", "weather"],
    "moon": ["moon"],
    "sun": ["sun"]
};

const textForms = ["text", "big", "number", "banner"];

const shapeForms = {
    "text": textForms,
    "fill": ["ring", "dial", "bar", ...textForms],
    "time": ["clock", "timer"]
};

const otherTypes = ["media", "game", "photo", "image"];

const colors = ["primary", "secondary", "tertiary", "error", "primary_container", "secondary_container", "tertiary_container", "error_container"];

const newValueKinds = ["text", "fill", "time", "command"];
const defaultFill = 0.5;
const defaultCommandIntervalS = 60;
const saveDebounceMs = 700;

const imageUrlPattern = /^https:\/\/\S+$/;
const valueIdPattern = /^[a-z][a-z0-9_]*$/;
const symbolNamePattern = /^[a-z0-9_]{1,64}$/;
const maxNameLength = 64;

// English display strings for editor Choices.kt/Labels.kt ids, translated where used
const sourceNames = {
    "cpu": "CPU",
    "memory": "Memory",
    "disk": "Disk",
    "load": "Load",
    "battery": "Battery",
    "packages": "Package updates",
    "window": "Active window",
    "app": "App",
    "workspace": "Workspace",
    "uptime": "Uptime",
    "alarm": "Alarm",
    "meeting": "Meeting"
};

const sourceSymbols = {
    "cpu": "developer_board",
    "memory": "memory",
    "disk": "storage",
    "load": "speed",
    "battery": "battery_full",
    "packages": "inventory_2",
    "window": "web_asset",
    "app": "apps",
    "workspace": "desktop_windows",
    "uptime": "schedule",
    "alarm": "alarm",
    "meeting": "event_busy",
    "weather": "partly_cloudy_day",
    "moon": "bedtime",
    "sun": "wb_sunny"
};

const shapeSymbols = {
    "text": "text_fields",
    "fill": "data_usage",
    "time": "timer"
};

const typeNames = {
    "value": "Value",
    "media": "Music and video",
    "game": "Game",
    "photo": "Photo",
    "image": "Image"
};

const typeSymbols = {
    "value": "data_usage",
    "media": "music_note",
    "game": "sports_esports",
    "photo": "photo_camera",
    "image": "image"
};

const formNames = {
    "ring": "Ring",
    "dial": "Dial",
    "bar": "Bar",
    "number": "Number",
    "text": "Text",
    "big": "Large",
    "clock": "Clock",
    "banner": "Banner",
    "weather": "Weather",
    "weather_live": "Live weather",
    "moon": "Moon",
    "sun": "Sun",
    "cover": "Cover",
    "vinyl": "Vinyl",
    "wave": "Wave",
    "player": "Player",
    "timer": "Timer"
};

const valueKindNames = {
    "text": "Text",
    "fill": "Gauge",
    "time": "Time",
    "command": "Command"
};

const popularIcons = ["planner_review", "memory", "storage", "speed", "battery_full", "schedule", "alarm", "event_busy", "web_asset", "apps", "terminal", "code", "desktop_windows", "inventory_2", "music_note", "sports_esports", "mood", "location_on", "favorite", "bolt", "coffee", "work", "home", "bedtime"];

function sourceSymbol(id, shape) {
    return sourceSymbols[id] ?? shapeSymbols[shape] ?? "text_fields";
}

function widgetSymbol(widget, shape) {
    return widget.type === "value" && widget.source && shape ? sourceSymbol(widget.source, shape) : (typeSymbols[widget.type] ?? "widgets");
}

// A device value as the data sheet's live preview line, or null for nothing to show
function previewValueText(value) {
    if (value?.time !== undefined)
        return {
            "kind": "time",
            "at": Date.parse(value.time)
        };
    if (value?.text)
        return {
            "kind": "text",
            "text": value.text
        };
    if (value?.fill !== undefined)
        return {
            "kind": "fill",
            "percent": Math.round(value.fill * 100)
        };
    return null;
}

function hasOwnForms(source) {
    return source in sourceForms;
}

function shapeOfValue(value) {
    if (value?.time !== undefined)
        return "time";
    return value?.fill !== undefined ? "fill" : "text";
}

function shapeOf(config, source, state) {
    if (!source)
        return "fill";
    const own = config?.values?.[source]?.value;
    if (own)
        return shapeOfValue(own);
    if (builtinShapes[source])
        return builtinShapes[source];
    const live = state?.values?.[source];
    return live ? shapeOfValue(live) : "fill";
}

function formsOffered(config, type, source, state) {
    if (type === "value")
        return sourceForms[source] ?? shapeForms[shapeOf(config, source, state)];
    return CardLayouts.formsOf(type);
}

function size(cols, rows) {
    return {
        "cols": cols,
        "rows": rows
    };
}

function preferredSizes(form) {
    switch (form) {
    case "ring":
    case "dial":
    case "number":
    case "moon":
    case "sun":
    case "weather":
        return [size(1, 1)];
    case "text":
    case "big":
    case "clock":
        return [size(1, 1), size(2, 1)];
    case "bar":
    case "timer":
    case "wave":
        return [size(2, 1)];
    case "banner":
    case "player":
        return [size(2, 1), size(4, 1)];
    case "weather_live":
        return [size(2, 1), size(4, 2)];
    case "cover":
    case "vinyl":
        return [size(1, 1), size(2, 2)];
    default:
        return [size(1, 1), size(2, 1), size(2, 2)];
    }
}

const preferredNewSizes = [size(2, 1), size(1, 1)];

function sameSize(a, b) {
    return a.cols === b.cols && a.rows === b.rows;
}

function distinctSizes(sizes) {
    return sizes.filter((s, i) => sizes.findIndex(t => sameSize(s, t)) === i);
}

function rowsOf(grid) {
    return CardLayouts.gridRows[grid];
}

function overlaps(a, b) {
    return a.col < b.col + b.cols && b.col < a.col + a.cols && a.row < b.row + b.rows && b.row < a.row + a.rows;
}

function covers(place, col, row) {
    return col >= place.col && col < place.col + place.cols && row >= place.row && row < place.row + place.rows;
}

function canPlace(widgets, place, grid, ignoring) {
    return CardLayouts.fits(place, grid) && !widgets.some((w, i) => i !== ignoring && overlaps(w.place, place));
}

function isFree(widgets, col, row) {
    return !widgets.some(w => covers(w.place, col, row));
}

function firstFree(widgets, wanted, grid) {
    for (let row = 0; row <= rowsOf(grid) - wanted.rows; row++)
        for (let col = 0; col <= CardLayouts.columns - wanted.cols; col++) {
            const place = {
                "col": col,
                "row": row,
                "cols": wanted.cols,
                "rows": wanted.rows
            };
            if (canPlace(widgets, place, grid))
                return place;
        }
    return null;
}

function replaced(widgets, index, place) {
    return widgets.map((w, i) => i === index ? Object.assign({}, w, {
                "place": place
            }) : w);
}

function moved(widgets, index, col, row, grid) {
    const place = Object.assign({}, widgets[index].place, {
        "col": col,
        "row": row
    });
    return canPlace(widgets, place, grid, index) ? replaced(widgets, index, place) : null;
}

function resized(widgets, index, wanted, grid) {
    const place = Object.assign({}, widgets[index].place, wanted);
    return canPlace(widgets, place, grid, index) ? replaced(widgets, index, place) : null;
}

function allSizes(grid) {
    const sizes = [];
    for (let rows = 1; rows <= rowsOf(grid); rows++)
        for (let cols = 1; cols <= CardLayouts.columns; cols++)
            sizes.push(size(cols, rows));
    return sizes;
}

function sizesFor(widgets, index, grid) {
    return allSizes(grid).filter(s => resized(widgets, index, s, grid) !== null);
}

// at: [col, row] of the cell the new widget starts in, or null for the first free place
function added(widgets, widget, grid, at, sizes) {
    for (const s of distinctSizes((sizes ?? []).concat(preferredNewSizes))) {
        const place = at ? {
            "col": at[0],
            "row": at[1],
            "cols": s.cols,
            "rows": s.rows
        } : firstFree(widgets, s, grid);
        if (place && canPlace(widgets, place, grid))
            return widgets.concat([Object.assign({}, widget, {
                    "place": place
                })]);
    }
    return null;
}

function removed(widgets, index) {
    return widgets.filter((_, i) => i !== index);
}

// A click on the resize corner steps through the form's sizes, or every size when the form has one
function nextSize(widgets, index, grid) {
    const widget = widgets[index];
    const current = size(widget.place.cols, widget.place.rows);
    const preferred = distinctSizes(preferredSizes(shownFormOf(widget)).filter(s => resized(widgets, index, s, grid) !== null).concat([current]));
    const sizes = preferred.length > 1 ? preferred : sizesFor(widgets, index, grid);
    const at = sizes.findIndex(s => sameSize(s, current));
    return resized(widgets, index, sizes[(at + 1) % sizes.length], grid);
}

function draggedPlace(place, drag, dxCells, dyCells) {
    const dc = Math.round(dxCells);
    const dr = Math.round(dyCells);
    if (drag === "move")
        return Object.assign({}, place, {
            "col": place.col + dc,
            "row": place.row + dr
        });
    return Object.assign({}, place, {
        "cols": Math.max(1, place.cols + dc),
        "rows": Math.max(1, place.rows + dr)
    });
}

function clamp(n, lo, hi) {
    return Math.max(lo, Math.min(hi, n));
}

function fittedInto(widgets, grid) {
    const rows = rowsOf(grid);
    const kept = [];
    for (const w of widgets) {
        const p = w.place;
        if (!(p.col >= 0 && p.col < CardLayouts.columns && p.row >= 0 && p.row < rows))
            continue;
        const place = {
            "col": p.col,
            "row": p.row,
            "cols": clamp(p.cols, 1, CardLayouts.columns - p.col),
            "rows": clamp(p.rows, 1, rows - p.row)
        };
        if (canPlace(kept, place, grid))
            kept.push(Object.assign({}, w, {
                "place": place
            }));
    }
    return kept;
}

function fitted(config) {
    const next = Object.assign({}, config);
    if (config.row)
        next.row = fittedInto(config.row, "row");
    if (config.detail)
        next.detail = fittedInto(config.detail, "detail");
    return next;
}

function canonicalJson(value) {
    if (Array.isArray(value))
        return `[${value.map(canonicalJson).join(",")}]`;
    if (value !== null && typeof value === "object")
        return `{${Object.keys(value).sort().map(k => `${JSON.stringify(k)}:${canonicalJson(value[k])}`).join(",")}}`;
    return JSON.stringify(value);
}

function sameConfig(a, b) {
    return canonicalJson(a) === canonicalJson(b);
}

function widgetsOf(config, grid) {
    return config?.[grid] ?? [];
}

function withWidgets(config, grid, widgets) {
    return Object.assign({}, config, {
        [grid]: widgets
    });
}

function shownFormOf(widget) {
    return CardLayouts.shownForm(widget) || null;
}

// A key set to null or "" leaves the widget, the schema has no nulls
function withFields(widget, fields) {
    const next = Object.assign({}, widget, fields);
    for (const key of Object.keys(next))
        if (next[key] === null || next[key] === undefined || next[key] === "")
            delete next[key];
    return next;
}

function variants(config, widgets, index, grid, state) {
    const widget = widgets[index];
    const offered = formsOffered(config, widget.type, widget.source, state);
    const forms = offered.length > 0 ? offered : [null];
    const fitting = [];
    for (const form of forms)
        for (const s of preferredSizes(form))
            if (resized(widgets, index, s, grid) !== null)
                fitting.push({
                    "form": form,
                    "size": s
                });
    const current = {
        "form": shownFormOf(widget),
        "size": size(widget.place.cols, widget.place.rows)
    };
    const listed = fitting.some(v => v.form === current.form && sameSize(v.size, current.size));
    return listed || !forms.includes(current.form) ? fitting : [current].concat(fitting);
}

function newWidget(config, type, source, state, label) {
    return withFields({
        "type": type,
        "place": {
            "col": 0,
            "row": 0,
            "cols": 1,
            "rows": 1
        }
    }, {
        "source": type === "value" ? source : null,
        "form": formsOffered(config, type, source, state)[0] ?? null,
        "label": label ?? null
    });
}

function withData(config, widget, type, source, state, label) {
    const forms = formsOffered(config, type, source, state);
    const kept = shownFormOf(widget);
    return withFields(newWidget(config, type, source, state, label), {
        "place": widget.place,
        "form": forms.includes(kept) ? kept : (forms[0] ?? null),
        "icon": widget.icon ?? null,
        "color": widget.color ?? null,
        "on_missing": widget.on_missing ?? null
    });
}

function valueName(config, id) {
    const all = widgetsOf(config, "row").concat(widgetsOf(config, "detail"));
    return all.find(w => w.source === id && (w.label ?? "").trim() !== "")?.label ?? "";
}

function sources(config) {
    return [...new Set(builtinSources.concat(Object.keys(config?.values ?? {})))];
}

function withValue(config, id, source) {
    const values = Object.assign({}, config.values ?? {});
    if (source)
        values[id] = source;
    else
        delete values[id];
    return Object.assign({}, config, {
        "values": values
    });
}

// The QML regex engine has no \p{L}, a cased character stands in for a letter
function isLetterOrDigit(c) {
    return c.toLowerCase() !== c.toUpperCase() || /[0-9]/.test(c);
}

function newValueSource(kind, rawName, nowMs) {
    const name = rawName.trim();
    switch (kind) {
    case "fill":
        return {
            "value": {
                "text": name,
                "fill": defaultFill
            }
        };
    case "time":
        return {
            "value": {
                "time": new Date(nowMs + 3600000).toISOString()
            }
        };
    case "command":
        return {
            "command": `echo '{"text": "${[...name].filter(c => c === " " || isLetterOrDigit(c)).join("")}"}'`,
            "interval_s": defaultCommandIntervalS
        };
    default:
        return {
            "value": {
                "text": name
            }
        };
    }
}

const translit = {
    "а": "a",
    "б": "b",
    "в": "v",
    "г": "g",
    "д": "d",
    "е": "e",
    "ж": "zh",
    "з": "z",
    "и": "i",
    "й": "y",
    "к": "k",
    "л": "l",
    "м": "m",
    "н": "n",
    "о": "o",
    "п": "p",
    "р": "r",
    "с": "s",
    "т": "t",
    "у": "u",
    "ф": "f",
    "х": "h",
    "ц": "ts",
    "ч": "ch",
    "ш": "sh",
    "щ": "sch",
    "ъ": "",
    "ы": "y",
    "ь": "",
    "э": "e",
    "ю": "yu",
    "я": "ya"
};

const fallbackValueId = "value";

function valueIdFor(name, taken) {
    const latin = [...name.toLowerCase()].map(c => translit[c] ?? c).join("");
    const slug = latin.replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
    const base = slug === "" ? fallbackValueId : /^[a-z]/.test(slug) ? slug : `${fallbackValueId}_${slug}`;
    for (let n = 1;; n++) {
        const id = n === 1 ? base : `${base}_${n}`;
        if (!taken.includes(id))
            return id;
    }
}

function isValidValue(value) {
    if (value.time !== undefined)
        return value.text === undefined && value.fill === undefined;
    return !!value.text;
}

// Problem codes, the order they are listed in
const problemCodes = ["value_source", "image_url", "name_length", "value_id", "value_empty", "command"];

function problems(config) {
    const found = new Set();
    const names = [config.account_name, config.device_name].filter(n => n !== undefined);
    if (names.some(n => n.length === 0 || n.length > maxNameLength))
        found.add("name_length");
    for (const w of widgetsOf(config, "row").concat(widgetsOf(config, "detail"))) {
        if (w.type === "value" && !w.source)
            found.add("value_source");
        if (w.type === "image" && !imageUrlPattern.test(w.url ?? ""))
            found.add("image_url");
    }
    for (const [id, source] of Object.entries(config.values ?? {})) {
        if (!valueIdPattern.test(id))
            found.add("value_id");
        if (source.command !== undefined) {
            if (!(source.interval_s >= 1) || source.value !== undefined)
                found.add("command");
        } else if (!source.value || !isValidValue(source.value)) {
            found.add("value_empty");
        }
    }
    return problemCodes.filter(p => found.has(p));
}

function sampleValues(nowMs) {
    const at = ms => new Date(nowMs + ms).toISOString();
    const dayMinute = Math.floor(nowMs / 60000) % 1440;
    return {
        "window": {
            "text": "Fresence - App.kt"
        },
        "cpu": {
            "text": "23%",
            "fill": 0.23
        },
        "memory": {
            "text": "61%",
            "fill": 0.61
        },
        "uptime": {
            "time": at(-(5 * 60 + 12) * 60000)
        },
        "meeting": {
            "time": at(40 * 60000)
        },
        "weather": {
            "text": `12;116;0.0;14;220;1;63;Waxing Gibbous;402;1170;${dayMinute};London`
        },
        "status": {
            "text": "writing code"
        },
        "disk": {
            "text": "48%",
            "fill": 0.48
        },
        "load": {
            "text": "0.42"
        },
        "battery": {
            "text": "81%",
            "fill": 0.81
        },
        "packages": {
            "text": "14"
        },
        "app": {
            "text": "Telegram"
        },
        "workspace": {
            "text": "2 · code"
        },
        "alarm": {
            "time": at(7 * 3600000)
        }
    };
}

function placeholderValue(shape, nowMs) {
    switch (shape) {
    case "text":
        return {
            "text": "42"
        };
    case "time":
        return {
            "time": new Date(nowMs - 3600000).toISOString()
        };
    default:
        return {
            "text": "42%",
            "fill": 0.42
        };
    }
}

// What the editor's tiles draw: the device's own state, with made-up data where it has none yet
function preview(config, state, nowMs) {
    const real = state ?? {};
    const sample = sampleValues(nowMs);
    const values = {};
    for (const w of widgetsOf(config, "row").concat(widgetsOf(config, "detail")))
        if (w.source)
            values[w.source] = config.values?.[w.source]?.value ?? sample[w.source] ?? placeholderValue(shapeOf(config, w.source, state), nowMs);
    return Object.assign({}, real, {
        "media": real.media ?? {
            "kind": "music",
            "playing": true,
            "title": "Midnight City",
            "artist": "M83",
            "album": "Hurry Up, We're Dreaming",
            "length_ms": 243000,
            "position_ms": 81000,
            "position_at": new Date(nowMs).toISOString(),
            "player": "spotify"
        },
        "game": real.game ?? {
            "name": "Hades II",
            "source": "steam",
            "id": "1145350",
            "started_at": new Date(nowMs - 67 * 60000).toISOString()
        },
        "values": Object.assign(values, real.values ?? {})
    });
}
