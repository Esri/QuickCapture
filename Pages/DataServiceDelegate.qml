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
    property alias background: background
    property alias thumbnailSource: thumbnailImage.source
    property alias titleText: titleText
    property alias rowLayout: rowLayout

    signal clicked(var itemInfo);
    signal doubleClicked(var itemInfo);
    signal pressAndHold(var itemInfo);

    property var itemInfo: GridView.view.model.get(index)

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    //--------------------------------------------------------------------------

    Rectangle {
        id: background

        //        anchors {
        //            fill: parent
        //            margins: 5 * AppFramework.displayScaleFactor
        //        }

        Component.onCompleted: {
            if (delegate.GridView.view.dynamicSpacing) {
                background.anchors.centerIn = parent;
                background.width = delegate.GridView.view.cellSize;
                background.height = background.width;
            } else {
                background.anchors.fill = parent;
                background.anchors.margins = 5 * AppFramework.displayScaleFactor;
            }
        }
        
        color: "#404040"
        border {
            width: 1
            color: "#10ffffff"
        }
        radius: 2 * AppFramework.displayScaleFactor
        
        MouseArea {
            id: mouseArea

            anchors.fill: parent

            onClicked: {
                delegate.clicked(delegate.itemInfo);
            }

            onDoubleClicked: {
                delegate.doubleClicked(delegate.itemInfo);
            }

            onPressAndHold: {
                delegate.pressAndHold(delegate.itemInfo);
            }

            onPressed: {
                delegate.scale = 1.05;
            }

            onReleased:  {
                delegate.scale = 1;
            }
        }

        Image {
            id: thumbnailImage

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 1 * AppFramework.displayScaleFactor
            }

            height: width * 133/200
            
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
        
        //--------------------------------------------------------------------------

        RowLayout {
            id: rowLayout

            anchors {
                left: parent.left
                right: parent.right
                top: thumbnailImage.bottom
                bottom: parent.bottom
                margins: 3 * AppFramework.displayScaleFactor
            }

            Text {
                id: titleText

                Layout.fillWidth: true
                Layout.fillHeight: true

                text: title
                font {
                    pixelSize: rowLayout.height / 2 * 0.72
                    bold: false
                    italic: !local
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: "#fefefe"
            }

        }
    }

    //--------------------------------------------------------------------------
}
