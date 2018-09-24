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

import ArcGIS.AppFramework 1.0

Rectangle {
    implicitHeight: 35 * AppFramework.displayScaleFactor
    
    property int keyCode: 0

    //--------------------------------------------------------------------------

    color: "transparent"
    border {
        width: (activeFocus ? 2 : 1) * AppFramework.displayScaleFactor
        color: activeFocus ? "blue" : "grey"
    }
    
    //--------------------------------------------------------------------------

    Keys.onPressed: {
        if (event.key) {
            console.log("onPressed key:", event.key, event.key.toString(16), "modifiers:", event.modifiers, event.modifiers.toString(16), "nativeScanCode:", event.nativeScanCode);

            keyCode = event.key;
        }
    }
    
    //--------------------------------------------------------------------------

    Text {
        id: keyText
        
        anchors.fill: parent
        

        property string keyInfo
        
        text: (parent.activeFocus && keyCode)
              ? qsTr("Key code %1 (0x%2)".arg(keyCode).arg(keyCode.toString(16)))
              : qsTr("Press to show key information")

        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    
    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            if (parent.activeFocus) {
                console.log("Copy to clipboard key:", keyCode, keyCode.toString(16));
                AppFramework.clipboard.copy("key=0x%1".arg(keyCode.toString(16)));
            } else {
                keyCode = 0;
                parent.forceActiveFocus();
            }
        }
    }

    //--------------------------------------------------------------------------
}
