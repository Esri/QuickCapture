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
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import "../Controls"

//------------------------------------------------------------------------------

FocusScope {
    id: view

    property string authorizationUrl
    property bool hideCancel: false
    property string fontFamily

    signal accepted(string authorizationCode)
    signal rejected()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("Opening external user agent:", authorizationUrl);
        Qt.openUrlExternally(authorizationUrl);
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20 * AppFramework.displayScaleFactor
        }
        
        spacing: 10 * AppFramework.displayScaleFactor

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        
        Text {
            Layout.fillWidth: true

            text: qsTr("%1 is using an external web browser to sign in.").arg(portal.app.info.title)

            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            font {
                pointSize: 16
                family: fontFamily
            }

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    authorizationCodeLayout.visible = true;
                }
            }
        }

        ColumnLayout {
            id: authorizationCodeLayout

            Layout.fillWidth: true
            Layout.topMargin: 20 * AppFramework.displayScaleFactor

            visible: portal.redirectUri === portal.kRedirectOOB
            spacing: 5 * AppFramework.displayScaleFactor

            Text {
                Layout.fillWidth: true

                text: qsTr("Locate the web browser page that has been launched and copy the code that is displayed. Paste this code below. After signing in you can safely close the external web browser page.")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                font {
                    pointSize: 16
                    family: fontFamily
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: height

                    fontFamily: view.fontFamily
                    text: "↑"
                    visible: false

                    onClicked: {
                        Qt.openUrlExternally(authorizationUrl);
                    }
                }

                TextField {
                    id: codeField

                    Layout.fillWidth: true

                    placeholderText: qsTr("Authorization code")
                }

                StyledButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: height

                    fontFamily: view.fontFamily
                    text: "✔"
                    visible: codeField.length > 0

                    onClicked: {
                        var code = codeField.text.trim();
                        if (code.length) {

                            if (code.substring(0, 4).toLocaleLowerCase() === "http") {
                                console.log("Approval url:", code);
                                portal.app.openUrl(code);
                            } else {
                                console.log("Authorization code:", code);
                                view.accepted(code);
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        StyledButton {
            Layout.alignment: Qt.AlignHCenter

            fontFamily: view.fontFamily
            text: qsTr("Cancel")
            visible: !hideCancel

            onClicked: {
                view.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------
}
