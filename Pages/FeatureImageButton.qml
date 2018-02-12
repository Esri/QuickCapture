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


FeatureButton {
    id: control
    
    //--------------------------------------------------------------------------

    contentItem:
        ColumnLayout {
        clip: true

        Item {
            //            Layout.fillWidth: true
            //            Layout.fillHeight: true
            Layout.preferredWidth: symbol.imageWidth * AppFramework.displayScaleFactor
            Layout.preferredHeight: symbol.imageWidth * AppFramework.displayScaleFactor
            Layout.alignment: Qt.AlignHCenter

            Image {
                anchors.fill: parent

                scale: control.down ? 1.2 : 1
                source: symbol.imageUrl
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                fillMode: Image.PreserveAspectFit
            }
        }

        Text {
            Layout.fillWidth: true

            text: control.text
            font: control.font
            opacity: enabled ? 1.0 : 0.3
            color: control.down ? downTextColor : textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    //--------------------------------------------------------------------------
}
