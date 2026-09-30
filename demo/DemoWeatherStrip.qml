//@ probe fresence -g 700x520 -s 1500
/**
 * The README's live weather strip: a curated handful of sky conditions - clear
 * day and night side by side, rain, thunder, snow, fog and a sunset - instead
 * of DemoWeather's full debug wall. `-p cycle=0` swaps the wall for one tile
 * stepping through every condition every cycleStepMs.
 */
import ".."
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    readonly property int tileUnit: 150
    readonly property int gap: 12

    // The real sunrise/sunset instants only matter through their offset from now
    // and from each other - dayLengthMin fixes how long the day is, sunriseAgoMin
    // how far into it (or past sunset) each scene sits.
    readonly property int dayLengthMin: 780

    function skyWeather(place, tempC, condition, wind, windDir, precip, sunriseAgoMin) {
        return Demo.weather(place, tempC, condition, {
            "wind_kmh": wind,
            "wind_dir_deg": windDir,
            "precip_mm": precip,
            "sunrise": Demo.iso(-Demo.minutes(sunriseAgoMin)),
            "sunset": Demo.iso(Demo.minutes(root.dayLengthMin - sunriseAgoMin))
        });
    }

    readonly property var scenes: ({
            "clear_day": root.skyWeather("Barcelona", 22, "clear", 8, 200, 0, 330),
            "rain": root.skyWeather("Seattle", 14, "rain", 18, 230, 3.5, 330),
            "thunder": root.skyWeather("Miami", 26, "thunder", 22, 90, 6, 330),
            "fog": root.skyWeather("London", 6, "fog", 3, 0, 0, 330),
            "snow": root.skyWeather("Oslo", -3, "snow", 12, 320, 2, 330),
            "clouds": root.skyWeather("Amsterdam", 15, "clouds", 14, 250, 0, 330),
            "twilight": root.skyWeather("Berlin", 15, "clear", 6, 180, 0, 779),
            "clear_night": root.skyWeather("Barcelona", 12, "clear", 8, 200, 0, 930)
        })

    function deviceFor(key) {
        return {
            "device_id": `dev-${key}`,
            "online": true,
            "state": {
                "weather": root.scenes[key]
            }
        };
    }

    function wallTile(key, cols, color) {
        return {
            "widget": Demo.widget("weather", [0, 0, cols, 1], {
                "form": "sky",
                "color": color
            }),
            "device": root.deviceFor(key)
        };
    }

    readonly property var wallTiles: [
        root.wallTile("clear_day", 1, "primary_container"),
        root.wallTile("rain", 2, "secondary_container"),
        root.wallTile("thunder", 1, "secondary_container"),
        root.wallTile("fog", 2, "primary_container"),
        root.wallTile("twilight", 2, "tertiary_container"),
        root.wallTile("snow", 1, "secondary_container"),
        root.wallTile("clear_night", 2, "tertiary_container"),
        root.wallTile("clouds", 1, "primary_container")
    ]

    property int cycle: -1
    readonly property int cycleStepMs: 3000
    readonly property var cycleConditions: ["clear", "mostly_clear", "partly", "clouds", "fog", "drizzle", "rain", "showers", "thunder", "hail", "snow", "snow_grains", "snow_showers"]
    readonly property var shownTiles: root.cycle >= 0 ? [root.conditionTile(root.cycleConditions[root.cycle % root.cycleConditions.length])] : root.wallTiles

    function conditionTile(condition) {
        return {
            "widget": Demo.widget("weather", [0, 0, 2, 1], {
                "form": "sky",
                "color": "primary_container"
            }),
            "device": {
                "device_id": `dev-${condition}`,
                "online": true,
                "state": {
                    "weather": Demo.weather("London", 12, condition, {
                        "wind_kmh": 10,
                        "wind_dir_deg": 270,
                        "sunrise": Demo.iso(-Demo.minutes(330)),
                        "sunset": Demo.iso(Demo.minutes(root.dayLengthMin - 330))
                    })
                }
            }
        };
    }

    Timer {
        interval: root.cycleStepMs
        running: root.cycle >= 0
        repeat: true
        onTriggered: root.cycle += 1
    }

    function checks() {
        return [
            {
                "name": "every curated tile renders one CardTile with a sky",
                "got": Items.tiles(wall).map(t => Items.byName(t, "tileWeatherSky")[0]?.status === 1),
                "want": root.shownTiles.map(() => true)
            },
            {
                "name": "every tile's form loads",
                "got": Items.brokenForms(wall),
                "want": []
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
            model: root.shownTiles
            delegate: CardTile {
                id: tileItem
                required property var modelData
                readonly property int cols: tileItem.modelData.widget.place.cols
                width: tileItem.cols * root.tileUnit + (tileItem.cols - 1) * root.gap
                height: root.tileUnit
                widget: tileItem.modelData.widget
                device: tileItem.modelData.device
            }
        }
    }
}
