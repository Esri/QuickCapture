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

    property DataService dataService
    property var signedInCallback

    //--------------------------------------------------------------------------

    title: dataService.itemInfo.title

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: parent
        }

        color: theme.backgroundColor

        ColumnLayout {
            Layout.fillWidth: true

            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: 133 * AppFramework.displayScaleFactor

                source: dataService.thumbnail
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
            }

            Text {
                Layout.fillWidth: true

                text: dataService.itemInfo.description || ""
                color: "white"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter

                font {
                    pointSize: 14
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Button {
                Layout.fillWidth: true

                enabled: dataService.points > 0 && !dataService.uploading
                text: qsTr("Upload %1 data points").arg(dataService.points)

                onClicked: {
                    if (dataService.portal.signedIn) {
                        dataService.upload();
                    } else {
                        signedInCallback = function () {
                            dataService.upload();
                        }

                        dataService.portal.autoSignIn();
                    }
                }
            }

            DelayButton {
                Layout.fillWidth: true

                enabled: dataService.points > 0 && !dataService.uploading
                text: qsTr("Delete %1 data points").arg(dataService.points)

                onActivated: {
                    dataService.deleteAll();
                }
            }

            DelayButton {
                Layout.fillWidth: true

                enabled: !dataService.uploading
                text: qsTr("Delete this project")

                onActivated: {
                    dataService.deleteFiles();
                    back();
                }
            }

            /*
            RoundButton {
                Layout.fillWidth: true

                text: qsTr("Update project configuration")

                onClicked: {
                    if (dataService.portal.signedIn) {
                        dataService.sync();
                    } else {
                        signedInCallback = function () {
                            dataService.sync();
                        }

                        dataService.portal.autoSignIn();
                    }
                }
            }
            */

            Flow {
                Layout.fillWidth: true
                spacing: 10 * AppFramework.displayScaleFactor

                Text {
                    text: qsTr("Owner: <b>%1</b>").arg(dataService.itemInfo.owner)
                    color: theme.textColor
                }

                Text {
                    text: qsTr("Modifed: <b>%1</b>").arg(new Date(dataService.itemInfo.modified))
                    color: theme.textColor
                }
            }

            Text {
                Layout.fillWidth: true

                text: '<a href="%1/home/item.html?id=%2">%2</a>'.arg(dataService.portal.portalUrl).arg(dataService.itemInfo.id);
                color: theme.textColor
                linkColor: color
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter

                font {
                    pointSize: 13
                }

                onLinkActivated: {
                    Qt.openUrlExternally(link);
                }
            }
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
}
