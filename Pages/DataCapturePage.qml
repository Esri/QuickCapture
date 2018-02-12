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
import QtPositioning 5.8
import QtLocation 5.9
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Sql 1.0

PageView {
    id: page

    //--------------------------------------------------------------------------

    property DataService dataService
    property bool online
    property var coordinate: QtPositioning.coordinate()
    property var coordinateInfo: Coordinate.convert(coordinate, "ddm")
    property color coordinateColor: "white"
    property real horizontalAccuracy
    property var lastInsertId

    property bool showMap: false

    //--------------------------------------------------------------------------

    title: dataService.itemInfo.title

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var options = dataService.parseOptions(dataService.itemInfo.accessInformation);

        console.log("Service options:", JSON.stringify(options, undefined, 2));

        if (options.showMap) {
            showMap = options.showMap;
        }

        if (options.columns) {
            featureTypesPanel.columns = options.columns;
        }

        if (options.backgroundColor) {
            backgroundFill.color = options.backgroundColor;
        }
    }

    //--------------------------------------------------------------------------

    PositionSource {
        id: positionSource

        active: true

        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                coordinate = position.coordinate;
                horizontalAccuracy = Math.round(position.horizontalAccuracy);
                if (horizontalAccuracy < 10) {
                    coordinateColor = "white";
                } else if (horizontalAccuracy < 100) {
                    coordinateColor = "orange";
                } else {
                    coordinateColor = "red";
                }

                map.center = coordinate;
            }
        }
    }

    //--------------------------------------------------------------------------

    Item {
        parent: page.actionItem
        anchors.fill: parent

        opacity: dataService.points > 0 ? 1 : 0.3

        Image {
            id: uploadImage

            anchors.fill: parent
            visible: false

            source: "images/upload-data.png"
            fillMode: Image.PreserveAspectFit
            verticalAlignment: Image.AlignTop
        }

        ColorOverlay {
            anchors.fill: uploadImage
            color: dataService.uploading ? "#00b2ff" : theme.pageHeaderTextColor
            source: uploadImage
        }

        Text {
            anchors.fill: parent

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom

            text: "%1".arg(dataService.points)
            color: theme.pageHeaderTextColor
            font {
                pointSize: 10
            }
        }

        MouseArea {
            anchors.fill: parent

            enabled: !portal.busy && !dataService.uploading && dataService.points > 0

            onClicked: {
                upload();
            }
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: backgroundFill

        anchors {
            fill: parent
        }

        //color: "#fefefe"
        color: "silver"
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        ScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            FeatureTypesPanel {
                id: featureTypesPanel

                width: scrollView.width

                dataService: page.dataService
                background: backgroundFill

                onAddFeature: {
                    lastInsertId = dataService.insertFeature(positionSource.position, layerId, template.prototype.attributes);
                    captureAudio.play();
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


            Map {
                id: map

                Layout.fillWidth: true
                Layout.preferredHeight: 100 * AppFramework.displayScaleFactor

                visible: showMap

                plugin: Plugin {
                    preferred: ["AppStudio", "ArcGIS", "esri"]
                }

                zoomLevel: 18

                gesture {
                    acceptedGestures: MapGestureArea.PinchGesture
                }

                //activeMapType: supportedMapTypes[0]

                onCopyrightLinkActivated: {
                    Qt.openUrlExternally(link);
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width / 2
                    height: 1
                    color: "black"
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height / 2
                    color: "black"
                }

                Rectangle {
                    anchors.fill: parent

                    color: "transparent"
                    border {
                        width: 1
                        color: "black"
                    }
                }
            }

            Text {
                Layout.fillWidth: true

                // ⇔ ⇕ ±
                text: (coordinateInfo && coordinateInfo.ddm) ? qsTr("Lat <b>%1</b> Lon <b>%2</b> ± <b>%3</b> m").arg(coordinateInfo.ddm.latitudeText).arg(coordinateInfo.ddm.longitudeText).arg(horizontalAccuracy) : ""
                color: coordinateColor
                font {
                    pointSize: 14
                }
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent

                    onPressAndHold: {
                        map.visible = !map.visible;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                RoundButton {
                    Layout.fillWidth: true

                    enabled: lastInsertId > 0
                    text: qsTr("Delete Last Point")

                    onClicked: {
                        dataService.deleteRow(lastInsertId);
                        lastInsertId = undefined;
                        deleteAudio.play();
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Audio {
        id: captureAudio

        source: "audio/capture.mp3"
    }

    Audio {
        id: deleteAudio

        source: "audio/delete.mp3"
    }

    //--------------------------------------------------------------------------

    Connections {
        target: dataService

        onUploaded: {
        }
    }

    Connections {
        target: dataService.portal

        onSignedInChanged: {
            if (dataService.portal.signedIn) {
                upload();
            }
        }
    }

    function upload() {
        if (!dataService.portal.signedIn) {
            dataService.portal.autoSignIn();
            return;
        }

        dataService.upload();
    }

    //--------------------------------------------------------------------------
}

