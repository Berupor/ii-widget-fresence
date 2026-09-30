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

const WHITE_POINT = [95.047, 100, 108.883];
const SRGB_TO_XYZ = [[0.41233895, 0.35762064, 0.18051042], [0.2126, 0.7152, 0.0722], [0.01932141, 0.11916382, 0.95034478]];
const XYZ_TO_SRGB = [[3.2413774792388685, -1.5376652402851851, -0.49885366846268053], [-0.9691452513005321, 1.8758853451067872, 0.04156585616912061], [0.05562093689691305, -0.20395524564742123, 1.0571799111220335]];
const XYZ_TO_CAM16 = [[0.401288, 0.650173, -0.051461], [-0.250268, 1.204414, 0.045854], [-0.002079, 0.048952, 0.953127]];
const SCALED_DISCOUNT_FROM_LINRGB = [[0.001200833568784504, 0.002389694492170889, 0.0002795742885861124], [0.0005891086651375999, 0.0029785502573438758, 0.0003270666104008398], [0.00010146692491640572, 0.0005364214359186694, 0.0032979401770712076]];
const LINRGB_FROM_SCALED_DISCOUNT = [[1373.2198709594231, -1100.4251190754821, -7.278681089101213], [-271.815969077903, 559.6580465940733, -32.46047482791194], [1.9622899599665666, -57.173814538844006, 308.7233197812385]];
const Y_FROM_LINRGB = [0.2126, 0.7152, 0.0722];
const CRITICAL_PLANES = Array.from({length: 255}, (_, i) => linearize(i + 0.5));
const LAB_EPSILON = 216 / 24389;
const LAB_KAPPA = 24389 / 27;
const TWO_PI = 2 * Math.PI;

function linearize(byte) {
    const n = byte / 255;
    return (n <= 0.040449936 ? n / 12.92 : Math.pow((n + 0.055) / 1.055, 2.4)) * 100;
}

function delinearize(linear) {
    const n = linear / 100;
    return 255 * (n <= 0.0031308 ? n * 12.92 : 1.055 * Math.pow(n, 1 / 2.4) - 0.055);
}

function toByte(linear) {
    return Math.min(255, Math.max(0, Math.round(delinearize(linear))));
}

function mul(v, m) {
    return [0, 1, 2].map(i => v[0] * m[i][0] + v[1] * m[i][1] + v[2] * m[i][2]);
}

function labF(t) {
    return t > LAB_EPSILON ? Math.cbrt(t) : (LAB_KAPPA * t + 16) / 116;
}

function labInvF(ft) {
    const cube = ft * ft * ft;
    return cube > LAB_EPSILON ? cube : (116 * ft - 16) / LAB_KAPPA;
}

const yFromLstar = lstar => 100 * labInvF((lstar + 16) / 116);
const linrgbOf = argb => [linearize(argb >> 16 & 255), linearize(argb >> 8 & 255), linearize(argb & 255)];
const argbOfLinrgb = lin => toByte(lin[0]) << 16 | toByte(lin[1]) << 8 | toByte(lin[2]);
const sanitizeDegrees = d => ((d % 360) + 360) % 360;
const sanitizeRadians = r => (r + 8 * Math.PI) % TWO_PI;

function labOf(argb) {
    const xyz = mul(linrgbOf(argb), SRGB_TO_XYZ);
    const fx = labF(xyz[0] / WHITE_POINT[0]);
    const fy = labF(xyz[1] / WHITE_POINT[1]);
    const fz = labF(xyz[2] / WHITE_POINT[2]);
    return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

function argbOfLab(lab) {
    const fy = (lab[0] + 16) / 116;
    const xyz = [labInvF(lab[1] / 500 + fy) * WHITE_POINT[0], labInvF(fy) * WHITE_POINT[1], labInvF(fy - lab[2] / 200) * WHITE_POINT[2]];
    return argbOfLinrgb(mul(xyz, XYZ_TO_SRGB));
}

const VIEW = (() => {
    const adaptingLuminance = 200 / Math.PI * yFromLstar(50) / 100;
    const surround = 2;
    const f = 0.8 + surround / 10;
    const c = 0.59 + (0.69 - 0.59) * (f - 0.9) * 10;
    const rgbW = mul(WHITE_POINT, XYZ_TO_CAM16);
    const d = Math.min(1, Math.max(0, f * (1 - 1 / 3.6 * Math.exp((-adaptingLuminance - 42) / 92))));
    const rgbD = rgbW.map(w => d * (100 / w) + 1 - d);
    const k = 1 / (5 * adaptingLuminance + 1);
    const k4 = k * k * k * k;
    const fl = k4 * adaptingLuminance + 0.1 * (1 - k4) * (1 - k4) * Math.cbrt(5 * adaptingLuminance);
    const n = yFromLstar(50) / WHITE_POINT[1];
    const nbb = 0.725 / Math.pow(n, 0.2);
    const rgbA = rgbW.map((w, i) => {
        const factor = Math.pow(fl * rgbD[i] * w / 100, 0.42);
        return 400 * factor / (factor + 27.13);
    });
    return {
        n, nbb, c, fl, rgbD,
        nc: f,
        z: 1.48 + Math.sqrt(n),
        aw: (40 * rgbA[0] + 20 * rgbA[1] + rgbA[2]) / 20 * nbb
    };
})();

function adapt(component) {
    const factor = Math.pow(Math.abs(component), 0.42);
    return Math.sign(component) * 400 * factor / (factor + 27.13);
}

function unadapt(adapted) {
    const abs = Math.abs(adapted);
    return Math.sign(adapted) * Math.pow(Math.max(0, 27.13 * abs / (400 - abs)), 1 / 0.42);
}

function hueChromaOf(argb) {
    const rgb = mul(mul(linrgbOf(argb), SRGB_TO_XYZ), XYZ_TO_CAM16);
    const [r, g, b] = rgb.map((v, i) => adapt(VIEW.fl * VIEW.rgbD[i] * v / 100));
    const a = (11 * r - 12 * g + b) / 11;
    const bb = (r + g - 2 * b) / 9;
    const hue = sanitizeDegrees(Math.atan2(bb, a) * 180 / Math.PI);
    const eHue = 0.25 * (Math.cos(hue * Math.PI / 180 + 2) + 3.8);
    const u = (20 * r + 20 * g + 21 * b) / 20;
    const j = 100 * Math.pow((40 * r + 20 * g + b) / 20 * VIEW.nbb / VIEW.aw, VIEW.c * VIEW.z);
    const t = 50000 / 13 * eHue * VIEW.nc * VIEW.nbb * Math.hypot(a, bb) / (u + 0.305);
    const alpha = Math.pow(t, 0.9) * Math.pow(1.64 - Math.pow(0.29, VIEW.n), 0.73);
    return {hue, chroma: alpha * Math.sqrt(j / 100)};
}

function argbByJ(hueRadians, chroma, y) {
    const tInnerCoeff = 1 / Math.pow(1.64 - Math.pow(0.29, VIEW.n), 0.73);
    const p1 = 0.25 * (Math.cos(hueRadians + 2) + 3.8) * (50000 / 13) * VIEW.nc * VIEW.nbb;
    const hSin = Math.sin(hueRadians);
    const hCos = Math.cos(hueRadians);
    let j = Math.sqrt(y) * 11;
    for (let round = 0; round < 5; round++) {
        const jn = j / 100;
        const alpha = chroma === 0 || j === 0 ? 0 : chroma / Math.sqrt(jn);
        const t = Math.pow(alpha * tInnerCoeff, 1 / 0.9);
        const p2 = VIEW.aw * Math.pow(jn, 1 / VIEW.c / VIEW.z) / VIEW.nbb;
        const gamma = 23 * (p2 + 0.305) * t / (23 * p1 + 11 * t * hCos + 108 * t * hSin);
        const a = gamma * hCos;
        const b = gamma * hSin;
        const scaled = [(460 * p2 + 451 * a + 288 * b) / 1403, (460 * p2 - 891 * a - 261 * b) / 1403, (460 * p2 - 220 * a - 6300 * b) / 1403].map(unadapt);
        const lin = mul(scaled, LINRGB_FROM_SCALED_DISCOUNT);
        if (lin.some(v => v < 0))
            return -1;
        const fnj = Y_FROM_LINRGB[0] * lin[0] + Y_FROM_LINRGB[1] * lin[1] + Y_FROM_LINRGB[2] * lin[2];
        if (fnj <= 0)
            return -1;
        if (round === 4 || Math.abs(fnj - y) < 0.002)
            return lin.some(v => v > 100.01) ? -1 : argbOfLinrgb(lin);
        j -= (fnj - y) * j / (2 * fnj);
    }
    return -1;
}

const isBounded = v => v >= 0 && v <= 100;
const cyclic = (a, b, c) => sanitizeRadians(b - a) < sanitizeRadians(c - a);

function hueOfLinrgb(lin) {
    const [r, g, b] = mul(lin, SCALED_DISCOUNT_FROM_LINRGB).map(adapt);
    return Math.atan2((r + g - 2 * b) / 9, (11 * r - 12 * g + b) / 11);
}

function nthVertex(y, n) {
    const coordA = n % 4 <= 1 ? 0 : 100;
    const coordB = n % 2 === 0 ? 0 : 100;
    const [kr, kg, kb] = Y_FROM_LINRGB;
    let vertex;
    if (n < 4)
        vertex = [(y - coordA * kg - coordB * kb) / kr, coordA, coordB];
    else if (n < 8)
        vertex = [coordB, (y - coordB * kr - coordA * kb) / kg, coordA];
    else
        vertex = [coordA, coordB, (y - coordA * kr - coordB * kg) / kb];
    return isBounded(vertex[n < 4 ? 0 : n < 8 ? 1 : 2]) ? vertex : null;
}

function bisectToSegment(y, targetHue) {
    let left = null;
    let right = null;
    let leftHue = 0;
    let rightHue = 0;
    let uncut = true;
    for (let n = 0; n < 12; n++) {
        const mid = nthVertex(y, n);
        if (!mid)
            continue;
        const midHue = hueOfLinrgb(mid);
        if (!left) {
            left = right = mid;
            leftHue = rightHue = midHue;
        } else if (uncut || cyclic(leftHue, midHue, rightHue)) {
            uncut = false;
            if (cyclic(leftHue, targetHue, midHue)) {
                right = mid;
                rightHue = midHue;
            } else {
                left = mid;
                leftHue = midHue;
            }
        }
    }
    return [left, right];
}

function argbAtLimit(y, targetHue) {
    let [left, right] = bisectToSegment(y, targetHue);
    let leftHue = hueOfLinrgb(left);
    for (let axis = 0; axis < 3; axis++) {
        if (left[axis] === right[axis])
            continue;
        const rising = left[axis] < right[axis];
        let lPlane = (rising ? Math.floor : Math.ceil)(delinearize(left[axis]) - 0.5);
        let rPlane = (rising ? Math.ceil : Math.floor)(delinearize(right[axis]) - 0.5);
        for (let i = 0; i < 8 && Math.abs(rPlane - lPlane) > 1; i++) {
            const mPlane = Math.floor((lPlane + rPlane) / 2);
            const t = (CRITICAL_PLANES[mPlane] - left[axis]) / (right[axis] - left[axis]);
            const mid = left.map((v, k) => v + (right[k] - v) * t);
            const midHue = hueOfLinrgb(mid);
            if (cyclic(leftHue, targetHue, midHue)) {
                right = mid;
                rPlane = mPlane;
            } else {
                left = mid;
                leftHue = midHue;
                lPlane = mPlane;
            }
        }
    }
    return argbOfLinrgb(left.map((v, k) => (v + right[k]) / 2));
}

const MIN_SOLVABLE = 0.0001;
const MAX_SOLVABLE_TONE = 99.9999;

function solveHct(hue, chroma, tone) {
    if (chroma < MIN_SOLVABLE || tone < MIN_SOLVABLE || tone > MAX_SOLVABLE_TONE) {
        const gray = toByte(yFromLstar(tone));
        return gray << 16 | gray << 8 | gray;
    }
    const radians = sanitizeDegrees(hue) * Math.PI / 180;
    const y = yFromLstar(tone);
    const exact = argbByJ(radians, chroma, y);
    return exact >= 0 ? exact : argbAtLimit(y, radians);
}

const WU_SIDE = 33;
const WU_INDEX_SHIFT = 3;
const WU_LAST = 32;
const CLUSTER_COLORS = 128;

const wuIndex = (r, g, b) => (r * WU_SIDE + g) * WU_SIDE + b;

function wuVolume(box, m) {
    return m[wuIndex(box.r1, box.g1, box.b1)] - m[wuIndex(box.r1, box.g1, box.b0)] - m[wuIndex(box.r1, box.g0, box.b1)] + m[wuIndex(box.r1, box.g0, box.b0)]
        - m[wuIndex(box.r0, box.g1, box.b1)] + m[wuIndex(box.r0, box.g1, box.b0)] + m[wuIndex(box.r0, box.g0, box.b1)] - m[wuIndex(box.r0, box.g0, box.b0)];
}

function wuBottom(box, axis, m) {
    const at = (r, g, b) => m[wuIndex(r, g, b)];
    if (axis === 0)
        return -at(box.r0, box.g1, box.b1) + at(box.r0, box.g1, box.b0) + at(box.r0, box.g0, box.b1) - at(box.r0, box.g0, box.b0);
    if (axis === 1)
        return -at(box.r1, box.g0, box.b1) + at(box.r1, box.g0, box.b0) + at(box.r0, box.g0, box.b1) - at(box.r0, box.g0, box.b0);
    return -at(box.r1, box.g1, box.b0) + at(box.r1, box.g0, box.b0) + at(box.r0, box.g1, box.b0) - at(box.r0, box.g0, box.b0);
}

function wuTop(box, axis, p, m) {
    const at = (r, g, b) => m[wuIndex(r, g, b)];
    if (axis === 0)
        return at(p, box.g1, box.b1) - at(p, box.g1, box.b0) - at(p, box.g0, box.b1) + at(p, box.g0, box.b0);
    if (axis === 1)
        return at(box.r1, p, box.b1) - at(box.r1, p, box.b0) - at(box.r0, p, box.b1) + at(box.r0, p, box.b0);
    return at(box.r1, box.g1, p) - at(box.r1, box.g0, p) - at(box.r0, box.g1, p) + at(box.r0, box.g0, p);
}

function wuVariance(box, h) {
    const dr = wuVolume(box, h.mr);
    const dg = wuVolume(box, h.mg);
    const db = wuVolume(box, h.mb);
    return wuVolume(box, h.m2) - (dr * dr + dg * dg + db * db) / wuVolume(box, h.w);
}

function wuMaximize(box, axis, first, last, whole, h) {
    const moments = [h.mr, h.mg, h.mb];
    const bottom = moments.map(m => wuBottom(box, axis, m));
    const bottomW = wuBottom(box, axis, h.w);
    let max = 0;
    let cut = -1;
    for (let i = first; i < last; i++) {
        const half = moments.map((m, k) => bottom[k] + wuTop(box, axis, i, m));
        const halfW = bottomW + wuTop(box, axis, i, h.w);
        if (halfW === 0)
            continue;
        const rest = half.map((v, k) => whole[k] - v);
        const restW = whole[3] - halfW;
        if (restW === 0)
            continue;
        const temp = (half[0] * half[0] + half[1] * half[1] + half[2] * half[2]) / halfW + (rest[0] * rest[0] + rest[1] * rest[1] + rest[2] * rest[2]) / restW;
        if (temp > max) {
            max = temp;
            cut = i;
        }
    }
    return {cut, max};
}

function wuCut(one, two, h) {
    const whole = [wuVolume(one, h.mr), wuVolume(one, h.mg), wuVolume(one, h.mb), wuVolume(one, h.w)];
    const lows = [one.r0, one.g0, one.b0];
    const highs = [one.r1, one.g1, one.b1];
    const results = [0, 1, 2].map(axis => wuMaximize(one, axis, lows[axis] + 1, highs[axis], whole, h));
    let axis = 2;
    if (results[0].max >= results[1].max && results[0].max >= results[2].max)
        axis = 0;
    else if (results[1].max >= results[0].max && results[1].max >= results[2].max)
        axis = 1;
    const cut = results[axis].cut;
    if (cut < 0)
        return false;
    two.r1 = one.r1;
    two.g1 = one.g1;
    two.b1 = one.b1;
    const key = ["r", "g", "b"][axis];
    two.r0 = one.r0;
    two.g0 = one.g0;
    two.b0 = one.b0;
    one[key + "1"] = two[key + "0"] = cut;
    one.vol = (one.r1 - one.r0) * (one.g1 - one.g0) * (one.b1 - one.b0);
    two.vol = (two.r1 - two.r0) * (two.g1 - two.g0) * (two.b1 - two.b0);
    return true;
}

function wuHistogram(pixels) {
    const size = WU_SIDE * WU_SIDE * WU_SIDE;
    const h = {w: new Float64Array(size), mr: new Float64Array(size), mg: new Float64Array(size), mb: new Float64Array(size), m2: new Float64Array(size)};
    for (const argb of pixels) {
        const r = argb >> 16 & 255;
        const g = argb >> 8 & 255;
        const b = argb & 255;
        const i = wuIndex((r >> WU_INDEX_SHIFT) + 1, (g >> WU_INDEX_SHIFT) + 1, (b >> WU_INDEX_SHIFT) + 1);
        h.w[i]++;
        h.mr[i] += r;
        h.mg[i] += g;
        h.mb[i] += b;
        h.m2[i] += r * r + g * g + b * b;
    }
    for (const m of [h.w, h.mr, h.mg, h.mb, h.m2]) {
        for (let r = 1; r <= WU_LAST; r++) {
            const area = new Float64Array(WU_SIDE);
            for (let g = 1; g <= WU_LAST; g++) {
                let line = 0;
                for (let b = 1; b <= WU_LAST; b++) {
                    const i = wuIndex(r, g, b);
                    line += m[i];
                    area[b] += line;
                    m[i] = m[wuIndex(r - 1, g, b)] + area[b];
                }
            }
        }
    }
    return h;
}

function wuColors(pixels) {
    const h = wuHistogram(pixels);
    const boxes = [{r0: 0, g0: 0, b0: 0, r1: WU_LAST, g1: WU_LAST, b1: WU_LAST, vol: 0}];
    const variances = new Float64Array(CLUSTER_COLORS);
    let count = CLUSTER_COLORS;
    let next = 0;
    for (let i = 1; i < CLUSTER_COLORS; i++) {
        boxes[i] = {r0: 0, g0: 0, b0: 0, r1: 0, g1: 0, b1: 0, vol: 0};
        if (wuCut(boxes[next], boxes[i], h)) {
            variances[next] = boxes[next].vol > 1 ? wuVariance(boxes[next], h) : 0;
            variances[i] = boxes[i].vol > 1 ? wuVariance(boxes[i], h) : 0;
        } else {
            variances[next] = 0;
            i--;
        }
        next = 0;
        let top = variances[0];
        for (let j = 1; j <= i; j++) {
            if (variances[j] > top) {
                top = variances[j];
                next = j;
            }
        }
        if (top <= 0) {
            count = i + 1;
            break;
        }
    }
    const colors = new Set();
    for (const box of boxes.slice(0, count)) {
        const weight = wuVolume(box, h.w);
        if (weight > 0)
            colors.add(Math.round(wuVolume(box, h.mr) / weight) << 16 | Math.round(wuVolume(box, h.mg) / weight) << 8 | Math.round(wuVolume(box, h.mb) / weight));
    }
    return Array.from(colors);
}

const KOTLIN_RANDOM_SEED = 0x42688;
const KMEANS_MAX_ITERATIONS = 10;
const KMEANS_MIN_MOVEMENT = 3;
const XORWOW_ADDEND_STEP = 362437;

function kotlinRandom(seed) {
    let x = seed | 0;
    let y = seed >> 31;
    let z = 0;
    let w = 0;
    let v = ~seed;
    let addend = (x << 10) ^ (y >>> 4);
    const nextInt = () => {
        let t = x ^ (x >>> 2);
        x = y;
        y = z;
        z = w;
        const v0 = v;
        w = v0;
        t = (t ^ (t << 1)) ^ v0 ^ (v0 << 4);
        v = t;
        addend = (addend + XORWOW_ADDEND_STEP) | 0;
        return (t + addend) | 0;
    };
    for (let i = 0; i < 64; i++)
        nextInt();
    return bound => {
        if ((bound & -bound) === bound) {
            const bitCount = 31 - Math.clz32(bound);
            return bitCount === 0 ? 0 : nextInt() >>> (32 - bitCount);
        }
        for (;;) {
            const bits = nextInt() >>> 1;
            const value = bits % bound;
            if (((bits - value + (bound - 1)) | 0) >= 0)
                return value;
        }
    };
}

const labDistance = (a, b) => (a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2]);

function refineClusters(pixels, startColors) {
    const counts = new Map();
    for (const argb of pixels)
        counts.set(argb, (counts.get(argb) || 0) + 1);
    const argbs = Array.from(counts.keys());
    const points = argbs.map(labOf);
    const clusterCount = Math.min(CLUSTER_COLORS, argbs.length, startColors.length);
    const clusters = startColors.slice(0, clusterCount).map(labOf);
    const random = kotlinRandom(KOTLIN_RANDOM_SEED);
    const assignment = points.map(() => random(clusterCount));
    for (let iteration = 0; iteration < KMEANS_MAX_ITERATIONS; iteration++) {
        const between = clusters.map(a => clusters.map(b => labDistance(a, b)));
        let moved = 0;
        points.forEach((point, p) => {
            const previous = assignment[p];
            const previousDistance = labDistance(point, clusters[previous]);
            let best = previousDistance;
            let bestIndex = -1;
            for (let j = 0; j < clusterCount; j++) {
                if (between[previous][j] >= 4 * previousDistance)
                    continue;
                const distance = labDistance(point, clusters[j]);
                if (distance < best) {
                    best = distance;
                    bestIndex = j;
                }
            }
            if (bestIndex !== -1 && Math.abs(Math.sqrt(best) - Math.sqrt(previousDistance)) > KMEANS_MIN_MOVEMENT) {
                moved++;
                assignment[p] = bestIndex;
            }
        });
        if (moved === 0 && iteration !== 0)
            break;
        const sums = clusters.map(() => [0, 0, 0, 0]);
        points.forEach((point, p) => {
            const n = counts.get(argbs[p]);
            const sum = sums[assignment[p]];
            sum[0] += point[0] * n;
            sum[1] += point[1] * n;
            sum[2] += point[2] * n;
            sum[3] += n;
        });
        sums.forEach((sum, i) => {
            clusters[i] = sum[3] === 0 ? [0, 0, 0] : [sum[0] / sum[3], sum[1] / sum[3], sum[2] / sum[3]];
        });
    }
    const population = new Map();
    const sizes = new Array(clusterCount).fill(0);
    argbs.forEach((argb, p) => {
        sizes[assignment[p]] += counts.get(argb);
    });
    clusters.forEach((lab, i) => {
        const argb = argbOfLab(lab);
        if (sizes[i] > 0 && !population.has(argb))
            population.set(argb, sizes[i]);
    });
    return population;
}

const HUE_COUNT = 360;
const HUE_SMOOTHING_BEFORE = 14;
const HUE_SMOOTHING_AFTER = 16;
const TARGET_CHROMA = 48;
const WEIGHT_PROPORTION = 0.7;
const WEIGHT_CHROMA_ABOVE = 0.3;
const WEIGHT_CHROMA_BELOW = 0.1;
const CUTOFF_CHROMA = 5;
const CUTOFF_PROPORTION = 0.01;
const PERCENT = 100;

function bestColor(population) {
    const entries = Array.from(population, ([argb, count]) => ({argb, count, cam: hueChromaOf(argb)}));
    const huePopulation = new Float64Array(HUE_COUNT);
    let total = 0;
    for (const e of entries) {
        huePopulation[Math.floor(e.cam.hue)] += e.count;
        total += e.count;
    }
    const excited = new Float64Array(HUE_COUNT);
    for (let hue = 0; hue < HUE_COUNT; hue++) {
        const proportion = huePopulation[hue] / total;
        for (let i = hue - HUE_SMOOTHING_BEFORE; i < hue + HUE_SMOOTHING_AFTER; i++)
            excited[(i % HUE_COUNT + HUE_COUNT) % HUE_COUNT] += proportion;
    }
    let best = -1;
    let bestScore = -Infinity;
    for (const e of entries) {
        const proportion = excited[(Math.round(e.cam.hue) % HUE_COUNT + HUE_COUNT) % HUE_COUNT];
        if (e.cam.chroma < CUTOFF_CHROMA || proportion <= CUTOFF_PROPORTION)
            continue;
        const chromaWeight = e.cam.chroma < TARGET_CHROMA ? WEIGHT_CHROMA_BELOW : WEIGHT_CHROMA_ABOVE;
        const score = proportion * PERCENT * WEIGHT_PROPORTION + (e.cam.chroma - TARGET_CHROMA) * chromaWeight;
        if (score > bestScore) {
            bestScore = score;
            best = e.argb;
        }
    }
    return best;
}

function hexOf(argb) {
    return "#" + (argb | 0x1000000).toString(16).slice(1).toUpperCase();
}

const PPM_HEADER_TOKENS = 4;

function pixelsOfPpm(text) {
    const values = text.split(/\s+/).filter(v => v.length > 0).slice(PPM_HEADER_TOKENS).map(Number);
    const pixels = [];
    for (let i = 0; i + 2 < values.length; i += 3)
        pixels.push(values[i] << 16 | values[i + 1] << 8 | values[i + 2]);
    return pixels;
}

// Mirrors themeColorOrNull: pixels are 0xRRGGBB ints of the picture at 64 px; "" when no color qualifies.
function seedOf(pixels) {
    if (pixels.length === 0)
        return "";
    const best = bestColor(refineClusters(pixels, wuColors(pixels)));
    return best < 0 ? "" : hexOf(best);
}

const PRIMARY_CHROMA = 36;
const SECONDARY_CHROMA = 16;
const NEUTRAL_CHROMA = 6;
const SHADE_TONE = 4;

// Tonal-spot roles ArtPalette.kt reads from dynamicColorScheme: secondaryContainer,
// onSecondaryContainer, primary and the dark surfaceContainerLowest.
function palette(seed, dark) {
    const hue = hueChromaOf(parseInt(seed.slice(1), 16)).hue;
    const role = (chroma, tone) => hexOf(solveHct(hue, chroma, tone));
    return {
        "fill": role(SECONDARY_CHROMA, dark ? 30 : 90),
        "content": role(SECONDARY_CHROMA, dark ? 90 : 10),
        "accent": role(PRIMARY_CHROMA, dark ? 80 : 40),
        "shade": role(NEUTRAL_CHROMA, SHADE_TONE)
    };
}
