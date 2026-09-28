.pragma library

// Five made-up characters, each a card an owner could have built in the app:
// row and detail grids plus the state that feeds them.

.import "DemoSnapshot.js" as Demo
.import "DemoCovers.js" as DemoCovers

const names = ["nightOwl", "musicHead", "traveler", "coder", "minimal"];

const rows = {
    "nightOwl": [
        Demo.value("local_time", [0, 0, 1, 1], {
            "form": "clock",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.value("window", [1, 0, 2, 1], {
            "form": "text",
            "on_missing": "hide"
        }),
        Demo.value("moon", [3, 0, 1, 1], {
            "form": "moon",
            "color": "primary_container",
            "on_missing": "hide"
        })
    ],
    "musicHead": [
        Demo.widget("media", [0, 0, 1, 1], {
            "form": "vinyl",
            "color": "primary_container",
            "on_missing": "hide"
        }),
        Demo.value("into_lately", [1, 0, 2, 1], {
            "form": "big",
            "color": "secondary_container",
            "label": "Into lately",
            "on_missing": "dim"
        }),
        Demo.value("local_time", [3, 0, 1, 1], {
            "form": "clock",
            "color": "tertiary_container",
            "on_missing": "hide"
        })
    ],
    "traveler": [
        Demo.widget("photo", [0, 0, 2, 1], {
            "on_missing": "hide"
        }),
        Demo.value("local_time", [2, 0, 1, 1], {
            "form": "clock",
            "color": "tertiary_container",
            "on_missing": "hide"
        }),
        Demo.widget("weather", [3, 0, 1, 1], {
            "form": "temp",
            "color": "primary_container",
            "on_missing": "hide"
        })
    ],
    "coder": [
        Demo.value("window", [0, 0, 2, 1], {
            "form": "text",
            "on_missing": "hide"
        }),
        Demo.value("cpu", [2, 0, 1, 1], {
            "form": "ring",
            "color": "primary_container",
            "label": "CPU",
            "on_missing": "dim"
        }),
        Demo.value("workspace", [3, 0, 1, 1], {
            "form": "number",
            "label": "Workspace",
            "icon": "desktop_windows",
            "on_missing": "hide"
        })
    ],
    "minimal": [
        Demo.value("quote", [0, 0, 4, 1], {
            "form": "big",
            "color": "secondary_container",
            "on_missing": "dim"
        })
    ]
};

const details = {
    "nightOwl": [
        Demo.widget("game", [0, 0, 4, 1], {
            "form": "banner",
            "on_missing": "hide"
        }),
        Demo.widget("media", [0, 1, 4, 1], {
            "form": "wave",
            "color": "primary",
            "on_missing": "hide"
        }),
        Demo.value("app", [0, 2, 2, 1], {
            "form": "text",
            "label": "App",
            "icon": "apps",
            "on_missing": "dim"
        }),
        Demo.value("uptime", [2, 2, 1, 1], {
            "form": "number",
            "color": "secondary_container",
            "label": "Uptime",
            "on_missing": "dim"
        }),
        Demo.widget("weather", [3, 2, 1, 1], {
            "form": "temp",
            "color": "tertiary_container",
            "on_missing": "dim"
        }),
        Demo.value("moon", [0, 3, 1, 1], {
            "form": "moon",
            "color": "primary_container",
            "label": "Moon",
            "on_missing": "dim"
        }),
        Demo.value("alarm", [1, 3, 1, 1], {
            "form": "clock",
            "color": "secondary_container",
            "label": "Alarm",
            "icon": "alarm",
            "time_mode": "until",
            "on_missing": "dim"
        }),
        Demo.value("sun", [2, 3, 2, 1], {
            "form": "sun",
            "color": "tertiary_container",
            "label": "Sun",
            "on_missing": "dim"
        })
    ],
    "musicHead": [
        Demo.widget("media", [0, 0, 4, 1], {
            "form": "cover",
            "on_missing": "hide"
        }),
        Demo.value("into_lately", [0, 1, 2, 2], {
            "form": "big",
            "color": "tertiary_container",
            "label": "Into lately",
            "on_missing": "dim"
        }),
        Demo.value("local_time", [2, 1, 1, 1], {
            "form": "clock",
            "color": "primary_container",
            "on_missing": "dim"
        }),
        Demo.widget("weather", [3, 1, 1, 1], {
            "form": "temp",
            "color": "secondary_container",
            "on_missing": "dim"
        }),
        Demo.value("uptime", [2, 2, 2, 1], {
            "form": "number",
            "color": "primary_container",
            "label": "Uptime",
            "on_missing": "dim"
        })
    ],
    "traveler": [
        Demo.widget("photo", [0, 0, 2, 2], {
            "on_missing": "hide"
        }),
        Demo.widget("weather", [2, 0, 2, 2], {
            "form": "temp",
            "color": "primary_container",
            "on_missing": "dim"
        }),
        Demo.value("local_time", [0, 2, 1, 1], {
            "form": "clock",
            "color": "tertiary_container",
            "on_missing": "dim"
        }),
        Demo.value("sun", [1, 2, 1, 1], {
            "form": "sun",
            "color": "tertiary_container",
            "on_missing": "dim"
        }),
        Demo.value("where_i_am", [2, 2, 2, 1], {
            "form": "big",
            "color": "secondary_container",
            "label": "Where I am",
            "on_missing": "dim"
        })
    ],
    "coder": [
        Demo.value("app", [0, 0, 2, 2], {
            "form": "big",
            "color": "primary_container",
            "label": "App",
            "on_missing": "dim"
        }),
        Demo.value("packages", [2, 0, 2, 1], {
            "form": "number",
            "label": "Packages",
            "icon": "inventory_2",
            "on_missing": "dim"
        }),
        Demo.value("load", [2, 1, 1, 1], {
            "form": "number",
            "color": "tertiary_container",
            "label": "Load",
            "on_missing": "dim"
        }),
        Demo.value("local_time", [3, 1, 1, 1], {
            "form": "clock",
            "color": "secondary_container",
            "on_missing": "dim"
        }),
        Demo.widget("media", [0, 2, 4, 1], {
            "form": "wave",
            "color": "tertiary",
            "on_missing": "hide"
        })
    ],
    "minimal": [
        Demo.value("mood", [0, 0, 2, 2], {
            "form": "big",
            "color": "secondary_container",
            "label": "Mood",
            "on_missing": "dim"
        }),
        Demo.value("local_time", [2, 0, 2, 2], {
            "form": "clock",
            "color": "tertiary_container",
            "on_missing": "dim"
        }),
        Demo.widget("weather", [0, 2, 4, 1], {
            "form": "temp",
            "color": "secondary_container",
            "on_missing": "dim"
        })
    ]
};

function text(t) {
    return {
        "text": t
    };
}

// photoPath: an absolute path the scene resolved, for the traveler's shared photo
function state(name, photoPath) {
    switch (name) {
    case "nightOwl":
        return {
            "game": Demo.game("Cyberpunk 2077", Demo.minutes(120), {
                "header": DemoCovers.url("cp2077-header.jpg")
            }),
            "media": Demo.playing("Turn Off the Lights", "Nite Jewel", DemoCovers.url("nightcall.jpg"), 40000, 210000),
            "weather": Demo.weather("Reykjavik", 7, "clear"),
            "values": {
                "local_time": text("03:12"),
                "window": text("◐ notes.md - nvim"),
                "moon": {
                    "text": "Waxing gibbous",
                    "fill": 0.8
                },
                "app": text("mpv"),
                "uptime": text("27h"),
                "alarm": {
                    "time": Demo.iso(Demo.minutes(7 * 60 + 30))
                },
                "sun": {
                    "text": "06:45 · 18:52",
                    "fill": 0.35
                }
            }
        };
    case "musicHead":
        return {
            "media": Demo.playing("Nightcall", "Kavinsky", DemoCovers.url("nightcall.jpg"), 78000, 258000),
            "weather": Demo.weather("Seoul", 18, "clouds"),
            "values": {
                "into_lately": text("synthwave"),
                "local_time": text("21:40"),
                "uptime": text("4h")
            }
        };
    case "traveler":
        return {
            "photo": {
                "id": "photo-demo",
                "key": "a2V5",
                "mime": "image/jpeg",
                "width": 1200,
                "height": 800,
                "expires_at": Demo.iso(Demo.minutes(50))
            },
            "weather": Demo.weather("Barcelona", 24, "clear"),
            "values": {
                "local_time": text("14:05"),
                "sun": {
                    "text": "07:30 · 20:40",
                    "fill": 0.55
                },
                "where_i_am": text("Barcelona, for a week")
            }
        };
    case "coder":
        return {
            "media": Demo.playing("Midnight City", "M83", DemoCovers.url("teardrop.jpg"), 60000, 244000),
            "values": {
                "window": text("fresence - Zed"),
                "cpu": {
                    "text": "38%",
                    "fill": 0.38
                },
                "workspace": text("3"),
                "app": text("Zed"),
                "packages": text("1432"),
                "load": text("1.24"),
                "local_time": text("11:20")
            }
        };
    default:
        return {
            "weather": Demo.weather("Oslo", 12, "rain"),
            "values": {
                "quote": text("Less, but better"),
                "mood": text("🙂"),
                "local_time": text("09:00")
            }
        };
    }
}

// d: extra Demo.device fields, id and account required
function device(name, d, photoPath) {
    return Demo.device(Object.assign({
        "row": rows[name],
        "detail": details[name],
        "state": state(name, photoPath),
        "photo": name === "traveler" ? photoPath : undefined
    }, d));
}
