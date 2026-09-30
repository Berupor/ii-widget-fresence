.pragma library

const thumbSide = 32;
const saturationBoost = 1.25;
const bmpHeaderBytes = 54;
const bmpBitsPerPixel = 24;
const bmpPixelsPerMeter = 2835;
const base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
const base64UrlAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

function bytesOf(base64Url) {
    const bytes = [];
    let buffer = 0;
    let bits = 0;
    for (const ch of base64Url) {
        const value = base64UrlAlphabet.indexOf(ch);
        if (value < 0)
            return null;
        buffer = (buffer << 6) | value;
        bits += 6;
        if (bits >= 8) {
            bits -= 8;
            bytes.push((buffer >> bits) & 0xff);
        }
    }
    return bytes;
}

function base64Of(bytes) {
    let out = "";
    for (let i = 0; i < bytes.length; i += 3) {
        const chunk = (bytes[i] << 16) | ((bytes[i + 1] ?? 0) << 8) | (bytes[i + 2] ?? 0);
        out += base64Alphabet[(chunk >> 18) & 63] + base64Alphabet[(chunk >> 12) & 63];
        out += i + 1 < bytes.length ? base64Alphabet[(chunk >> 6) & 63] : "=";
        out += i + 2 < bytes.length ? base64Alphabet[chunk & 63] : "=";
    }
    return out;
}

function channelByte(v) {
    return Math.trunc(Math.max(0, 255 * Math.min(1, v)));
}

function aspectRatio(u) {
    const hasAlpha = (u[2] & 0x80) !== 0;
    const isLandscape = (u[4] & 0x80) !== 0;
    const lx = isLandscape ? (hasAlpha ? 5 : 7) : u[3] & 7;
    const ly = isLandscape ? u[3] & 7 : hasAlpha ? 5 : 7;
    return lx / ly;
}

// Same decoder as app/shared thumbhash/ThumbHash.kt: RGBA rows of width x height, 32 px on the long side
function decode(hash) {
    const u = hash;
    if (u.length < 5)
        return null;
    const header24 = u[0] | (u[1] << 8) | (u[2] << 16);
    const header16 = u[3] | (u[4] << 8);
    const lDc = (header24 & 63) / 63;
    const pDc = ((header24 >> 6) & 63) / 31.5 - 1;
    const qDc = ((header24 >> 12) & 63) / 31.5 - 1;
    const lScale = ((header24 >> 18) & 31) / 31;
    const hasAlpha = header24 >> 23 !== 0;
    const pScale = ((header16 >> 3) & 63) / 63;
    const qScale = ((header16 >> 9) & 63) / 63;
    const isLandscape = header16 >> 15 !== 0;
    const lx = Math.max(3, isLandscape ? (hasAlpha ? 5 : 7) : header16 & 7);
    const ly = Math.max(3, isLandscape ? header16 & 7 : hasAlpha ? 5 : 7);
    const aDc = hasAlpha ? (u[5] & 15) / 15 : 1;
    const aScale = (u[5] >> 4) / 15;
    const acStart = hasAlpha ? 6 : 5;
    let acIndex = 0;

    function channel(nx, ny, scale) {
        const ac = [];
        for (let cy = 0; cy < ny; cy++) {
            for (let cx = cy > 0 ? 0 : 1; cx * ny < nx * (ny - cy); cx++) {
                const nibble = ((u[acStart + (acIndex >> 1)] ?? 0) >> ((acIndex & 1) << 2)) & 15;
                ac.push((nibble / 7.5 - 1) * scale);
                acIndex++;
            }
        }
        return ac;
    }

    const lAc = channel(lx, ly, lScale);
    const pAc = channel(3, 3, pScale * saturationBoost);
    const qAc = channel(3, 3, qScale * saturationBoost);
    const aAc = hasAlpha ? channel(5, 5, aScale) : [];

    const ratio = aspectRatio(u);
    const w = Math.round(ratio > 1 ? thumbSide : thumbSide * ratio);
    const h = Math.round(ratio > 1 ? thumbSide / ratio : thumbSide);
    if (w < 1 || h < 1)
        return null;
    const rgba = new Array(w * h * 4);
    const fx = new Array(Math.max(lx, hasAlpha ? 5 : 3));
    const fy = new Array(Math.max(ly, hasAlpha ? 5 : 3));
    let i = 0;
    for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
            let l = lDc;
            let p = pDc;
            let q = qDc;
            let a = aDc;
            for (let cx = 0; cx < fx.length; cx++)
                fx[cx] = Math.cos(Math.PI / w * (x + 0.5) * cx);
            for (let cy = 0; cy < fy.length; cy++)
                fy[cy] = Math.cos(Math.PI / h * (y + 0.5) * cy);
            let j = 0;
            for (let cy = 0; cy < ly; cy++) {
                const fy2 = fy[cy] * 2;
                for (let cx = cy > 0 ? 0 : 1; cx * ly < lx * (ly - cy); cx++)
                    l += lAc[j++] * fx[cx] * fy2;
            }
            j = 0;
            for (let cy = 0; cy < 3; cy++) {
                const fy2 = fy[cy] * 2;
                for (let cx = cy > 0 ? 0 : 1; cx < 3 - cy; cx++) {
                    const f = fx[cx] * fy2;
                    p += pAc[j] * f;
                    q += qAc[j] * f;
                    j++;
                }
            }
            if (hasAlpha) {
                j = 0;
                for (let cy = 0; cy < 5; cy++) {
                    const fy2 = fy[cy] * 2;
                    for (let cx = cy > 0 ? 0 : 1; cx < 5 - cy; cx++)
                        a += aAc[j++] * fx[cx] * fy2;
                }
            }
            const b = l - 2 / 3 * p;
            const r = (3 * l - b + q) / 2;
            const g = r - q;
            rgba[i++] = channelByte(r);
            rgba[i++] = channelByte(g);
            rgba[i++] = channelByte(b);
            rgba[i++] = channelByte(a);
        }
    }
    return {
        "width": w,
        "height": h,
        "rgba": rgba
    };
}

function le32(v) {
    return [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];
}

// Opaque 24-bit BMP, bottom-up rows padded to 4 bytes; the clip is opaque so alpha is dropped
function bmpOf(image) {
    const rowBytes = Math.ceil(image.width * 3 / 4) * 4;
    const pixelBytes = rowBytes * image.height;
    const bytes = [0x42, 0x4d].concat(le32(bmpHeaderBytes + pixelBytes), le32(0), le32(bmpHeaderBytes));
    bytes.push(...le32(40), ...le32(image.width), ...le32(image.height), 1, 0, bmpBitsPerPixel, 0);
    bytes.push(...le32(0), ...le32(pixelBytes), ...le32(bmpPixelsPerMeter), ...le32(bmpPixelsPerMeter), ...le32(0), ...le32(0));
    for (let y = image.height - 1; y >= 0; y--) {
        for (let x = 0; x < image.width; x++) {
            const at = (y * image.width + x) * 4;
            bytes.push(image.rgba[at + 2], image.rgba[at + 1], image.rgba[at]);
        }
        for (let pad = image.width * 3; pad < rowBytes; pad++)
            bytes.push(0);
    }
    return bytes;
}

/// Data URL of the blurred preview for a base64url thumbhash, or "" when it does not decode
function dataUrl(hash) {
    const bytes = bytesOf(hash ?? "");
    const image = bytes ? decode(bytes) : null;
    return image ? "data:image/bmp;base64," + base64Of(bmpOf(image)) : "";
}
