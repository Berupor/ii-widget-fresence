//@ probe fresence -g 700x520 -s 1500
/**
 * The README's live weather strip: a curated handful of weather_live
 * conditions - clear day and night side by side, rain, thunder, snow, fog
 * and a sunset - instead of DemoWeather's full debug wall.
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

    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170

    function weatherValue(temp, code, precip, wind, windDir, nowMin, moonIllum, moonPhase, city) {
        const isDay = nowMin >= root.sunriseMin && nowMin < root.sunsetMin ? 1 : 0;
        return `${temp};${code};${precip};${wind};${windDir};${isDay};${moonIllum};${moonPhase};${root.sunriseMin};${root.sunsetMin};${nowMin};${city}`;
    }

    readonly property var fields: ({
            "clear_day": root.weatherValue(22, 113, 0, 8, 200, 720, 28, "Waxing Crescent", "Barcelona"),
            "rain": root.weatherValue(14, 302, 3.5, 18, 230, 720, 50, "First Quarter", "Seattle"),
            "thunder": root.weatherValue(26, 389, 6, 22, 90, 720, 50, "First Quarter", "Miami"),
            "fog": root.weatherValue(6, 248, 0, 3, 0, 720, 50, "First Quarter", "London"),
            "snow": root.weatherValue(-3, 332, 2, 12, 320, 720, 50, "First Quarter", "Oslo"),
            "clouds": root.weatherValue(15, 119, 0, 14, 250, 720, 50, "First Quarter", "Amsterdam"),
            "twilight": root.weatherValue(15, 113, 0, 6, 180, root.sunsetMin - 1, 62, "Waxing Gibbous", "Berlin"),
            "clear_night": root.weatherValue(12, 113, 0, 8, 200, 1320, 28, "Waxing Crescent", "Barcelona")
        })

    function wallTile(source, cols, color) {
        return Demo.value(source, [0, 0, cols, 1], {
            "form": "weather_live",
            "color": color
        });
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
                "values": values
            }
        };
    }

    function checks() {
        return [
            {
                "name": "every curated tile renders one CardTile with a sky",
                "got": Items.tiles(wall).map(t => Items.byName(t, "tileWeatherSky")[0]?.status === 1),
                "want": root.wallTiles.map(() => true)
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
            model: root.wallTiles
            delegate: CardTile {
                id: tileItem
                required property var modelData
                readonly property int cols: tileItem.modelData.place.cols
                width: tileItem.cols * root.tileUnit + (tileItem.cols - 1) * root.gap
                height: root.tileUnit
                widget: tileItem.modelData
                device: root.device
            }
        }
    }
}
