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
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0


Item {
    //--------------------------------------------------------------------------

    property bool collapsed: false
    property alias color: colorOverlay.color

    //--------------------------------------------------------------------------

    implicitWidth: 100
    implicitHeight: 100
    
    //--------------------------------------------------------------------------

    Image {
        id: groupImage
        
        anchors.fill: parent
        
        fillMode: Image.PreserveAspectFit
        source: "images/group-indicator.png"
        visible: false
    }
    
    //--------------------------------------------------------------------------

    ColorOverlay {
        id: colorOverlay

        anchors.fill: groupImage
        source: groupImage
        color: "darkgrey"

        rotation: collapsed ? -90 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: 200
            }
        }
    }
    
    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            collapsed = !collapsed;
        }
    }

    //--------------------------------------------------------------------------
}
