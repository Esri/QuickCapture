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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

import "HelpersLib.js" as HelpersLib


Button {
    id: button
    
    property ButtonGroup buttonGroup

    property int layerId
    property var template
    property string description
    property var options
    property Symbol symbol
    property color textColor: "black"

    property color downTextColor: textColor
    property color downBorderColor: textColor//"darkgrey"

    property color backgroundColor: symbol.color
    property color borderColor: symbol.outlineColor
    property real borderWidth: symbol.outlineWidth * symbol.scaleFactor

    property bool requiresTag: false
    property bool tagAvailable: false

    //--------------------------------------------------------------------------

    signal addFeature(var button)

    //--------------------------------------------------------------------------

    enabled: !requiresTag || (requiresTag && tagAvailable)

    //--------------------------------------------------------------------------

    Component.onCompleted: {

        var exclusive = true;
        if (typeof options.exclusive === "boolean") {
            exclusive = options.exclusive;
        }

        if (buttonGroup && exclusive) {
            buttonGroup.addButton(this);
        }

        if (options.color) {
            backgroundColor = options.color;
        }

        if (options.outlineColor) {
            borderColor = options.outlineColor;
        }

        if (options.outlineWidth) {
            borderWidth = options.outlineWidth * symbol.scaleFactor;
        }

        textColor = HelpersLib.contrastColor(background.color);

        if (options.textColor) {
            textColor = options.textColor;
        }

        if (options.textColor) {
            textColor = options.textColor;
        }
    }

    //--------------------------------------------------------------------------

    text: template.name

    font {
        pointSize: 14 * (control.down ? 1.2 : 1)
        bold: control.down
    }
    
    //--------------------------------------------------------------------------

    background: Rectangle {
        implicitWidth: 100 * AppFramework.displayScaleFactor
        implicitHeight: 40 * AppFramework.displayScaleFactor

        color: control.down ? Qt.lighter(backgroundColor, 1.2) : backgroundColor
        opacity: enabled ? 1 : 0.3
        border {
            color: control.down ? downBorderColor : borderColor
            width: borderWidth * control.down ? 1 : 2
        }

        radius: 5 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------
}
