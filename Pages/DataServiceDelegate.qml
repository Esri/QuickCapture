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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../Controls"

Item {
    id: delegate

    property alias mouseArea: mouseArea

    signal clicked(var itemInfo);
    signal doubleClicked(var itemInfo);
    signal pressAndHold(var itemInfo);

    property var itemInfo: ListView.view.model.get(index)

    width: ListView.view.width
    height: layout.height + layout.anchors.margins * 2

    //--------------------------------------------------------------------------

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            delegate.clicked(delegate.itemInfo);
        }

        onDoubleClicked: {
            delegate.doubleClicked(delegate.itemInfo);
        }

        onPressAndHold: {
            delegate.pressAndHold(delegate.itemInfo);
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: parent
            margins: 2 * AppFramework.displayScaleFactor
        }

        color: "white"
        border {
            width: 1 * AppFramework.displayScaleFactor
            color: "darkgrey"
        }
        radius: 5 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 5 * AppFramework.displayScaleFactor
        }

        scale: mouseArea.pressed ? 0.9 : 1

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor

            Item {
                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 66 * AppFramework.displayScaleFactor
                //Layout.alignment: Qt.AlignTop
                //                Layout.margins: 3 * AppFramework.displayScaleFactor

                Rectangle {
                    anchors.fill: parent
                    color: "darkgrey"
                }

                Image {
                    anchors.fill: parent

                    source: thumbnailUrl
                    fillMode: Image.PreserveAspectFit
                    cache: false

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border {
                            width: 1
                            color: "#10000000"
                        }
                    }

                    Item {
                        anchors.centerIn: parent

                        visible: portal.signedIn
                        width: parent.height * 0.75
                        height: width

                        Image {
                            anchors {
                                fill: parent
                            }

                            source: local ? updateAvailable ? "images/data-sync.png" : "" : "images/data-download.png"
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
            }

            //----------------------------------------------------------------------

            ColumnLayout {

                Text {
                    Layout.fillWidth: true

                    text: title
                    font {
                        pointSize: 16
                        bold: mouseArea.pressed
                        italic: !local
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: "black"
                }

                Text {
                    id: snippetText

                    Layout.fillWidth: true

                    text: snippet || ""
                    visible: text.length > 0

                    font {
                        pointSize: 12
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: "black"
                    maximumLineCount: 3
                }
            }

            StyledImageButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                source: "images/information.png"

                onClicked: {
                    delegate.pressAndHold(delegate.itemInfo);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
