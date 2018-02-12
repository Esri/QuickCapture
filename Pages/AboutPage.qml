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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

PageView {
    id: page

    //--------------------------------------------------------------------------

    title: qsTr("About %1").arg(app.info.title)

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        color: theme.backgroundColor

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            Text {
                Layout.fillWidth: true

                text: qsTr("Version %1").arg(app.info.version)
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 16
                color: theme.textColor
            }

            Text {
                Layout.fillWidth: true

                text: app.info.description
                //textFormat: Text.RichText
                horizontalAlignment: Text.AlignHCenter
                color: theme.textColor
            }

            Text {
                Layout.fillWidth: true

                text: app.info.licenseInfo
            }

            Text {
                Layout.fillWidth: true

                text: qsTr('<a href="http://esriurl.com/labseula">View the license agreement</a>')
                horizontalAlignment: Text.AlignHCenter
                font {
                    pointSize: 15
                    bold: true
                }
                color: theme.textColor
                linkColor: color
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
