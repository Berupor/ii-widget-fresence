//@ probe fresence -g 800x220 -s 1500
/**
 * Frame source for docs/weather.gif (tests/widget-gif.sh): a sun tile and a
 * thunderstorm tile, side by side. `frame` (set via -p after load) drives both:
 * nowMin loops once around the clock over totalFrames, and skyPhase steps
 * WeatherSky's rain and lightning through CardTile's skyAnimPhase hook - a plain
 * data change either way, so the same frame always renders the same picture.
 */
import ".."
import "../CardLayouts.js" as CardLayouts
import "lib/DemoSnapshot.js" as Demo
import qs.modules.common
import QtQuick

Item {
    id: root
    property int frame: 0

    readonly property int totalFrames: 40
    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170
    readonly property int nowMin: Math.round(720 + root.frame * 1440 / root.totalFrames) % 1440
    readonly property real skyStepMs: 90
    readonly property real skyPhase: root.frame * root.skyStepMs

    function weatherValue(temp, code, precip, wind, windDir, nowMin, moonIllum, moonPhase, city) {
        const isDay = nowMin >= root.sunriseMin && nowMin < root.sunsetMin ? 1 : 0;
        return `${temp};${code};${precip};${wind};${windDir};${isDay};${moonIllum};${moonPhase};${root.sunriseMin};${root.sunsetMin};${nowMin};${city}`;
    }

    readonly property int tileUnit: 180
    readonly property int gap: 14

    function wallTile(source, color) {
        return Demo.value(source, [0, 0, 2, 1], {
            "form": "weather_live",
            "color": color
        });
    }

    readonly property var wallTiles: [root.wallTile("arc", "tertiary_container"), root.wallTile("thunder", "primary_container")]

    readonly property var device: ({
            "device_id": "dev-weather",
            "online": true,
            "state": {
                "values": {
                    "arc": {
                        "text": root.weatherValue(18, 113, 0, 6, 180, root.nowMin, 70, "Waxing Gibbous", "Berlin")
                    },
                    "thunder": {
                        "text": root.weatherValue(7, 389, 6, 22, 230, 720, 50, "First Quarter", "Bergen")
                    }
                }
            }
        })

    function checks() {
        return [
            {
                "name": "the arc tile's day/night follows frame, not the clock",
                "got": CardLayouts.weatherFieldsOf(root.device.state.values.arc.text)?.isDay,
                "want": root.nowMin >= root.sunriseMin && root.nowMin < root.sunsetMin
            },
            {
                "name": "the sky steps with frame through CardTile's skyAnimPhase",
                "got": wallRepeater.itemAt(1)?.skyAnimPhase,
                "want": root.skyPhase
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
            id: wallRepeater
            model: root.wallTiles
            delegate: CardTile {
                id: tileItem
                required property var modelData
                width: root.tileUnit * 2 + root.gap
                height: root.tileUnit
                widget: tileItem.modelData
                device: root.device
                skyAnimPhase: root.skyPhase
            }
        }
    }
}
