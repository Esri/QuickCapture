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
import ArcGIS.AppFramework.Networking 1.0

import "../Portal"

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    property Portal portal
    property UserInfo userInfo

    property var signedInCallback

    //--------------------------------------------------------------------------

    signal start(bool online)
    signal signIn(bool auto)

    //--------------------------------------------------------------------------

    color: "#6eb52a"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        //        portal.autoSignIn();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        onSignedInChanged: {
            if (portal.signedIn && signedInCallback) {
                signedInCallback();
                signedInCallback = null;
            }
        }
    }

    //--------------------------------------------------------------------------

    Image {
        anchors.fill: parent
        source: "../appicon.png"
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#A0000000"
    }

    ColumnLayout {
        anchors {
            fill: parent
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 30 * AppFramework.displayScaleFactor

            text: app.info.title
            font {
                family: app.fontFamily
                pointSize: 30
                bold: true
            }

            color: "white"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 30 * AppFramework.displayScaleFactor

            text: app.info.snippet
            font {
                family: app.fontFamily
                pointSize: 16
            }

            color: "white"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

//        Rectangle {
//            Layout.fillWidth: true

//            color: "white"
//            height: 1
//        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RoundButton {
            Layout.fillWidth: true
            Layout.margins: 10 * AppFramework.displayScaleFactor

            visible: userInfo.isValid

            text: userInfo.isValid ? qsTr("Continue as %1").arg(userInfo.info.fullName) : ""

            onClicked: {
                signedInCallback = null;

                start(false);
            }

            onPressAndHold: {
                signedInCallback = function () {
                    start(true);
                }

                portal.autoSignIn();
            }
        }

        /*
        RoundButton {
            Layout.fillWidth: true
            Layout.margins: 10 * AppFramework.displayScaleFactor

            visible: userInfo.isValid // && !portal.signedIn
            enabled: !portal.busy

            text: userInfo.isValid ? qsTr("Sign in and continue as %1").arg(userInfo.info.fullName) : ""

            onClicked: {
                if (portal.signedIn) {
                    start(true);
                } else {
                    signedInCallback = function () {
                        start(true);
                    }

                    portal.autoSignIn();
                }
            }
        }
        */

        RoundButton {
            Layout.fillWidth: true
            Layout.margins: 10 * AppFramework.displayScaleFactor

            text: userInfo.isValid ? qsTr("Sign in as a different user") : qsTr("Sign in")

            enabled: !portal.busy

            onClicked: {
                signedInCallback = function () {
                    start(true);
                }

                portal.signIn(undefined, true);
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

            text: qsTr("Version %1").arg(app.info.version)
            horizontalAlignment: Text.AlignHCenter
            font {
                pointSize: 14
            }
            color: "white"

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    page.StackView.view.push(aboutPage);
                }
            }
        }

    }

    //--------------------------------------------------------------------------

    Component {
        id: aboutPage

        AboutPage {
            theme: app.theme
        }
    }

    //--------------------------------------------------------------------------
}

