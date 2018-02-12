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

import QtQuick 2.9

import ArcGIS.AppFramework 1.0

//------------------------------------------------------------------------------

Item {
    property var symbolInfo

    property string type
    property real angle
    property string style
    property real size
    property color color: "lightgrey"

    property string outlineType
    property string outlineStyle
    property color outlineColor: "darkgrey"
    property real outlineWidth: 4 / 3

    property real imageWidth
    property real imageHeight
    property alias imageUrl: imageObject.url

    property real scaleFactor: 0.75

    readonly property string kPictureMarkerSymbol: "esriPMS"
    readonly property string kSimpleMarkerSymbol: "esriSMS"

    //--------------------------------------------------------------------------

    onSymbolInfoChanged: {
        if (!symbolInfo) {
            return;
        }

        //console.log("symbolInfo:", JSON.stringify(symbolInfo, undefined, 2));

        type = symbolInfo.type;
        angle = symbolInfo.angle;

        switch (type) {
        case kSimpleMarkerSymbol:
            fromSimpleMarker();
            break;

        case kPictureMarkerSymbol:
            fromPictureMarker();
            break;

        default:
            console.error("Unhandled symbol type:", type);
            break;
        }
    }

    //--------------------------------------------------------------------------

    function fromSimpleMarker() {
        style = symbolInfo.style;
        size = symbolInfo.size;
        color = toColor(symbolInfo.color);

        console.log("outline:", JSON.stringify(symbolInfo.outline, undefined, 2))

        outlineType = symbolInfo.outline.type || "";
        outlineStyle = symbolInfo.outline.style || "";
        outlineWidth = symbolInfo.outline.width;
        outlineColor = toColor(symbolInfo.outline.color);
    }

    //--------------------------------------------------------------------------

    function fromPictureMarker() {
        imageWidth = symbolInfo.width;
        imageHeight = symbolInfo.height;


        if (imageObject.loadFromData(symbolInfo.imageData)) {
            console.log("image:", symbolInfo.contentType, imageObject.width, "x", imageObject.height);
        } else {
            console.log("Error loading:", symbolInfo.contentType);
        }

/*
        var imageFormat;
        switch (symbolInfo.contentType) {
        case "image/png":
            imageFormat = "PNG";
            break;

        case "image/jpeg":
            imageFormat = "JPG";
            break;

        case "image/gif":
            imageFormat = "GIF";
            break;

        default:
            console.warn("Unknown contentType:", symbolInfo.contentType);
            break;
        }

        if (imageFormat) {
            //console.log("imageFormat:", imageFormat, symbolInfo.imageData);
            if (imageObject.loadFromData(symbolInfo.imageData, imageFormat)) {
                console.log("image:", imageFormat, imageObject.width, "x", imageObject.height, imageObject.format);
            } else {
                console.log("Error loading:", imageFormat);
            }
        }
        */
    }

    //--------------------------------------------------------------------------

    function toColor(colorArray) {
        if (!colorArray) {
            return "transparent";
        }

        if (!Array.isArray(colorArray)) {
            console.error("Not a color array:", JSON.stringify(colorArray));
            return "darkgrey";
        }

        return Qt.rgba(colorArray[0] / 255,
                       colorArray[1] / 255,
                       colorArray[2] / 255,
                       colorArray[3] / 255);
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    //--------------------------------------------------------------------------
}
