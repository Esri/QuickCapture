/* Copyright 2015 Esri
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

import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../Controls"

//------------------------------------------------------------------------------

Rectangle {
    id: page

    property Portal portal

    property int buttonHeight: 35 * AppFramework.displayScaleFactor
    property alias bannerColor: view.bannerColor
    property color bannerTextColor: "white"
    property alias fontFamily: view.fontFamily

    signal close()

    //--------------------------------------------------------------------------

    color: "white"
    
    //--------------------------------------------------------------------------

    Rectangle {
        id: portalsBanner
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        
        height: portalsBannerRow.height + 5 * AppFramework.displayScaleFactor * 2
        color: bannerColor
        
        RowLayout {
            id: portalsBannerRow
            
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            
            ImageButton {
                Layout.preferredWidth: buttonHeight
                Layout.preferredHeight: buttonHeight
                
                source: "images/back.png"
                
                onClicked: {
                    page.close();
                }
            }
            
            Text {
                Layout.fillWidth: true
                
                text: qsTr("Portals")
                font {
                    pointSize: titleText.font.pointSize
                    bold: titleText.font.bold
                    family: fontFamily
                }
                color: bannerTextColor
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.preferredWidth: buttonHeight
                Layout.preferredHeight: buttonHeight
            }
        }
    }
    
    //--------------------------------------------------------------------------

    PortalSettingsView {
        id: view

        anchors {
            left: parent.left
            right: parent.right
            top: portalsBanner.bottom
            bottom: parent.bottom
        }

        portal: page.portal
        bannerColor: bannerColor
        fontFamily: page.fontFamily

        onDoubleClicked: {
            page.close();
        }
    }

    //--------------------------------------------------------------------------
}

