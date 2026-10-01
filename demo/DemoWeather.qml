//@ probe fresence -g 1300x760 -s 2500
/**
 * The animated live weather tile (sky form + WeatherSky) at every condition,
 * day and night, both sizes - plus a few tiles that isolate one axis each: light vs
 * heavy rain, windy vs calm, a cold vs a hot reading. arcMoments steps the sun and
 * moon around their arcs: sunrise, morning, noon, late afternoon and sunset by day,
 * dusk, midnight and pre-dawn by night, all against the same schematic sunrise/sunset
 * so skyClock's mapping can be checked directly. The moon and sun forms of the weather
 * widget and the clock close it out.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now
    readonly property int tileUnit: 96
    readonly property int gap: 8

    // Real sunrise/sunset instants only matter through their offset from Fresence.now
    // and from each other - sunriseMin/sunsetMin fix that offset in a schematic day,
    // dayLengthMin how long it runs, elapsedFor() the reverse lookup a scene needs to
    // land at a chosen minute of that day.
    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170
    readonly property int dayLengthMin: root.sunsetMin - root.sunriseMin
    readonly property int dayNowMin: 720
    readonly property int nightNowMin: 1320

    function elapsedFor(nowMinDesired) {
        return ((nowMinDesired - root.sunriseMin) % 1440 + 1440) % 1440;
    }

    function skyWeather(city, tempC, condition, wind, windDir, precip, nowMinDesired) {
        const sunriseMs = Fresence.now - root.elapsedFor(nowMinDesired) * 60000;
        return Demo.weather(city, tempC, condition, {
            "wind_kmh": wind,
            "wind_dir_deg": windDir,
            "precip_mm": precip,
            "sunrise": new Date(sunriseMs).toISOString(),
            "sunset": new Date(sunriseMs + root.dayLengthMin * 60000).toISOString()
        });
    }

    readonly property var conditions: [
        {
            "key": "clear",
            "condition": "clear",
            "temp": 22,
            "nightTemp": 12,
            "precip": 0,
            "wind": 8,
            "windDir": 200,
            "city": "Barcelona"
        },
        {
            "key": "clouds",
            "condition": "clouds",
            "temp": 15,
            "nightTemp": 9,
            "precip": 0,
            "wind": 14,
            "windDir": 250,
            "city": "Amsterdam"
        },
        {
            "key": "partly",
            "condition": "partly",
            "temp": 17,
            "nightTemp": 10,
            "precip": 0,
            "wind": 10,
            "windDir": 270,
            "city": "Prague"
        },
        {
            "key": "rain",
            "condition": "rain",
            "temp": 14,
            "nightTemp": 11,
            "precip": 3.5,
            "wind": 18,
            "windDir": 230,
            "city": "Seattle"
        },
        {
            "key": "thunder",
            "condition": "thunder",
            "temp": 26,
            "nightTemp": 21,
            "precip": 6,
            "wind": 22,
            "windDir": 90,
            "city": "Miami"
        },
        {
            "key": "snow",
            "condition": "snow",
            "temp": -3,
            "nightTemp": -8,
            "precip": 2,
            "wind": 12,
            "windDir": 320,
            "city": "Oslo"
        },
        {
            "key": "fog",
            "condition": "fog",
            "temp": 6,
            "nightTemp": 4,
            "precip": 0,
            "wind": 3,
            "windDir": 0,
            "city": "London"
        }
    ]

    readonly property var variants: [
        {
            "key": "rain_light",
            "condition": "rain",
            "temp": 16,
            "precip": 0.5,
            "wind": 5,
            "windDir": 180,
            "city": "Dublin"
        },
        {
            "key": "rain_heavy",
            "condition": "rain",
            "temp": 15,
            "precip": 8,
            "wind": 10,
            "windDir": 180,
            "city": "Mumbai"
        },
        {
            "key": "rain_windy",
            "condition": "rain",
            "temp": 13,
            "precip": 3,
            "wind": 45,
            "windDir": 90,
            "city": "Wellington"
        },
        {
            "key": "rain_calm",
            "condition": "rain",
            "temp": 13,
            "precip": 3,
            "wind": 1,
            "windDir": 0,
            "city": "Kyoto"
        },
        {
            "key": "wind_ne",
            "condition": "rain",
            "temp": 13,
            "precip": 3,
            "wind": 20,
            "windDir": 43,
            "city": "Helsinki"
        },
        {
            "key": "wind_w",
            "condition": "rain",
            "temp": 13,
            "precip": 3,
            "wind": 20,
            "windDir": 270,
            "city": "Lisbon"
        },
        {
            "key": "clear_cold",
            "condition": "clear",
            "temp": -18,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Yakutsk"
        },
        {
            "key": "clear_hot",
            "condition": "clear",
            "temp": 41,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Phoenix"
        },
        {
            "key": "mostly_clear",
            "condition": "mostly_clear",
            "temp": 18,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Lyon"
        },
        {
            "key": "drizzle",
            "condition": "drizzle",
            "temp": 11,
            "precip": 0.3,
            "wind": 8,
            "windDir": 180,
            "city": "Bergen"
        },
        {
            "key": "showers",
            "condition": "showers",
            "temp": 16,
            "precip": 2,
            "wind": 10,
            "windDir": 200,
            "city": "Auckland"
        },
        {
            "key": "snow_showers",
            "condition": "snow_showers",
            "temp": -1,
            "precip": 1.5,
            "wind": 10,
            "windDir": 320,
            "city": "Tromso"
        },
        {
            "key": "snow_grains",
            "condition": "snow_grains",
            "temp": -6,
            "precip": 0.5,
            "wind": 6,
            "windDir": 320,
            "city": "Reykjavik"
        },
        {
            "key": "hail",
            "condition": "hail",
            "temp": 12,
            "precip": 4,
            "wind": 20,
            "windDir": 270,
            "city": "Denver"
        },
        {
            "key": "drizzle_light",
            "condition": "drizzle",
            "temp": 12,
            "precip": 0.1,
            "wind": 10,
            "windDir": 270,
            "city": "Cork"
        },
        {
            "key": "drizzle_steady",
            "condition": "drizzle",
            "temp": 12,
            "precip": 1,
            "wind": 10,
            "windDir": 270,
            "city": "Galway"
        },
        {
            "key": "rain_downpour",
            "condition": "rain",
            "temp": 12,
            "precip": 10,
            "wind": 10,
            "windDir": 270,
            "city": "Singapore"
        },
        {
            "key": "showers_heavy",
            "condition": "showers",
            "temp": 12,
            "precip": 10,
            "wind": 10,
            "windDir": 270,
            "city": "Darwin"
        },
        {
            "key": "snow_light",
            "condition": "snow",
            "temp": -3,
            "precip": 0.3,
            "wind": 10,
            "windDir": 270,
            "city": "Tallinn"
        },
        {
            "key": "snow_heavy",
            "condition": "snow",
            "temp": -3,
            "precip": 5,
            "wind": 10,
            "windDir": 270,
            "city": "Sapporo"
        },
        {
            "key": "snow_blizzard",
            "condition": "snow",
            "temp": -15,
            "precip": 2,
            "wind": 45,
            "windDir": 270,
            "city": "Reykjavik"
        },
        {
            "key": "clear_freezing",
            "condition": "clear",
            "temp": -20,
            "precip": 0,
            "wind": 10,
            "windDir": 270,
            "city": "Norilsk"
        },
        {
            "key": "clear_scorching",
            "condition": "clear",
            "temp": 35,
            "precip": 0,
            "wind": 10,
            "windDir": 270,
            "city": "Cairo"
        },
        {
            "key": "clear_gale",
            "condition": "clear",
            "temp": 17,
            "precip": 0,
            "wind": 50,
            "windDir": 270,
            "city": "Chicago"
        }
    ]

    // Steps the sun (day) or moon (night) around their arcs, at the same sunrise/sunset
    // as root.sunriseMin/sunsetMin - noon (780) sits exactly at their midpoint.
    readonly property var arcMoments: [
        { "key": "arc_sunrise", "temp": 10, "now": root.sunriseMin, "day": true },
        { "key": "arc_morning", "temp": 14, "now": 540, "day": true },
        { "key": "arc_noon", "temp": 22, "now": 780, "day": true },
        { "key": "arc_late_afternoon", "temp": 19, "now": 1020, "day": true },
        { "key": "arc_sunset", "temp": 15, "now": root.sunsetMin - 1, "day": true },
        { "key": "arc_dusk", "temp": 12, "now": 1200, "day": false },
        { "key": "arc_midnight", "temp": 8, "now": 0, "day": false },
        { "key": "arc_predawn", "temp": 7, "now": 330, "day": false }
    ]

    readonly property var bodyForms: [
        { "key": "moon_night", "form": "moon", "now": 0 },
        { "key": "sun_morning", "form": "sun", "now": 540 },
        { "key": "sun_evening", "form": "sun", "now": 1020 },
        { "key": "sun_night", "form": "sun", "now": 0 },
        { "key": "sun_unknown", "form": "sun" }
    ]

    readonly property int clockOffsetS: 9 * 3600

    readonly property real knownNewMoonMs: Date.parse("2000-01-06T18:14:00Z")
    readonly property real synodicMonthMs: 29.530588853 * 86400000

    function sceneEntries() {
        const entries = {};
        for (const c of root.conditions) {
            entries[`${c.key}_day`] = root.skyWeather(c.city, c.temp, c.condition, c.wind, c.windDir, c.precip, root.dayNowMin);
            entries[`${c.key}_night`] = root.skyWeather(c.city, c.nightTemp, c.condition, c.wind, c.windDir, c.precip, root.nightNowMin);
        }
        for (const v of root.variants)
            entries[v.key] = root.skyWeather(v.city, v.temp, v.condition, v.wind, v.windDir, v.precip, root.dayNowMin);
        for (const a of root.arcMoments)
            entries[a.key] = root.skyWeather("Berlin", a.temp, "clear", 6, 180, 0, a.now);
        for (const b of root.bodyForms)
            entries[b.key] = b.now === undefined ? Demo.weather("Oslo", 3, "snow") : root.skyWeather("Berlin", 10, "clear", 6, 180, 0, b.now);
        return entries;
    }
    readonly property var scenes: root.sceneEntries()

    function deviceFor(key) {
        return {
            "device_id": `dev-${key}`,
            "online": true,
            "state": {
                "weather": root.scenes[key]
            }
        };
    }

    function wallTile(key, cols, color, form) {
        return {
            "widget": Demo.widget("weather", [0, 0, cols, 1], {
                "form": form ?? "sky",
                "color": color
            }),
            "device": root.deviceFor(key)
        };
    }

    readonly property var clockTile: ({
            "widget": Demo.widget("clock", [0, 0, 1, 1], {
                "color": "secondary_container"
            }),
            "device": {
                "device_id": "dev-clock",
                "online": true,
                "state": {
                    "utc_offset_s": root.clockOffsetS
                }
            }
        })

    readonly property var wallTiles: {
        const tiles = [];
        for (const c of root.conditions) {
            tiles.push(root.wallTile(`${c.key}_day`, 1, "primary_container"));
            tiles.push(root.wallTile(`${c.key}_night`, 1, "tertiary_container"));
            tiles.push(root.wallTile(`${c.key}_day`, 2, "primary_container"));
            tiles.push(root.wallTile(`${c.key}_night`, 2, "tertiary_container"));
        }
        for (const v of root.variants)
            tiles.push(root.wallTile(v.key, 1, "secondary_container"));
        for (const a of root.arcMoments) {
            const color = a.day ? "primary_container" : "tertiary_container";
            tiles.push(root.wallTile(a.key, 1, color));
            tiles.push(root.wallTile(a.key, 2, color));
        }
        for (const b of root.bodyForms)
            tiles.push(root.wallTile(b.key, 1, "tertiary_container", b.form));
        tiles.push(root.clockTile);
        return tiles;
    }

    function weatherWidget(form) {
        return Demo.widget("weather", [0, 0, 1, 1], {
            "form": form
        });
    }

    function hhmm(iso) {
        return Qt.formatTime(new Date(Date.parse(iso)), "HH:mm");
    }

    function tileFor(key, cols) {
        return Items.tiles(wall).find(t => (t.widget.source === key || t.device?.device_id === `dev-${key}`) && (cols === undefined || t.widget.place.cols === cols)) ?? null;
    }

    function skyFor(key, cols) {
        return Items.findAll(root.tileFor(key, cols), it => it.condition !== undefined && it.showsFlash !== undefined)[0] ?? null;
    }

    function textPartsOf(key, cols) {
        return Items.findAll(root.tileFor(key, cols), it => it.text !== undefined && it.font !== undefined && it.visible && it.text.length > 0).map(it => it.text);
    }

    function bodyOf(key, cols, name) {
        return Items.byName(root.tileFor(key, cols), name)[0] ?? null;
    }

    function checks() {
        const clearDay = root.skyFor("clear_day", 1);
        const clearNight = root.skyFor("clear_night", 1);
        const thunderDay = root.skyFor("thunder_day", 1);
        const snowNight = root.skyFor("snow_night", 1);
        const rainLight = root.skyFor("rain_light");
        const rainHeavy = root.skyFor("rain_heavy");
        const rainWindy = root.skyFor("rain_windy");
        const rainCalm = root.skyFor("rain_calm");
        const windNE = root.skyFor("wind_ne");
        const windW = root.skyFor("wind_w");
        const clearCold = root.skyFor("clear_cold");
        const clearHot = root.skyFor("clear_hot");
        const [mostlyClear, drizzle, showers, snowShowers, snowGrains, hail, clearGale] = ["mostly_clear", "drizzle", "showers", "snow_showers", "snow_grains", "hail", "clear_gale"].map(k => root.skyFor(k));
        const arcDayKeys = ["arc_sunrise", "arc_morning", "arc_noon", "arc_late_afternoon", "arc_sunset"];
        const arcNightKeys = ["arc_dusk", "arc_midnight", "arc_predawn"];
        const sunXs = arcDayKeys.map(k => root.bodyOf(k, 2, "weatherSun")?.x);
        const sunNoonY = root.bodyOf("arc_noon", 2, "weatherSun")?.y;
        const sunSunriseY = root.bodyOf("arc_sunrise", 2, "weatherSun")?.y;
        const noonClock = CardLayouts.skyClock(root.scenes.arc_noon, Fresence.now);
        const moon = root.bodyOf("moon_night", 1, "moonDisc");
        const phase = CardLayouts.moonPhase(Fresence.now);
        return [
            {
                "name": "every wall tile renders one CardTile",
                "got": Items.tiles(wall).length,
                "want": root.wallTiles.length
            },
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(wall),
                "want": []
            },
            {
                "name": "the sky reads its condition and day/night off state.weather",
                "got": [clearDay?.condition, clearDay?.isDay, clearNight?.isDay, thunderDay?.showsFlash, thunderDay?.showsRain, snowNight?.showsSnow],
                "want": ["clear", true, false, true, true, true]
            },
            {
                "name": "each new condition picks its own layers: sun, rain, drizzle, snow, grains, hail, flash, shower cloud, lone cloud",
                "got": [mostlyClear, drizzle, showers, snowShowers, snowGrains, hail].map(c => ["showsSun", "showsRain", "showsDrizzle", "showsSnow", "showsGrains", "showsHail", "showsFlash", "showsShowerCloud", "showsLoneCloud"].map(f => c?.[f] ? 1 : 0).join("")),
                "want": ["100000001", "001000000", "110000010", "100100010", "000010000", "010001100"]
            },
            {
                "name": "strong wind draws streaks under any condition, calm air draws none",
                "got": [clearGale?.windy, clearGale?.showsClouds, mostlyClear?.windy, rainCalm?.windy],
                "want": [true, false, false, false]
            },
            {
                "name": "heavier rain reads a higher intensity than light rain",
                "got": rainHeavy?.intensity > rainLight?.intensity,
                "want": true
            },
            {
                "name": "a windy reading tilts the falling rain more than a calm one",
                "got": Math.abs(rainWindy?.windTilt ?? 0) > Math.abs(rainCalm?.windTilt ?? 0),
                "want": true
            },
            {
                "name": "wind tilts rain against its source direction: from the NE or E it drifts left, from the W it drifts right",
                "got": [windNE?.windTilt < 0, rainWindy?.windTilt < 0, windW?.windTilt > 0],
                "want": [true, true, true]
            },
            {
                "name": "a hot reading warms the tone further than a cold one",
                "got": clearHot?.warmth > clearCold?.warmth,
                "want": true
            },
            {
                "name": "the sky's foreground text is the city and temperature",
                "got": root.textPartsOf("clear_day", 1),
                "want": ["Barcelona", "22°"]
            },
            {
                "name": "the sun moves monotonically along its arc as the day progresses, peaking near the top at noon",
                "got": [sunXs.every((x, i) => i === 0 || x > sunXs[i - 1]), sunNoonY < sunSunriseY],
                "want": [true, true]
            },
            {
                "name": "isDay follows sunrise/sunset rather than a fixed clock window",
                "got": arcDayKeys.concat(arcNightKeys).map(k => root.skyFor(k, 1)?.isDay),
                "want": [true, true, true, true, true, false, false, false]
            },
            {
                "name": "skyClock pins sunrise at a fixed schematic minute and places sunset and now relative to it",
                "got": [noonClock.sunriseMin, noonClock.sunsetMin, Math.round(noonClock.nowMin)],
                "want": [360, 1140, 750]
            },
            {
                "name": "moon phase illumination runs off the calendar date: 0 at the reference new moon, 1 a synodic month later",
                "got": [CardLayouts.moonPhase(root.knownNewMoonMs).illumination, CardLayouts.moonPhase(root.knownNewMoonMs + root.synodicMonthMs / 2).illumination],
                "want": [0, 1],
                "tol": 0.001
            },
            {
                "name": "the moon waxes through the first quarter and wanes through the last",
                "got": [CardLayouts.moonPhase(root.knownNewMoonMs + root.synodicMonthMs / 4).waxing, CardLayouts.moonPhase(root.knownNewMoonMs + root.synodicMonthMs * 3 / 4).waxing],
                "want": [true, false]
            },
            {
                "name": "the moon form lights the phase of the viewer's clock and names the lit share",
                "got": [moon?.lit, moon?.litSide, root.textPartsOf("moon_night", 1)],
                "want": [phase.illumination, phase.waxing ? 1 : -1, [`${Math.round(phase.illumination * 100)}%`]],
                "tol": 0.001
            },
            {
                "name": "the sun form puts the sun along the daylight gone by and shows it only by day",
                "got": ["sun_morning", "sun_evening", "sun_night"].map(k => [root.bodyOf(k, 1, "sunArc")?.progress, root.bodyOf(k, 1, "sunArc")?.isDay]),
                "want": [[150 / 780, true], [630 / 780, true], [0, false]],
                "tol": 0.005
            },
            {
                "name": "the sun form names the next sunset by day and the next sunrise at night, a dash without sun times",
                "got": ["sun_morning", "sun_night", "sun_unknown"].map(k => root.textPartsOf(k, 1)),
                "want": [[root.hhmm(root.scenes.sun_morning.sunset)], [root.hhmm(root.scenes.sun_night.sunrise)], ["-"]]
            },
            {
                "name": "a sun without sun times draws no disc",
                "got": root.bodyOf("sun_unknown", 1, "sunArc")?.shown,
                "want": false
            },
            {
                "name": "moon needs no weather, sun and sky do, clock needs the owner's offset",
                "got": [CardLayouts.missing(root.weatherWidget("moon"), {}, Fresence.now), CardLayouts.missing(root.weatherWidget("sun"), {}, Fresence.now), CardLayouts.missing(root.weatherWidget("sky"), {}, Fresence.now), CardLayouts.missing(root.clockTile.widget, {}, Fresence.now), CardLayouts.missing(root.clockTile.widget, root.clockTile.device, Fresence.now)],
                "want": [false, true, true, true, false]
            },
            {
                "name": "only the sky lets go of the background",
                "got": ["sky", "temp", "moon", "sun"].map(f => CardLayouts.takesBackground(root.weatherWidget(f))).concat([CardLayouts.takesBackground(root.clockTile.widget)]),
                "want": [false, true, true, true, false]
            }
        ];
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    Flow {
        id: wall
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: root.gap

        Repeater {
            model: root.wallTiles
            delegate: CardTile {
                id: tileItem
                required property var modelData
                width: tileItem.modelData.widget.place.cols === 2 ? root.tileUnit * 2 + root.gap : root.tileUnit
                height: root.tileUnit
                widget: tileItem.modelData.widget
                device: tileItem.modelData.device
            }
        }
    }
}
