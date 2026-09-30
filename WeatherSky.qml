import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "CardLayouts.js" as CardLayouts

Item {
    id: sky
    required property var weather
    required property color tint
    required property color contentColor
    required property bool running
    // -1 leaves the rain and lightning on their own wall-clock loops; set to pin every
    // drop and strike to that many elapsed ms, for a frame that must render the same on
    // every run.
    property real animPhase: -1

    // No tile span reaches this sibling of TileWeatherLive, so the 2x1 layout is read
    // back off the rendered aspect ratio instead - keep sceneStart's fraction matching
    // TileWeatherLive's textFraction, the two split the same tile.
    readonly property bool wide: sky.width > sky.height * 1.5
    readonly property real sceneStart: sky.wide ? sky.width * 0.45 : 0

    readonly property var clock: CardLayouts.skyClock(sky.weather, Fresence.now)
    readonly property var moonPhase: CardLayouts.moonPhase(Fresence.now)
    readonly property string condition: sky.weather?.condition ?? "clouds"
    readonly property bool isDay: sky.nowMin >= sky.sunriseMin && sky.nowMin < sky.sunsetMin
    readonly property real tempC: sky.weather?.temp_c ?? 15
    readonly property real precipMM: sky.weather?.precip_mm ?? (sky.showsSnow || sky.showsGrains ? 1 : sky.showsRain ? 2 : 0)
    readonly property real windKmph: sky.weather?.wind_kmh ?? 6
    readonly property real windDirDeg: sky.weather?.wind_dir_deg ?? 0

    readonly property real sunriseMin: sky.clock.sunriseMin
    readonly property real sunsetMin: sky.clock.sunsetMin
    readonly property real nowMin: sky.clock.nowMin
    // 0 at sunrise/sunset, up to 1 at the moment itself, over a ~50min approach on
    // either side - the horizon warms before the tone lifts off the temperature alone.
    readonly property real twilightWindow: 50
    readonly property real twilightStrength: Math.max(0, 1 - Math.min(Math.abs(sky.nowMin - sky.sunriseMin), Math.abs(sky.nowMin - sky.sunsetMin)) / sky.twilightWindow)
    readonly property real dayProgress: sky.arcProgress(sky.nowMin, sky.sunriseMin, sky.sunsetMin)
    readonly property real nightProgress: sky.arcProgress(((sky.nowMin - sky.sunsetMin) % 1440 + 1440) % 1440, 0, ((sky.sunriseMin - sky.sunsetMin) % 1440 + 1440) % 1440)

    readonly property bool showsSun: ["clear", "mostly_clear", "partly", "showers", "snow_showers"].includes(sky.condition)
    readonly property bool showsRain: ["rain", "showers", "thunder", "hail"].includes(sky.condition)
    readonly property bool showsDrizzle: sky.condition === "drizzle"
    readonly property bool showsSnow: sky.condition === "snow" || sky.condition === "snow_showers"
    readonly property bool showsGrains: sky.condition === "snow_grains"
    readonly property bool showsHail: sky.condition === "hail"
    readonly property bool showsFlash: sky.condition === "thunder" || sky.condition === "hail"
    readonly property bool showsShowerCloud: sky.condition === "showers" || sky.condition === "snow_showers"
    readonly property bool showsLoneCloud: sky.condition === "mostly_clear"
    readonly property bool showsClouds: sky.condition !== "clear" && sky.condition !== "fog"
    readonly property bool showsFog: sky.condition === "fog"
    readonly property bool windy: sky.windKmph >= sky.strongWindKmph
    readonly property real strongWindKmph: 40
    readonly property bool overcast: sky.condition === "clouds" || sky.condition === "drizzle"
    readonly property int driftingCloudCount: sky.overcast ? 4 : sky.condition === "partly" ? 2 : sky.showsLoneCloud ? 0 : sky.showsShowerCloud ? 1 : 3

    readonly property real intensity: Math.max(0, Math.min(1, sky.precipMM / 8))
    readonly property real windTilt: Math.max(-24, Math.min(24, -(sky.windKmph / sky.strongWindKmph) * 24 * Math.sin(sky.windDirDeg * Math.PI / 180)))

    readonly property real coldC: -5
    readonly property real hotC: 32
    readonly property real warmth: Math.max(0, Math.min(1, (sky.tempC - sky.coldC) / (sky.hotC - sky.coldC)))
    readonly property real toneSaturation: 0.85
    readonly property bool darkTheme: sky.contentColor.hslLightness > 0.5
    readonly property color pastelPrimary: sky.darkTheme ? Appearance.colors.colPrimary : Appearance.m3colors.m3inversePrimary
    readonly property real maxToneLightness: 0.62
    readonly property real toneLightness: Math.min(sky.pastelPrimary.hslLightness, sky.maxToneLightness)
    readonly property color coldTone: Qt.hsla(0.6, sky.toneSaturation, sky.toneLightness, 1)
    readonly property color hotTone: Qt.hsla(0.07, sky.toneSaturation, sky.toneLightness, 1)
    // Mixed in RGB: a hue rotation from blue to orange passes through green.
    readonly property color toneWash: ColorUtils.applyAlpha(ColorUtils.mix(sky.hotTone, sky.coldTone, sky.warmth), 0.48)
    readonly property real darkNightFade: 0.45
    readonly property real lightNightFade: 0.75
    readonly property color nightWash: ColorUtils.transparentize(Appearance.colors.colScrim, sky.darkTheme ? sky.darkNightFade : sky.lightNightFade)

    readonly property color glowColor: ColorUtils.transparentize(sky.contentColor, 0.65)
    readonly property color glowClearColor: ColorUtils.transparentize(sky.contentColor, 1)
    readonly property color sunColor: ColorUtils.transparentize(sky.contentColor, 0.05)
    readonly property color rayColor: ColorUtils.transparentize(sky.contentColor, 0.25)
    readonly property color moonColor: ColorUtils.transparentize(sky.contentColor, 0.1)
    readonly property color earthshineColor: ColorUtils.transparentize(sky.contentColor, 0.85)
    readonly property color starColor: ColorUtils.transparentize(sky.contentColor, 0.25)
    readonly property color cloudColor: ColorUtils.transparentize(sky.contentColor, 0.3)
    readonly property color rainColor: ColorUtils.transparentize(sky.contentColor, 0.3)
    readonly property color drizzleColor: ColorUtils.transparentize(sky.contentColor, 0.45)
    readonly property color hailColor: ColorUtils.transparentize(sky.contentColor, 0.05)
    readonly property color windColor: ColorUtils.transparentize(sky.contentColor, 0.45)
    readonly property color snowColor: ColorUtils.transparentize(sky.contentColor, 0.1)
    readonly property color fogColor: ColorUtils.transparentize(sky.contentColor, 0.82)
    readonly property color flashColor: ColorUtils.transparentize(sky.contentColor, 0)
    readonly property color flashFaintColor: ColorUtils.transparentize(sky.contentColor, 0.6)

    clip: true

    function hash(n) {
        const v = Math.sin(n * 12.9898) * 43758.5453;
        return v - Math.floor(v);
    }

    readonly property real cloudCrossingMs: 22000
    readonly property real minCloudCrossingMs: 6000
    readonly property real cloudCrossingMsPerKmph: 150
    readonly property real splashShare: 0.22
    readonly property real splashSize: 7
    readonly property int firstStrikeMs: 900
    readonly property int flashRiseMs: 70
    readonly property int flashFallMs: 220
    readonly property real flashPeak: 0.5

    function strikeGapMs(strike) {
        return 1800 + sky.hash(strike) * 3000;
    }

    function pinnedStrike(phase) {
        let strikeAt = sky.firstStrikeMs;
        let strike = 1;
        while (strikeAt + sky.strikeGapMs(strike) <= phase) {
            strikeAt += sky.strikeGapMs(strike);
            strike += 1;
        }
        return {
            "strike": strike,
            "strikeAt": strikeAt
        };
    }

    function pinnedFlashOpacity(phase) {
        const sinceStrike = phase - sky.pinnedStrike(phase).strikeAt;
        if (sinceStrike < 0)
            return 0;
        if (sinceStrike < sky.flashRiseMs)
            return sky.flashPeak * sinceStrike / sky.flashRiseMs;
        return sky.flashPeak * Math.max(0, 1 - (sinceStrike - sky.flashRiseMs) / sky.flashFallMs);
    }

    function arcProgress(pos, start, end) {
        return end > start ? Math.max(0, Math.min(1, (pos - start) / (end - start))) : 0;
    }

    // On a tall (1x1) tile TileWeatherLive centers the city and temperature over the
    // whole tile, so the arc has to stay low, clear of that text - the wide layout
    // keeps them in a left column instead and can let the arc reach for the top.
    readonly property real arcPeakFraction: sky.wide ? 0.06 : 0.74

    // A body's arc across the scene: low behind the left edge at progress 0, highest
    // near the top (sky.arcPeakFraction) at 0.5, low behind the right edge at 1 -
    // restMargin is how much of the disc sinks below the tile at rest, as a fraction of
    // its own size.
    function arcPos(progress, size, restMargin) {
        const left = sky.sceneStart - size / 2;
        const right = sky.width - size / 2;
        const restY = sky.height - (1 - restMargin) * size;
        const peakY = sky.height * sky.arcPeakFraction;
        return Qt.point(left + progress * (right - left), restY - (restY - peakY) * Math.sin(progress * Math.PI));
    }

    // A particle drifting by `travel` px over its fall needs its spawn band widened on
    // the upwind side by that much, or the downwind edge goes bare while the upwind one
    // still has particles converging into frame.
    function driftSpawnRange(travel, width) {
        return travel >= 0 ? {
            "min": -Math.abs(travel),
            "max": width
        } : {
            "min": 0,
            "max": width + Math.abs(travel)
        };
    }

    readonly property real showerPrecipTop: heldCloud.y + heldCloud.height * 0.75
    readonly property real precipTop: sky.showsShowerCloud ? sky.showerPrecipTop : 0

    function precipSpawnRange(travel) {
        return sky.showsShowerCloud ? {
            "min": heldCloud.x + heldCloud.width * 0.1,
            "max": heldCloud.x + heldCloud.width * 0.9
        } : sky.driftSpawnRange(travel, sky.width);
    }

    component Halo: RadialGradient {
        id: halo
        required property real reach
        anchors.centerIn: parent
        width: halo.reach * 2
        height: halo.width
        horizontalRadius: halo.reach
        verticalRadius: halo.reach
        gradient: Gradient {
            GradientStop {
                position: 0
                color: sky.glowColor
            }
            GradientStop {
                position: 1
                color: sky.glowClearColor
            }
        }
    }

    component Cycle: QtObject {
        id: cycle
        required property real durationMs
        required property real offset
        property real progress: sky.animPhase >= 0 ? ((sky.animPhase + cycle.offset * cycle.durationMs) % cycle.durationMs) / cycle.durationMs : cycle.offset

        SequentialAnimation on progress {
            running: sky.running && sky.animPhase < 0
            NumberAnimation {
                from: cycle.offset
                to: 1
                duration: cycle.durationMs * (1 - cycle.offset)
            }
            NumberAnimation {
                from: 0
                to: 1
                duration: cycle.durationMs
                loops: Animation.Infinite
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: sky.toneWash
    }

    Rectangle {
        anchors.fill: parent
        opacity: sky.twilightStrength * 0.6
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: sky.hotTone
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: sky.showsSun

        // At the low ends of the arc (sunrise, sunset) a third of the disc sinks below
        // the tile's own clip, in the empty band under the temperature; the Sunny
        // silhouette's bottom point is shallower than its top one, so a full half would
        // pinch into a sliver.
        Item {
            id: sun
            objectName: "weatherSun"
            visible: sky.isDay
            width: Math.min(sky.width, sky.height) * 0.28
            height: sun.width
            readonly property point pos: sky.arcPos(sky.dayProgress, sun.width, 0.32)
            x: sun.pos.x
            y: sun.pos.y

            Halo {
                reach: sun.width * 1.5
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: sky.sunColor
            }

            Repeater {
                model: sky.showsSun && sky.isDay ? 8 : 0
                delegate: Rectangle {
                    id: ray
                    required property int index
                    readonly property real innerReach: sun.width * 0.62
                    readonly property real outerReach: sun.width * 0.85
                    width: sun.width * 0.12
                    height: ray.outerReach - ray.innerReach
                    radius: width / 2
                    color: sky.rayColor
                    anchors.horizontalCenter: sun.horizontalCenter
                    y: sun.height / 2 - ray.outerReach
                    transform: Rotation {
                        origin.x: ray.width / 2
                        origin.y: ray.outerReach
                        angle: ray.index * (360 / 8)
                    }
                }
            }
        }

        Item {
            id: moon
            objectName: "weatherMoon"
            visible: !sky.isDay
            width: Math.min(sky.width, sky.height) * 0.26
            height: moon.width
            readonly property point pos: sky.arcPos(sky.nightProgress, moon.width, 0.5)
            x: moon.pos.x
            y: moon.pos.y

            readonly property bool waxing: sky.moonPhase.waxing
            readonly property real illum: sky.moonPhase.illumination
            readonly property real r: moon.width / 2
            readonly property real terminatorRx: Math.abs(1 - 2 * moon.illum) * moon.r
            readonly property int outerSweep: moon.waxing ? 1 : 0
            readonly property int innerSweep: moon.illum < 0.5 ? (moon.waxing ? 0 : 1) : (moon.waxing ? 1 : 0)
            // The lit lune: a half-circle limb on the lit side, closed by an inner
            // terminator ellipse whose x-radius shrinks to 0 at the half-lit quarters
            // and back out to r at new/full - Northern-hemisphere framing, so waxing
            // lights the right limb.
            readonly property string litPath: `M ${moon.r},0 A ${moon.r},${moon.r} 0 0 ${moon.outerSweep} ${moon.r},${2 * moon.r} A ${moon.terminatorRx},${moon.r} 0 0 ${moon.innerSweep} ${moon.r},0 Z`

            Halo {
                reach: moon.width * (0.9 + 0.6 * moon.illum)
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: sky.earthshineColor
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: sky.moonColor
                    strokeColor: "transparent"
                    PathSvg {
                        path: moon.litPath
                    }
                }
            }
        }

        Repeater {
            model: !sky.isDay ? 10 : 0
            delegate: Rectangle {
                id: star
                required property int index
                readonly property real phase: sky.hash(star.index)
                width: 2 + sky.hash(star.index + 5) * 1.5
                height: star.width
                radius: width / 2
                color: sky.starColor
                x: sky.hash(star.index) * sky.width
                y: sky.hash(star.index + 11) * sky.height * 0.16
                opacity: 0.25

                SequentialAnimation on opacity {
                    running: sky.running && !sky.isDay
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.9
                        duration: 900 + star.phase * 1400
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        to: 0.25
                        duration: 900 + star.phase * 1400
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: sky.showsSun && !sky.isDay

        Item {
            id: shootingStar
            readonly property real everyMs: 6500
            readonly property real flightMs: 650
            readonly property real tailShare: 0.35
            readonly property real lineWidth: 1.5
            property real liveMs: 0
            readonly property real ms: sky.animPhase >= 0 ? sky.animPhase : shootingStar.liveMs
            readonly property int index: Math.floor(shootingStar.ms / shootingStar.everyMs)
            readonly property real progress: (shootingStar.ms % shootingStar.everyMs) / shootingStar.flightMs
            readonly property real travelX: Math.min(sky.width, sky.height) * 0.9
            readonly property real travelY: Math.min(sky.width, sky.height) * 0.35
            readonly property real startX: sky.sceneStart + sky.hash(shootingStar.index + 40) * (sky.width - sky.sceneStart) * 0.6
            readonly property real startY: sky.hash(shootingStar.index + 41) * sky.height * 0.3
            readonly property real midShare: shootingStar.progress - shootingStar.tailShare / 2
            visible: shootingStar.index > 0 && shootingStar.progress < 1

            Rectangle {
                width: Math.hypot(shootingStar.travelX, shootingStar.travelY) * shootingStar.tailShare
                height: shootingStar.lineWidth
                radius: height / 2
                x: shootingStar.startX + shootingStar.travelX * shootingStar.midShare - width / 2
                y: shootingStar.startY + shootingStar.travelY * shootingStar.midShare - height / 2
                rotation: Math.atan2(shootingStar.travelY, shootingStar.travelX) * 180 / Math.PI
                opacity: Math.max(0, Math.sin(shootingStar.progress * Math.PI))
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: ColorUtils.transparentize(sky.starColor, 1)
                    }
                    GradientStop {
                        position: 1
                        color: sky.starColor
                    }
                }
            }

            NumberAnimation {
                id: flight
                paused: !sky.running
                target: shootingStar
                property: "liveMs"
                duration: shootingStar.flightMs
            }

            Timer {
                interval: shootingStar.everyMs
                repeat: true
                running: sky.running && sky.showsSun && !sky.isDay && sky.animPhase < 0
                onTriggered: {
                    const periodStart = (shootingStar.index + 1) * shootingStar.everyMs;
                    flight.from = periodStart;
                    flight.to = periodStart + shootingStar.flightMs;
                    flight.restart();
                }
            }
        }
    }

    Item {
        id: fog
        anchors.fill: parent
        visible: sky.showsFog

        Rectangle {
            id: hazeShape
            visible: false
            width: sky.width * 1.3
            height: sky.height * 0.4
            radius: height / 2
            color: sky.fogColor
        }

        GaussianBlur {
            id: hazeBlur
            visible: false
            width: hazeShape.width
            height: hazeShape.height
            source: hazeShape
            radius: Math.max(sky.width, sky.height) * 0.12
            samples: 16
            transparentBorder: true
        }

        ShaderEffectSource {
            id: hazeTexture
            visible: false
            sourceItem: sky.showsFog ? hazeBlur : null
            sourceRect: Qt.rect(-hazeBlur.radius, -hazeBlur.radius, hazeShape.width + 2 * hazeBlur.radius, hazeShape.height + 2 * hazeBlur.radius)
        }

        Repeater {
            model: sky.showsFog ? 3 : 0
            delegate: Item {
                id: haze
                required property int index
                // Wide enough, and drifting in a narrow enough band, that both edges stay
                // covered by overflow at every point of the drift - or a still frame (not
                // sky.running) would freeze on the rest x below and leave the right edge bare.
                width: hazeShape.width
                height: hazeShape.height
                y: sky.height * (0.08 + 0.28 * haze.index)
                x: -sky.width * 0.15

                ShaderEffect {
                    property variant source: hazeTexture
                    x: -hazeBlur.radius
                    y: -hazeBlur.radius
                    width: hazeTexture.sourceRect.width
                    height: hazeTexture.sourceRect.height
                }

                SequentialAnimation on x {
                    running: sky.running && sky.showsFog
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: -sky.width * 0.05
                        duration: 5200 + haze.index * 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: -sky.width * 0.25
                        duration: 5200 + haze.index * 900
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !sky.isDay
        color: sky.nightWash
    }

    // Keep sky.wide and precipMaskWide's stops matching where TileWeatherLive puts the
    // caption/temperature: centered when the tile is tall, in a left column of the
    // same textFraction for any wide span (2x1, 4x1, ...).
    Item {
        id: precip
        anchors.fill: parent
        visible: sky.showsClouds || sky.windy
        clip: true

        layer.enabled: sky.showsClouds || sky.windy
        layer.effect: OpacityMask {
            maskSource: sky.wide ? precipMaskWide : precipMaskTall
        }

        Repeater {
            model: sky.showsRain ? Math.round(8 + sky.intensity * 16) : 0
            delegate: Item {
                id: raindrop
                required property int index
                readonly property real fallDuration: 650 - sky.intensity * 250 + sky.hash(raindrop.index + 9) * 300
                readonly property real dropHeight: sky.height * (0.16 + sky.hash(raindrop.index) * 0.14)
                readonly property real fallSpan: sky.height - sky.precipTop + 2 * raindrop.dropHeight
                readonly property real travelX: raindrop.fallSpan * Math.tan(sky.windTilt * Math.PI / 180)
                readonly property var spawnRange: sky.precipSpawnRange(raindrop.travelX)
                readonly property real startX: raindrop.spawnRange.min + sky.hash(raindrop.index + 3) * (raindrop.spawnRange.max - raindrop.spawnRange.min)
                readonly property real landsAt: (sky.height - sky.precipTop) / raindrop.fallSpan
                readonly property real splashProgress: (raindrop.cycle.progress - raindrop.landsAt) / sky.splashShare
                readonly property real splashWidth: sky.splashSize * (0.4 + 0.6 * raindrop.splashProgress)
                readonly property Cycle cycle: Cycle {
                    durationMs: raindrop.fallDuration
                    offset: 0
                }

                Rectangle {
                    width: 2
                    height: raindrop.dropHeight
                    radius: width / 2
                    color: sky.rainColor
                    rotation: -sky.windTilt
                    x: raindrop.startX + raindrop.travelX * raindrop.cycle.progress
                    y: sky.precipTop - height + raindrop.fallSpan * raindrop.cycle.progress
                }

                Rectangle {
                    visible: raindrop.splashProgress >= 0 && raindrop.splashProgress <= 1
                    width: raindrop.splashWidth
                    height: width * 0.35
                    radius: height / 2
                    color: "transparent"
                    border.width: 1
                    border.color: sky.rainColor
                    opacity: 1 - raindrop.splashProgress
                    x: raindrop.startX + raindrop.travelX * raindrop.landsAt + 1 - width / 2
                    y: sky.height - width * 0.3
                }
            }
        }

        Repeater {
            model: sky.showsSnow ? Math.round(6 + sky.intensity * 14) : 0
            delegate: Item {
                id: flake
                required property int index
                readonly property real snowTilt: sky.windTilt * 0.6
                readonly property real driftSpan: (sky.height - sky.precipTop + 2 * flake.height) * Math.tan(flake.snowTilt * Math.PI / 180)
                readonly property var spawnRange: sky.precipSpawnRange(flake.driftSpan)
                readonly property real baseX: flake.spawnRange.min + sky.hash(flake.index + 4) * (flake.spawnRange.max - flake.spawnRange.min)
                readonly property real driftX: (flake.y - sky.precipTop + flake.height) * Math.tan(flake.snowTilt * Math.PI / 180)
                property real swayOffset: 0
                width: 3 + sky.hash(flake.index + 6) * 3
                height: flake.width
                rotation: -flake.snowTilt
                x: flake.baseX + flake.driftX + flake.swayOffset
                y: sky.precipTop - flake.height

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: sky.snowColor
                }

                NumberAnimation on y {
                    running: sky.running && sky.showsSnow
                    from: sky.precipTop - flake.height
                    to: sky.height + flake.height
                    duration: 2200 - sky.intensity * 500 + sky.hash(flake.index + 13) * 1200
                    loops: Animation.Infinite
                }
                SequentialAnimation on swayOffset {
                    running: sky.running && sky.showsSnow
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: sky.width * 0.08
                        duration: 1400 + sky.hash(flake.index + 17) * 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: -sky.width * 0.08
                        duration: 1400 + sky.hash(flake.index + 17) * 900
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        Repeater {
            model: sky.showsDrizzle ? Math.min(44, Math.round(16 + sky.intensity * 200)) : 0
            delegate: Rectangle {
                id: mist
                required property int index
                readonly property real fallDuration: 1500 + sky.hash(mist.index + 9) * 700
                readonly property real travelX: (sky.height + 2 * mist.height) * Math.tan(sky.windTilt * Math.PI / 180)
                readonly property var spawnRange: sky.driftSpawnRange(mist.travelX, sky.width)
                readonly property real startX: mist.spawnRange.min + sky.hash(mist.index + 3) * (mist.spawnRange.max - mist.spawnRange.min)
                readonly property Cycle cycle: Cycle {
                    durationMs: mist.fallDuration
                    offset: sky.hash(mist.index + 31)
                }
                width: 1.2
                height: sky.height * (0.035 + sky.hash(mist.index) * 0.025)
                radius: width / 2
                color: sky.drizzleColor
                rotation: -sky.windTilt
                x: mist.startX + mist.travelX * mist.cycle.progress
                y: -mist.height + (sky.height + 2 * mist.height) * mist.cycle.progress
            }
        }

        Repeater {
            model: sky.showsGrains ? 34 : 0
            delegate: Rectangle {
                id: grain
                required property int index
                readonly property Cycle cycle: Cycle {
                    durationMs: 1000 + sky.hash(grain.index + 9) * 400
                    offset: sky.hash(grain.index + 31)
                }
                width: 2.2
                height: grain.width
                radius: width / 2
                color: sky.snowColor
                x: sky.hash(grain.index + 3) * sky.width - grain.width / 2
                y: -grain.height + (sky.height + 2 * grain.height) * grain.cycle.progress
            }
        }

        Repeater {
            model: sky.showsHail ? 12 : 0
            delegate: Rectangle {
                id: pellet
                required property int index
                readonly property real fallShare: 0.72
                readonly property real bounce: Math.max(0, (pellet.cycle.progress - pellet.fallShare) / (1 - pellet.fallShare))
                readonly property real landedY: sky.height - pellet.height - sky.height * 0.12 * 4 * pellet.bounce * (1 - pellet.bounce)
                readonly property Cycle cycle: Cycle {
                    durationMs: 700 + sky.hash(pellet.index + 9) * 250
                    offset: sky.hash(pellet.index + 31)
                }
                width: 2 * (2 + sky.hash(pellet.index + 6) * 1.5)
                height: pellet.width
                radius: width / 2
                color: sky.hailColor
                opacity: 1 - pellet.bounce
                x: sky.hash(pellet.index + 3) * sky.width - pellet.width / 2
                y: pellet.cycle.progress < pellet.fallShare ? -pellet.height + sky.height * pellet.cycle.progress / pellet.fallShare : pellet.landedY
            }
        }

        Repeater {
            model: sky.windy ? 5 : 0
            delegate: Rectangle {
                id: streak
                required property int index
                readonly property Cycle cycle: Cycle {
                    durationMs: 900 + sky.hash(streak.index + 9) * 500
                    offset: sky.hash(streak.index + 31)
                }
                readonly property real travelled: -streak.width + (sky.width + 2 * streak.width) * streak.cycle.progress
                width: sky.width * (0.18 + 0.12 * sky.hash(streak.index))
                height: 1.5
                radius: height / 2
                color: sky.windColor
                opacity: Math.sin(streak.cycle.progress * Math.PI)
                x: sky.windTilt < 0 ? sky.width - streak.travelled - streak.width : streak.travelled
                y: sky.height * (0.3 + 0.6 * sky.hash(streak.index + 2))
            }
        }

        Item {
            id: clouds
            anchors.fill: parent
            clip: true

            Item {
                id: heldCloud
                visible: sky.showsShowerCloud || sky.showsLoneCloud
                readonly property real puffSize: Math.min(sky.width, sky.height) * 0.34 * (sky.showsShowerCloud ? 1 : 0.6)
                readonly property real swayMs: sky.animPhase >= 0 ? sky.animPhase : heldCloud.liveSwayMs
                property real liveSwayMs: 0
                readonly property real sway: Math.sin(Math.PI * heldCloud.swayMs / 7000)
                width: heldCloud.puffSize * 2.2
                height: heldCloud.puffSize * 1.1
                x: sky.sceneStart + (sky.width - sky.sceneStart) * 0.36 + sky.width * 0.03 * heldCloud.sway - heldCloud.width / 2
                y: sky.height * 0.02
                opacity: sky.showsShowerCloud ? 0.75 : 0.55

                layer.enabled: heldCloud.visible
                layer.effect: GaussianBlur {
                    radius: Math.min(sky.width, sky.height) * 0.08
                    samples: 12
                    transparentBorder: true
                }

                Rectangle {
                    y: heldCloud.puffSize * 0.35
                    width: heldCloud.width
                    height: heldCloud.puffSize * 0.75
                    radius: height / 2
                    color: sky.cloudColor
                }
                Rectangle {
                    x: heldCloud.width / 2 - heldCloud.puffSize * 0.75
                    y: heldCloud.puffSize * -0.05
                    width: heldCloud.puffSize
                    height: width
                    radius: width / 2
                    color: sky.cloudColor
                }
                Rectangle {
                    x: heldCloud.width / 2 + heldCloud.puffSize * 0.07
                    y: heldCloud.puffSize * 0.22
                    width: heldCloud.puffSize * 0.76
                    height: width
                    radius: width / 2
                    color: sky.cloudColor
                }

                NumberAnimation on liveSwayMs {
                    running: sky.running && heldCloud.visible && sky.animPhase < 0
                    from: 0
                    to: 14000
                    duration: 14000
                    loops: Animation.Infinite
                }
            }

            Item {
                id: cloudShape
                readonly property real puffSize: Math.min(sky.width, sky.height) * 0.275
                visible: false
                width: cloudShape.puffSize * 2.4
                height: cloudShape.puffSize * 1.3

                Rectangle {
                    width: cloudShape.puffSize * 1.3
                    height: cloudShape.puffSize * 0.9
                    radius: height / 2
                    color: sky.cloudColor
                    anchors.centerIn: parent
                }
                Rectangle {
                    width: cloudShape.puffSize * 0.9
                    height: cloudShape.puffSize * 0.8
                    radius: height / 2
                    color: sky.cloudColor
                    x: cloudShape.puffSize * 0.15
                    y: cloudShape.puffSize * 0.1
                }
                Rectangle {
                    width: cloudShape.puffSize * 0.8
                    height: cloudShape.puffSize * 0.7
                    radius: height / 2
                    color: sky.cloudColor
                    x: cloudShape.width - width - cloudShape.puffSize * 0.15
                    y: cloudShape.puffSize * 0.18
                }
            }

            GaussianBlur {
                id: cloudBlur
                visible: false
                width: cloudShape.width
                height: cloudShape.height
                source: cloudShape
                radius: Math.min(sky.width, sky.height) * 0.08
                samples: 12
                transparentBorder: true
            }

            ShaderEffectSource {
                id: cloudTexture
                visible: false
                sourceItem: sky.showsClouds && sky.driftingCloudCount > 0 ? cloudBlur : null
            }

            Repeater {
                model: sky.showsClouds ? sky.driftingCloudCount : 0
                delegate: ShaderEffect {
                    id: cloud
                    required property int index
                    property variant source: cloudTexture
                    readonly property real depth: 0.55 + sky.hash(cloud.index) * 0.45
                    readonly property real puffSize: Math.min(sky.width, sky.height) * (0.2 + 0.1 * cloud.depth)
                    readonly property real crossingMs: Math.max(sky.minCloudCrossingMs, sky.cloudCrossingMs - sky.windKmph * sky.cloudCrossingMsPerKmph) / cloud.depth
                    readonly property real travelled: cloud.cycle.progress * (sky.width + cloud.width)
                    readonly property Cycle cycle: Cycle {
                        durationMs: cloud.crossingMs
                        offset: sky.hash(cloud.index + 7)
                    }
                    width: cloud.puffSize * 2.4
                    height: cloud.puffSize * 1.3
                    x: sky.windTilt < 0 ? sky.width - cloud.travelled : cloud.travelled - cloud.width
                    y: sky.overcast ? sky.height * 0.18 * sky.hash(cloud.index + 2) - cloud.height * 0.2 : sky.height * 0.04 * sky.hash(cloud.index + 2) - cloud.height * 0.35
                    opacity: 0.3 + 0.3 * cloud.depth
                    scale: 0.85 + 0.3 * cloud.depth
                }
            }
        }
    }

    Rectangle {
        id: precipMaskTall
        visible: false
        width: sky.width
        height: sky.height
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "white"
            }
            GradientStop {
                position: 0.3
                color: "transparent"
            }
            GradientStop {
                position: 0.8
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: "white"
            }
        }
    }

    Rectangle {
        id: precipMaskWide
        visible: false
        width: sky.width
        height: sky.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: Math.max(0, sky.sceneStart / Math.max(1, sky.width) - 0.05)
                color: "transparent"
            }
            GradientStop {
                position: Math.min(1, sky.sceneStart / Math.max(1, sky.width) + 0.12)
                color: "white"
            }
        }
    }

    Shape {
        id: bolt
        readonly property int strike: sky.animPhase >= 0 ? sky.pinnedStrike(sky.animPhase).strike : flashTimer.strikes
        readonly property real length: sky.height * (sky.wide ? 0.75 : 0.32)
        readonly property real step: Math.min(sky.width, sky.height) * 0.08
        readonly property int segments: 5
        readonly property real topX: sky.sceneStart + (0.2 + 0.6 * sky.hash(bolt.strike + 60)) * (sky.width - sky.sceneStart)
        readonly property var points: [Qt.point(bolt.topX, 0)].concat(Array.from({
            "length": bolt.segments
        }, (_, i) => Qt.point(bolt.topX + (i % 2 === 0 ? 1 : -1) * bolt.step * (0.5 + sky.hash(bolt.strike * 7 + i)), bolt.length * (i + 1) / bolt.segments)))
        anchors.fill: parent
        visible: sky.showsFlash && flash.opacity > 0
        opacity: Math.min(1, 2 * flash.opacity)
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: sky.flashColor
            strokeWidth: 2.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: bolt.points
            }
        }
    }

    Rectangle {
        id: flash
        anchors.fill: parent
        color: sky.flashColor
        gradient: sky.wide ? flashGradient : null
        opacity: sky.showsFlash && sky.animPhase >= 0 ? sky.pinnedFlashOpacity(sky.animPhase) : 0

        Gradient {
            id: flashGradient
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: sky.flashFaintColor
            }
            GradientStop {
                position: 1
                color: sky.flashColor
            }
        }

        SequentialAnimation {
            id: flashPulse
            NumberAnimation {
                target: flash
                property: "opacity"
                to: sky.flashPeak
                duration: sky.flashRiseMs
            }
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0
                duration: sky.flashFallMs
            }
        }

        Timer {
            id: flashTimer
            property int strikes: 0
            interval: sky.firstStrikeMs
            running: sky.running && sky.showsFlash && sky.animPhase < 0
            repeat: true
            onTriggered: {
                flashPulse.restart();
                flashTimer.strikes += 1;
                flashTimer.interval = sky.strikeGapMs(flashTimer.strikes);
            }
        }
    }
}
