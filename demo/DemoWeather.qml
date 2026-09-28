//@ probe fresence -g 1300x760 -s 2500
/**
 * The animated live weather tile (weather_live form + WeatherSky) at every condition,
 * day and night, both sizes - plus a few tiles that isolate one axis each: light vs
 * heavy rain, windy vs calm, a cold vs a hot reading, and a waxing crescent vs a waxing
 * gibbous moon. arcMoments steps the sun and moon around their arcs: sunrise, morning,
 * noon, late afternoon and sunset by day, dusk, midnight and pre-dawn by night. A plain
 * weather form with a free-text value, and the moon and sun forms driven by fill, close
 * it out.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    readonly property int tileUnit: 96
    readonly property int gap: 8

    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170
    readonly property int dayNowMin: 720
    readonly property int nightNowMin: 1320

    function weatherValue(temp, code, precip, wind, windDir, sunrise, sunset, nowMin, moonIllum, moonPhase, city) {
        const isDay = nowMin >= sunrise && nowMin < sunset ? 1 : 0;
        return `${temp};${code};${precip};${wind};${windDir};${isDay};${moonIllum};${moonPhase};${sunrise};${sunset};${nowMin};${city}`;
    }

    readonly property var conditions: [
        {
            "key": "clear",
            "code": 113,
            "temp": 22,
            "nightTemp": 12,
            "precip": 0,
            "wind": 8,
            "windDir": 200,
            "city": "Barcelona",
            "moonIllum": 28,
            "moonPhase": "Waxing Crescent"
        },
        {
            "key": "clouds",
            "code": 119,
            "temp": 15,
            "nightTemp": 9,
            "precip": 0,
            "wind": 14,
            "windDir": 250,
            "city": "Amsterdam",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain",
            "code": 302,
            "temp": 14,
            "nightTemp": 11,
            "precip": 3.5,
            "wind": 18,
            "windDir": 230,
            "city": "Seattle",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "thunder",
            "code": 389,
            "temp": 26,
            "nightTemp": 21,
            "precip": 6,
            "wind": 22,
            "windDir": 90,
            "city": "Miami",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "snow",
            "code": 332,
            "temp": -3,
            "nightTemp": -8,
            "precip": 2,
            "wind": 12,
            "windDir": 320,
            "city": "Oslo",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "fog",
            "code": 248,
            "temp": 6,
            "nightTemp": 4,
            "precip": 0,
            "wind": 3,
            "windDir": 0,
            "city": "London",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        }
    ]

    readonly property var variants: [
        {
            "key": "rain_light",
            "code": 296,
            "temp": 16,
            "precip": 0.5,
            "wind": 5,
            "windDir": 180,
            "city": "Dublin",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain_heavy",
            "code": 308,
            "temp": 15,
            "precip": 8,
            "wind": 10,
            "windDir": 180,
            "city": "Mumbai",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain_windy",
            "code": 302,
            "temp": 13,
            "precip": 3,
            "wind": 45,
            "windDir": 90,
            "city": "Wellington",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "rain_calm",
            "code": 302,
            "temp": 13,
            "precip": 3,
            "wind": 1,
            "windDir": 0,
            "city": "Kyoto",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "wind_ne",
            "code": 302,
            "temp": 13,
            "precip": 3,
            "wind": 20,
            "windDir": 43,
            "city": "Helsinki",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "wind_w",
            "code": 302,
            "temp": 13,
            "precip": 3,
            "wind": 20,
            "windDir": 270,
            "city": "Lisbon",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "clear_cold",
            "code": 113,
            "temp": -18,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Yakutsk",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "clear_hot",
            "code": 113,
            "temp": 41,
            "precip": 0,
            "wind": 6,
            "windDir": 200,
            "city": "Phoenix",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "clear_full_moon",
            "code": 113,
            "temp": 8,
            "precip": 0,
            "wind": 5,
            "windDir": 180,
            "city": "Reykjavik",
            "now": 1320,
            "moonIllum": 96,
            "moonPhase": "Waxing Gibbous"
        },
        {
            "key": "possible_thunder_no_precip",
            "code": 200,
            "temp": 20,
            "precip": 0,
            "wind": 10,
            "windDir": 150,
            "city": "Denver",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "possible_rain_no_precip",
            "code": 176,
            "temp": 17,
            "precip": 0,
            "wind": 8,
            "windDir": 140,
            "city": "Nairobi",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
        },
        {
            "key": "possible_rain_with_precip",
            "code": 176,
            "temp": 17,
            "precip": 1.2,
            "wind": 8,
            "windDir": 140,
            "city": "Nairobi",
            "moonIllum": 50,
            "moonPhase": "First Quarter"
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

    readonly property string legacyKey: "weather_text"
    readonly property string legacyValue: "9° Rain · Lisbon, PT"

    readonly property var fills: ({
            "moon_crescent": {
                "text": "Waxing Crescent",
                "fill": 0.25
            },
            "moon_gibbous": {
                "text": "Waxing Gibbous",
                "fill": 0.9
            },
            "sun_morning": {
                "text": "06:30 - 19:30",
                "fill": 0.2
            },
            "sun_evening": {
                "text": "06:30 - 19:30",
                "fill": 0.8
            }
        })

    function fieldEntries() {
        const entries = {};
        for (const c of root.conditions) {
            entries[`${c.key}_day`] = root.weatherValue(c.temp, c.code, c.precip, c.wind, c.windDir, root.sunriseMin, root.sunsetMin, root.dayNowMin, c.moonIllum, c.moonPhase, c.city);
            entries[`${c.key}_night`] = root.weatherValue(c.nightTemp, c.code, c.precip, c.wind, c.windDir, root.sunriseMin, root.sunsetMin, root.nightNowMin, c.moonIllum, c.moonPhase, c.city);
        }
        for (const v of root.variants)
            entries[v.key] = root.weatherValue(v.temp, v.code, v.precip, v.wind, v.windDir, root.sunriseMin, root.sunsetMin, v.now ?? root.dayNowMin, v.moonIllum, v.moonPhase, v.city);
        for (const a of root.arcMoments)
            entries[a.key] = root.weatherValue(a.temp, 113, 0, 6, 180, root.sunriseMin, root.sunsetMin, a.now, 62, "Waxing Gibbous", "Berlin");
        entries[root.legacyKey] = root.legacyValue;
        return entries;
    }
    readonly property var fields: root.fieldEntries()

    readonly property var device: {
        const values = {};
        for (const key in root.fields)
            values[key] = {
                "text": root.fields[key]
            };
        return {
            "device_id": "dev-weather",
            "online": true,
            "state": {
                "values": Object.assign(values, root.fills)
            }
        };
    }

    function wallTile(source, cols, color, form) {
        return Demo.value(source, [0, 0, cols, 1], {
            "form": form ?? "weather_live",
            "color": color
        });
    }

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
        tiles.push(root.wallTile(root.legacyKey, 2, "secondary_container", "weather"));
        for (const key in root.fills)
            tiles.push(root.wallTile(key, 1, "tertiary_container", key.startsWith("moon") ? "moon" : "sun"));
        return tiles;
    }

    function tileFor(source, cols) {
        return Items.tiles(wall).find(t => t.widget.source === source && (cols === undefined || t.widget.place.cols === cols)) ?? null;
    }

    function skyFor(source, cols) {
        return Items.findAll(root.tileFor(source, cols), it => it.condition !== undefined && it.showsThunder !== undefined)[0] ?? null;
    }

    function textPartsOf(source, cols) {
        return Items.findAll(root.tileFor(source, cols), it => it.text !== undefined && it.font !== undefined && it.visible && it.text.length > 0).map(it => it.text);
    }

    function bodyOf(source, cols, name) {
        return Items.byName(root.tileFor(source, cols), name)[0] ?? null;
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
        const possibleThunderNoPrecip = root.skyFor("possible_thunder_no_precip");
        const possibleRainNoPrecip = root.skyFor("possible_rain_no_precip");
        const possibleRainWithPrecip = root.skyFor("possible_rain_with_precip");
        const arcDayKeys = ["arc_sunrise", "arc_morning", "arc_noon", "arc_late_afternoon", "arc_sunset"];
        const arcNightKeys = ["arc_dusk", "arc_midnight", "arc_predawn"];
        const sunXs = arcDayKeys.map(k => root.bodyOf(k, 2, "weatherSun")?.x);
        const sunNoonY = root.bodyOf("arc_noon", 2, "weatherSun")?.y;
        const sunSunriseY = root.bodyOf("arc_sunrise", 2, "weatherSun")?.y;
        const arcNoonFields = CardLayouts.weatherFieldsOf(root.fields.arc_noon);
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
                "name": "the sky reads its condition and day/night off the compact value",
                "got": [clearDay?.condition, clearDay?.isDay, clearNight?.isDay, thunderDay?.showsThunder, thunderDay?.showsRain, snowNight?.showsSnow],
                "want": ["clear", true, false, true, true, true]
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
                "name": "code 200 ('thundery outbreaks possible') with no measured precipitation reads as clouds, not thunder",
                "got": [possibleThunderNoPrecip?.condition, possibleThunderNoPrecip?.showsThunder, possibleThunderNoPrecip?.showsRain],
                "want": ["clouds", false, false]
            },
            {
                "name": "code 176 ('patchy rain nearby') with no measured precipitation reads as clouds",
                "got": possibleRainNoPrecip?.condition,
                "want": "clouds"
            },
            {
                "name": "code 176 ('patchy rain nearby') with measured precipitation reads as rain",
                "got": possibleRainWithPrecip?.condition,
                "want": "rain"
            },
            {
                "name": "a hot reading warms the tone further than a cold one",
                "got": clearHot?.warmth > clearCold?.warmth,
                "want": true
            },
            {
                "name": "the compact value splits into a temperature and the city",
                "got": root.textPartsOf("clear_day", 1),
                "want": ["Barcelona", "22°"]
            },
            {
                "name": "a free-text weather value shows its temperature under the city, with no sky",
                "got": [root.textPartsOf(root.legacyKey, 2), root.skyFor(root.legacyKey, 2)],
                "want": [["Lisbon, PT", "9°"], null]
            },
            {
                "name": "the compact value carries moon illumination and phase, a crescent waxing and a gibbous also waxing",
                "got": [CardLayouts.weatherFieldsOf(root.fields.clear_night).moonIllum, CardLayouts.weatherFieldsOf(root.fields.clear_night).moonPhase, CardLayouts.weatherFieldsOf(root.fields.clear_full_moon).moonIllum, CardLayouts.weatherFieldsOf(root.fields.clear_full_moon).moonPhase],
                "want": [28, "Waxing Crescent", 96, "Waxing Gibbous"]
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
                "name": "the compact value parses sunrise, sunset and now in minutes since midnight",
                "got": [arcNoonFields.sunriseMin, arcNoonFields.sunsetMin, arcNoonFields.nowMin],
                "want": [root.sunriseMin, root.sunsetMin, 780]
            },
            {
                "name": "the moon form lights as much of the disc as its fill says",
                "got": ["moon_crescent", "moon_gibbous"].map(k => root.bodyOf(k, 1, "moonDisc")?.lit),
                "want": [0.25, 0.9],
                "tol": 0.001
            },
            {
                "name": "the sun form puts the sun as far along its arc as its fill says",
                "got": ["sun_morning", "sun_evening"].map(k => root.bodyOf(k, 1, "sunArc")?.progress),
                "want": [0.2, 0.8],
                "tol": 0.001
            },
            {
                "name": "the moon and sun forms caption the value's text",
                "got": ["moon_crescent", "sun_evening"].map(k => root.textPartsOf(k, 1)),
                "want": [["Waxing Crescent"], ["06:30 - 19:30"]]
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
                width: tileItem.modelData.place.cols === 2 ? root.tileUnit * 2 + root.gap : root.tileUnit
                height: root.tileUnit
                widget: tileItem.modelData
                device: root.device
            }
        }
    }
}
