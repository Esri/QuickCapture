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
    property var typeInfo
    property string typeId
    property string name
    property var options
    property alias symbol: symbol
    property alias symbolInfo: symbol.symbolInfo
    property alias textColor: nameText.color
    readonly property bool collapsed: groupIndicator.collapsed || layerCollapsed
    property bool layerCollapsed: false
    property alias buttonGroup: buttonGroup

    //--------------------------------------------------------------------------

    implicitHeight: nameText.paintedHeight
    
    //--------------------------------------------------------------------------

    Component.onCompleted: {
        typeId = typeInfo.id;
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
            pointSize: 16
            bold: !collapsed
            italic: collapsed
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    }
    
    //--------------------------------------------------------------------------

    Symbol {
        id: symbol
    }

    //--------------------------------------------------------------------------
}
