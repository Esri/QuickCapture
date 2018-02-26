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


Item {
    property var layerInfo
    property int layerId
    property string name
    property var options
    property alias symbol: symbol
    property alias symbolInfo: symbol.symbolInfo
    property alias textColor: nameText.color
    property alias collapsed: groupIndicator.collapsed
    property alias buttonGroup: buttonGroup

    //--------------------------------------------------------------------------

    implicitHeight: nameText.paintedHeight

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        layerId = layerInfo.id;

        if (layerInfo.drawingInfo.renderer.type === "simple") {
            symbol.symbolInfo = layerInfo.drawingInfo.renderer.symbol;
        }
    }

    //--------------------------------------------------------------------------

    ButtonGroup {
        id: buttonGroup
    }

    //--------------------------------------------------------------------------

    GroupIndicator {
        id: groupIndicator

        height: parent.height
        width: height

        color: textColor
    }

    //--------------------------------------------------------------------------

    Text {
        id: nameText
        
        anchors {
            left: parent.left
            right: parent.right
        }
        
        text: name
        font {
            pointSize: 20
            bold: true
        }
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: Text.AlignHCenter
    }
    
    //--------------------------------------------------------------------------

    Symbol {
        id: symbol
    }

    //--------------------------------------------------------------------------

    function findUniqueValueInfo(value) {
        if (layerInfo.drawingInfo.renderer.type !== "uniqueValue") {
            console.error("Not a uniqueValue renderer:", layerInfo.drawingInfo.renderer.type);
            return;
        }

        var uniqueValueInfo;

        var uniqueValueInfos = layerInfo.drawingInfo.renderer.uniqueValueInfos;
        for (var i = 0; i < uniqueValueInfos.length; i++) {
            if (uniqueValueInfos[i].value == value) {
                uniqueValueInfo = uniqueValueInfos[i];
                break;
            }
        }

        if (!uniqueValueInfo) {
            console.warn("No uniquevalue match for value:", JSON.stringify(value));
        }

        return uniqueValueInfo;
    }

    //--------------------------------------------------------------------------
}
