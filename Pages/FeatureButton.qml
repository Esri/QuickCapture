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
import QtGraphicalEffects 1.0

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

    property int key
    property bool showKey: false

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

        if (options.captureImage) {
            captureImageIndicator.visible = true;
        }

        if (typeof options.key === "number") {
            key = options.key;
        } else if (options.key > "") {
            var keyText = options.key.trim();
            var code = Number.parseInt(keyText);
            if (isFinite(code)) {
                key = code;
            } else if (keyText > " ") {
                key = keyText.toUpperCase().charCodeAt(0);
            }
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

        Item {
            id: captureImageIndicator

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: parent.radius + parent.border.width
            }

            visible: false

            width: 20 * AppFramework.displayScaleFactor
            height: width

            Image {
                id: cameraImage

                anchors.fill: parent

                visible: false
                source: "images/camera.png"
                fillMode: Image.PreserveAspectFit
                verticalAlignment: Image.AlignBottom
                horizontalAlignment: Image.AlignRight
            }

            ColorOverlay {
                source: cameraImage
                anchors.fill: cameraImage
                color: textColor
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                leftMargin: parent.border.width + 2 * AppFramework.displayScaleFactor
                verticalCenter: parent.verticalCenter
            }

            width: keyText.paintedWidth + 4 * AppFramework.displayScaleFactor
            height: keyText.paintedHeight + 4 * AppFramework.displayScaleFactor
            opacity: 0.5

            visible: showKey && key

            color: "transparent"
            radius: 2 * AppFramework.displayScaleFactor
            border {
                color: textColor
                width: 1 * AppFramework.displayScaleFactor
            }

            Text {
                id: keyText

                anchors.centerIn: parent
                text: (key > 32 && key <= 0xFFFF) ? String.fromCharCode(key) : "0x%1".arg(key.toString(16))
            }
        }
    }

    //--------------------------------------------------------------------------

    onClicked: {
        Qt.inputMethod.hide();
    }

    //--------------------------------------------------------------------------
}
