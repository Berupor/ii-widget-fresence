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

const textForms = ["text", "big", "number", "banner"];

const shapeForms = {
    "text": textForms,
    "fill": ["ring", "figure", "cells", "dial", "bar", ...textForms],
    "time": ["clock", "timer"]
};

const chessTypes = ["chess"];
const otherTypes = ["media", "game", "weather", "clock", "photo", "image"].concat(chessTypes);

const colors = ["primary", "secondary", "tertiary", "error", "primary_container", "secondary_container", "tertiary_container", "error_container"];

const newValueKinds = ["text", "fill", "time", "command"];
const defaultFill = 0.5;
const defaultCommandIntervalS = 60;
const saveDebounceMs = 700;
const chessCheckDebounceMs = 500;

const imageUrlPattern = /^https:\/\/\S+$/;
const valueIdPattern = /^[a-z][a-z0-9_]*$/;
const chessUserPattern = /^[A-Za-z0-9_-]{3,25}$/;
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

const shapeSymbols = {
    "text": "text_fields",
    "fill": "data_usage",
    "time": "timer"
};

const typeNames = {
    "value": "Value",
    "media": "Music and video",
    "game": "Game",
    "weather": "Weather",
    "chess": "Chess",
    "clock": "Clock",
    "photo": "Photo",
    "image": "Image"
};

const typeSymbols = {
    "value": "data_usage",
    "media": "music_note",
    "game": "sports_esports",
    "weather": "partly_cloudy_day",
    "chess": "chess_queen",
    "clock": "schedule",
    "photo": "photo_camera",
    "image": "image"
};

const backgroundKinds = ["music", "game", "photo", "url"];

const backgroundNames = {
    "": "Color",
    "music": "Music",
    "game": "Game",
    "photo": "Photo",
    "url": "Link"
};

const backgroundSymbols = {
    "": "palette",
    "music": "music_note",
    "game": "sports_esports",
    "photo": "photo_camera",
    "url": "link"
};

const formNames = {
    "ring": "Ring",
    "dial": "Dial",
    "figure": "Figure",
    "cells": "Cells",
    "bar": "Bar",
    "number": "Number",
    "text": "Text",
    "big": "Large",
    "clock": "Clock",
    "banner": "Banner",
    "hero": "Hero",
    "sky": "Sky",
    "temp": "Temperature",
    "moon": "Moon",
    "sun": "Sun",
    "cover": "Cover",
    "poster": "Poster",
    "vinyl": "Vinyl",
    "sleeve": "Sleeve",
    "wave": "Wave",
    "board": "Board",
    "rating": "Rating",
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
        return shapeForms[shapeOf(config, source, state)].filter(f => f !== "figure" || CardLayouts.figureOf(source));
    return CardLayouts.formsOf(type);
}

function size(cols, rows) {
    return {
        "cols": cols,
        "rows": rows
    };
}

function preferredSizes(form, type) {
    if (type === "clip" || type === "clock")
        return [size(1, 1), size(2, 2)];
    switch (form) {
    case "dial":
    case "number":
    case "moon":
    case "sun":
    case "temp":
        return [size(1, 1)];
    case "ring":
    case "figure":
    case "cells":
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
    case "hero":
        return [size(4, 2), size(4, 1)];
    case "sky":
        return [size(2, 1), size(4, 2)];
    case "board":
        return [size(1, 1), size(2, 1), size(2, 2), size(4, 1), size(4, 2)];
    case "rating":
        return [size(1, 1), size(2, 1)];
    case "cover":
    case "vinyl":
        return [size(1, 1), size(2, 2)];
    case "poster":
    case "sleeve":
        return [size(2, 2)];
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

function distance(a, b) {
    return Math.abs(a.col - b.col) + Math.abs(a.row - b.row);
}

function nearest(spots, from) {
    return spots.reduce((best, spot) => !best || distance(spot, from) < distance(best, from) ? spot : best, null);
}

function spotsOf(size, grid) {
    const spots = [];
    for (let row = 0; row <= rowsOf(grid) - size.rows; row++)
        for (let col = 0; col <= CardLayouts.columns - size.cols; col++)
            spots.push({
                "col": col,
                "row": row,
                "cols": size.cols,
                "rows": size.rows
            });
    return spots;
}

function swapped(widgets, index, col, row, grid) {
    const origin = widgets[index].place;
    const target = Object.assign({}, origin, {
        "col": col,
        "row": row
    });
    if (!CardLayouts.fits(target, grid))
        return null;
    const hit = widgets.map((w, i) => i).filter(i => i !== index && overlaps(widgets[i].place, target));
    if (hit.length !== 1)
        return null;
    const other = hit[0];
    const spot = nearest(spotsOf(widgets[other].place, grid).filter(s => overlaps(s, origin) && !overlaps(s, target) && !widgets.some((w, i) => i !== index && i !== other && overlaps(w.place, s))), origin);
    if (!spot)
        return null;
    return widgets.map((w, i) => i === index ? Object.assign({}, w, {
                "place": target
            }) : i === other ? Object.assign({}, w, {
                "place": spot
            }) : w);
}

function moveOrSwap(widgets, index, col, row, grid) {
    return moved(widgets, index, col, row, grid) ?? swapped(widgets, index, col, row, grid);
}

function pushDirection(other, origin, grown) {
    const right = other.col >= origin.col + origin.cols;
    const down = other.row >= origin.row + origin.rows;
    if (right !== down)
        return right ? "right" : "down";
    return grown.col + grown.cols - other.col <= grown.row + grown.rows - other.row ? "right" : "down";
}

function pushedPast(place, pusher, direction) {
    return direction === "right" ? Object.assign({}, place, {
        "col": pusher.col + pusher.cols
    }) : Object.assign({}, place, {
        "row": pusher.row + pusher.rows
    });
}

function nearestFree(places, index, from, absent, grid) {
    return nearest(spotsOf(from, grid).filter(spot => places.every((p, i) => i === index || absent.has(i) || !overlaps(p, spot))), from);
}

// Growing a widget pushes the ones in its way aside, null when something has nowhere to go
function stretched(widgets, index, wanted, grid) {
    const origin = widgets[index].place;
    const grown = Object.assign({}, origin, wanted);
    if (!CardLayouts.fits(grown, grid))
        return null;
    const places = widgets.map(w => w.place);
    places[index] = grown;
    const evicted = new Set();
    const movers = [[index, null]];
    while (movers.length > 0) {
        const [mover, push] = movers.shift();
        if (evicted.has(mover))
            continue;
        for (let j = 0; j < places.length; j++) {
            if (j === index || j === mover || evicted.has(j) || !overlaps(places[j], places[mover]))
                continue;
            const direction = push ?? pushDirection(places[j], origin, grown);
            const shifted = pushedPast(places[j], places[mover], direction);
            if (CardLayouts.fits(shifted, grid)) {
                places[j] = shifted;
                movers.push([j, direction]);
            } else {
                evicted.add(j);
            }
        }
    }
    const order = Array.from(evicted).sort((a, b) => widgets[a].place.row - widgets[b].place.row || widgets[a].place.col - widgets[b].place.col);
    for (const j of order) {
        evicted.delete(j);
        const spot = nearestFree(places, j, widgets[j].place, evicted, grid);
        if (!spot)
            return null;
        places[j] = spot;
    }
    return widgets.map((w, i) => Object.assign({}, w, {
            "place": places[i]
        }));
}

// The largest size up to the wanted one that fits, the widgets unchanged when none does
function stretchedToward(widgets, index, wanted, grid) {
    const place = widgets[index].place;
    const cols = clamp(wanted.cols, 1, CardLayouts.columns - place.col);
    const rows = clamp(wanted.rows, 1, rowsOf(grid) - place.row);
    const sizes = [];
    for (let c = 1; c <= cols; c++)
        for (let r = 1; r <= rows; r++)
            sizes.push(size(c, r));
    sizes.sort((a, b) => b.cols * b.rows - a.cols * a.rows || b.cols - a.cols);
    for (const s of sizes) {
        const next = stretched(widgets, index, s, grid);
        if (next)
            return next;
    }
    return widgets;
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
    const preferred = distinctSizes(preferredSizes(shownFormOf(widget), widget.type).filter(s => stretched(widgets, index, s, grid) !== null).concat([current]));
    const sizes = preferred.length > 1 ? preferred : sizesFor(widgets, index, grid);
    const at = sizes.findIndex(s => sameSize(s, current));
    return stretched(widgets, index, sizes[(at + 1) % sizes.length], grid);
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

// What the editor changed from base to draft, laid over a config that moved on meanwhile
function rebased(base, draft, latest) {
    const next = Object.assign({}, latest);
    for (const key of new Set(Object.keys(base).concat(Object.keys(draft)))) {
        if (canonicalJson(base[key]) === canonicalJson(draft[key]))
            continue;
        if (draft[key] === undefined)
            delete next[key];
        else
            next[key] = draft[key];
    }
    return next;
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
        for (const s of preferredSizes(form, widget.type))
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
        "on_missing": widget.on_missing ?? null,
        "background": widget.background ?? null
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
    const next = Object.assign({}, config, {
        "values": values
    });
    return source ? next : withStatus(next, statusOf(next).filter(s => s !== id));
}

function statusOf(config) {
    return config?.status ?? [];
}

function withStatus(config, ids) {
    const next = Object.assign({}, config, {
        "status": ids
    });
    if (ids.length === 0)
        delete next.status;
    return next;
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

function isChessUser(name) {
    return chessUserPattern.test(name);
}

function withChessUser(config, text) {
    return withFields(config, {
        "chess_user": text.trim()
    });
}

const chessModeNames = {
    "rapid": "Rapid",
    "blitz": "Blitz",
    "bullet": "Bullet",
    "daily": "Daily"
};
const chessNotFoundExitCode = 5;

// `fresence chess` answers a profile as JSON, and exits chessNotFoundExitCode for an unknown player
function chessPlayer(exitCode, body) {
    if (exitCode === chessNotFoundExitCode)
        return {
            "kind": "missing"
        };
    if (exitCode !== 0)
        return {
            "kind": "unreachable"
        };
    let profile;
    try {
        profile = JSON.parse(body);
    } catch (e) {
        return {
            "kind": "unreachable"
        };
    }
    return Object.assign({
        "kind": "found"
    }, chessModeNames[profile?.mode] !== undefined ? {
        "mode": profile.mode
    } : {}, Number.isInteger(profile?.rating) ? {
        "rating": profile.rating
    } : {});
}

function newChessUser(config, stored) {
    const user = config?.chess_user;
    return user !== undefined && isChessUser(user) && user !== stored?.chess_user ? user : null;
}

// check: { user, player } as the live check last saw it, player null while it runs
function awaitsChessCheck(config, check, stored) {
    const user = newChessUser(config, stored);
    return user !== null && (check?.user !== user || !check.player);
}

function chessUserMissing(config, check, stored) {
    const user = newChessUser(config, stored);
    return user !== null && check?.user === user && check.player?.kind === "missing";
}

function isValidValue(value) {
    if (value.time !== undefined)
        return value.text === undefined && value.fill === undefined;
    return !!value.text;
}

// Problem codes, the order they are listed in
const problemCodes = ["value_source", "image_url", "background_url", "name_length", "value_id", "value_empty", "command", "chess_user", "chess_missing"];

function problems(config) {
    const found = new Set();
    const names = [config.account_name, config.device_name].filter(n => n !== undefined);
    if (names.some(n => n.length === 0 || n.length > maxNameLength))
        found.add("name_length");
    if (config.chess_user !== undefined && !isChessUser(config.chess_user))
        found.add("chess_user");
    for (const w of widgetsOf(config, "row").concat(widgetsOf(config, "detail"))) {
        if (w.type === "value" && !w.source)
            found.add("value_source");
        if (w.type === "image" && !imageUrlPattern.test(w.url ?? ""))
            found.add("image_url");
        if (w.background?.kind === "url" && !imageUrlPattern.test(w.background.url ?? ""))
            found.add("background_url");
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

function sampleChess(nowMs) {
    return {
        "user": "xlamid",
        "mode": "rapid",
        "rating": 1225,
        "best": 1272,
        "history": [1217, 1226, 1236, 1245, 1254, 1246, 1254, 1246, 1238, 1239, 1248, 1257, 1249, 1241, 1250, 1243, 1251, 1245, 1253, 1245, 1254, 1263, 1255, 1264, 1272, 1264, 1258, 1266, 1258, 1266, 1258, 1266, 1259, 1253, 1236, 1215, 1238, 1219, 1202, 1225],
        "last": {
            "fen": "r7/p7/R5p1/2R2b2/kB6/5P2/P1N1r1PP/6K1 b - - 0 31",
            "color": "white",
            "result": "win",
            "ending": "checkmate",
            "opponent": "tsv365",
            "opponent_rating": 1283,
            "moves": 31,
            "delta": 23,
            "ended_at": new Date(nowMs - 25 * 60000).toISOString()
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
        "weather": real.weather ?? {
            "place": "London",
            "temp_c": 12,
            "condition": "partly",
            "precip_mm": 0,
            "wind_kmh": 14,
            "wind_dir_deg": 220,
            "sunrise": new Date(nowMs - 5 * 3600000).toISOString(),
            "sunset": new Date(nowMs + 7 * 3600000).toISOString()
        },
        "chess": config.chess_user ? (real.chess ?? sampleChess(nowMs)) : undefined,
        "values": Object.assign(values, real.values ?? {})
    });
}
