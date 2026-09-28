.pragma library

const artlessSeeds = ["#E57373", "#FFB74D", "#D4C050", "#81C784", "#4DB6AC", "#64B5F6", "#9575CD", "#F06292"];
const hashMix = -1640531527;
const hashShift = 16;

const seeds = {};

// app/shared ui/card/ArtPalette.kt artlessSeed: the same String.hashCode pick, so a
// tile without art gets the color the app gives it.
function artlessSeed(key) {
    let hash = 0;
    for (let i = 0; i < key.length; i++)
        hash = (Math.imul(hash, 31) + key.charCodeAt(i)) | 0;
    return artlessSeeds[(Math.imul(hash, hashMix) >>> hashShift) % artlessSeeds.length];
}

function remembered(url) {
    return seeds[url];
}

function remember(url, seed) {
    seeds[url] = seed;
}

function hueOf(seed) {
    const c = Qt.color(seed);
    return c.hslHue >= 0 ? c.hslHue : 0;
}

// Tonal stand-ins for the dynamicColorScheme roles ArtPalette.kt reads: secondaryContainer,
// onSecondaryContainer, primary and the dark surfaceContainerLowest.
function palette(seed, dark) {
    const hue = hueOf(seed);
    return {
        "fill": Qt.hsla(hue, 0.25, dark ? 0.25 : 0.87, 1),
        "content": Qt.hsla(hue, 0.3, dark ? 0.88 : 0.12, 1),
        "accent": Qt.hsla(hue, 0.6, dark ? 0.72 : 0.42, 1),
        "shade": Qt.hsla(hue, 0.2, 0.06, 1)
    };
}
