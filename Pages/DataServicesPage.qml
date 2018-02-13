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

import "../Portal"


PageView {
    id: page

    //--------------------------------------------------------------------------

    property Portal portal
    property UserInfo userInfo
    property bool online
    property alias dataService: dataService
    property bool infoPage: false
    property var signedInCallback
    property bool refreshOnce: true


    //--------------------------------------------------------------------------

    signal selected()

    //--------------------------------------------------------------------------

    title: qsTr("My Data Capture Projects")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        update();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: userInfo

        onInfoChanged: {
            update();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: dataService.portal

        onSignedInChanged: {
            if (dataService.portal.signedIn && signedInCallback) {
                signedInCallback();
                signedInCallback = null;
            }
        }
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: dataFolder
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: parent
        }

        color: "ghostwhite" //"silver"

        ColumnLayout {
            anchors {
                fill: parent
            }

            spacing: 5 * AppFramework.displayScaleFactor

            DataServicesView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 5 * AppFramework.displayScaleFactor

                model: dataServices.model
                delegate: dataServiceDelegate

                onRefresh: {
                    if (portal.signedIn) {
                        page.online = true;
                        page.update();
                    } else {
                        signedInCallback = function() {
                            page.online = true;
                            page.update();
                        };
                        portal.autoSignIn();
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    footer: Rectangle {
        height: childrenRect.height + footerLayout.anchors.margins * 2

        color: theme.pageHeaderColor

        //--------------------------------------------------------------------------

        ColumnLayout {
            id: footerLayout

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 10 * AppFramework.displayScaleFactor
            }

            Text {
                Layout.fillWidth: true

                text: online ? qsTr("Signed in as %1").arg(userInfo.info.fullName) : qsTr("Capturing data as %1").arg(userInfo.info.fullName)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: theme.textColor

                font {
                    pointSize: 14
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        visible: dataService.updating

        color: "#40000000"

        BusyIndicator {
            anchors.centerIn: parent
            running: dataService.updating
        }
    }

    //--------------------------------------------------------------------------

    DataServices {
        id: dataServices

        portal: page.portal
        online: page.online
        path: dataFolder.path

        onRefreshComplete: {
            if (!model.count && !online && refreshOnce) {
                if (dataService.portal.signedIn) {
                    page.online = true;
                    page.update();
                } else {
                    refreshOnce = false;
                    signedInCallback = function() {
                        page.online = true;
                        page.update();
                    };
                    portal.autoSignIn();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dataServiceDelegate

        DataServiceDelegate {
            onClicked: {
                infoPage = false;
                openService(itemInfo);
            }

            onPressAndHold: {
                infoPage = true;
                openService(itemInfo);
            }
        }
    }

    //--------------------------------------------------------------------------

    DataService {
        id: dataService

        portal: page.portal
        userInfo: page.userInfo
        folder.path: dataFolder.path

        onReady: {
            console.log("DataService ready");
        }

        onOpened: {
            console.log("DataService opened");
            selected();
        }

        onCreated: {
            console.log("Created data service:", itemInfo.id);
            page.update();
        }

        onDeleted: {
            console.log("Deleted data service");
            page.update();
        }
    }

    //--------------------------------------------------------------------------

    function openService(itemInfo) {
        var itemId = itemInfo.id;

        console.log("Opening:", itemId, "local:", itemInfo.local, "updateAvaiable:", itemInfo.updateAvailable);

        if (online && (!itemInfo.local || itemInfo.updateAvailable)) {
            dataService.sync(itemId);
        } else {
            dataService.open(itemId);
        }
    }

    //--------------------------------------------------------------------------

    function update() {
        console.log("Update data services");

        if (!userInfo.isValid) {
            console.error("Invalid userInfo");
            return;
        }

        console.log("userInfo:", JSON.stringify(userInfo.info, undefined, 2));

        var path = "~/ArcGIS/QuickCapture/%1/%2"
        .arg(userInfo.info.orgId > "" ? userInfo.info.orgId : "portal")
        .arg(userInfo.info.username);

        console.log("Data path:", path);

        dataFolder.path = path;
        if (!dataFolder.exists) {
            console.log("Creating data folder:", dataFolder.path);
            dataFolder.makeFolder();
        }

        dataServices.refresh();
    }

    //--------------------------------------------------------------------------
}

