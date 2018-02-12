/* Copyright 2018 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

.pragma library

//------------------------------------------------------------------------------

function hex2rgba(color, factor) {
    var hex = Qt.lighter(color, 1).toString();

    var a = 255;
    var r = 128;
    var g = 128;
    var b = 128;

    var aOffset = 0;
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) {
        result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        if (result) {
            aOffset  = 1;
            a = parseInt(result[1], 16);
        }
    }

    if (result) {
        r = parseInt(result[1 + aOffset], 16);
        g = parseInt(result[2 + aOffset], 16);
        b = parseInt(result[3 + aOffset], 16);
    }

    if (!factor) {
        factor = 1;
    }

    return {
        a: a / factor,
        r: r / factor,
        g: g / factor,
        b: b / factor
    }
}

//------------------------------------------------------------------------------

function contrastColor(color) {

    function contrast(color) {
        var rgb = hex2rgba(color);
        return (Math.round(rgb.r * 299) + Math.round(rgb.g * 587) + Math.round(rgb.b * 114)) / 1000;
    }

    return (contrast(color) >= 128) ? 'black' : 'white';
}

//------------------------------------------------------------------------------
// Precise method, which guarantees v = v1 when s = 1

function lerp(v0, v1, s) {
    return (1 - s) * v0 + s * v1;
}

//------------------------------------------------------------------------------

function interpolateColor(color1, color2, s) {
    if (s <= 0) {
        return color1;
    } else if (s >= 1) {
        return color2;
    }

    var rgb1 = hex2rgba(color1, 255);
    var rgb2 = hex2rgba(color2, 255);

    var r = lerp(rgb1.r, rgb2.r, s);
    var g = lerp(rgb1.g, rgb2.g, s);
    var b = lerp(rgb1.b, rgb2.b, s);
    var a = lerp(rgb1.a, rgb2.a, s);

    return Qt.rgba(r, g, b, a);
}

//------------------------------------------------------------------------------

function interpolateColors(colors, s) {
    if (!Array.isArray(colors)) {
        console.error("Not an array:", colors);
        return;
    }

    var iMax = colors.length;

    if (s <= 0) {
        return colors[0];
    } else if (s >= 1) {
        return colors[iMax - 1];
    }

    var i = Math.floor(s * iMax);

    return interpolateColor(colors[i], colors[i + 1], s - i / (iMax-1));
}

//------------------------------------------------------------------------------

function interpolateArray(array, s, minValue, maxValue) {
    if (!Array.isArray(array)) {
        console.error("Not an array:", array);
        return;
    }

    var iMax = array.length;

    if (s <= 0) {
        return minValue ? minValue : array[0];
    } else if (s >= 1) {
        return maxValue ? maxValue: array[iMax - 1];
    }

    var i = Math.floor(s * iMax);

    return array[i];
}

//------------------------------------------------------------------------------

