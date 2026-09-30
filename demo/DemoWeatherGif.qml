//@ probe fresence -g 800x220 -s 1500
/**
 * Frame source for docs/weather.gif (tests/widget-gif.sh): a sun tile and a
 * thunderstorm tile, side by side. `frame` (set via -p after load) drives both:
 * the arc tile's sunrise/sunset are placed so its elapsed time - and so its
 * schematic nowMin - loops once around the clock over totalFrames, and skyPhase
 * steps WeatherSky's rain and lightning through CardTile's skyAnimPhase hook -
 * a plain data change either way, so the same frame always renders the same
 * picture.
 */
import ".."
import "lib/DemoSnapshot.js" as Demo
import "lib/DemoItems.js" as Items
import qs.modules.common
import QtQuick

Item {
    id: root
    Component.onCompleted: Fresence.frozenAt = Demo.now
    property int frame: 0

    readonly property int totalFrames: 40
    readonly property int sunriseMin: 390
    readonly property int sunsetMin: 1170
    readonly property int dayLengthMin: root.sunsetMin - root.sunriseMin
    readonly property int nowMin: Math.round(720 + root.frame * 1440 / root.totalFrames) % 1440
    readonly property real elapsedMin: ((root.nowMin - root.sunriseMin) % 1440 + 1440) % 1440
    readonly property real skyStepMs: 90
    readonly property real skyPhase: root.frame * root.skyStepMs

    function skyFromNow(place, tempC, condition, wind, windDir, precip, elapsedMin) {
        const sunriseMs = Fresence.now - elapsedMin * 60000;
        return Demo.weather(place, tempC, condition, {
            "wind_kmh": wind,
            "wind_dir_deg": windDir,
            "precip_mm": precip,
            "sunrise": new Date(sunriseMs).toISOString(),
            "sunset": new Date(sunriseMs + root.dayLengthMin * 60000).toISOString()
        });
    }

    readonly property int tileUnit: 180
    readonly property int gap: 14

    function wallTile(color) {
        return Demo.widget("weather", [0, 0, 2, 1], {
            "form": "sky",
            "color": color
        });
    }

    readonly property var wallTiles: [root.wallTile("tertiary_container"), root.wallTile("primary_container")]

    readonly property var arcDevice: ({
            "device_id": "dev-arc",
            "online": true,
            "state": {
                "weather": root.skyFromNow("Berlin", 18, "clear", 6, 180, 0, root.elapsedMin)
            }
        })

    readonly property var thunderDevice: ({
            "device_id": "dev-thunder",
            "online": true,
            "state": {
                "weather": root.skyFromNow("Bergen", 7, "thunder", 22, 230, 6, 330)
            }
        })

    readonly property var devices: [root.arcDevice, root.thunderDevice]

    function checks() {
        const arcSky = Items.findAll(wallRepeater.itemAt(0), it => it.condition !== undefined && it.showsFlash !== undefined)[0] ?? null;
        return [
            {
                "name": "the arc tile's day/night follows frame, not the clock",
                "got": arcSky?.isDay,
                "want": root.elapsedMin < root.dayLengthMin
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
                required property int index
                width: root.tileUnit * 2 + root.gap
                height: root.tileUnit
                widget: tileItem.modelData
                device: root.devices[tileItem.index]
                skyAnimPhase: root.skyPhase
            }
        }
    }
}
