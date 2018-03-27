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
import ArcGIS.AppFramework.Controls 1.0

import "../Controls"

Rectangle {
    id: header

    property AppTheme theme
    property alias textColor: titleText.color
    property string fontFamily
    property alias actionItem: actionItem

    //--------------------------------------------------------------------------

    signal back()
    signal titleClicked()
    signal titlePressAndHold()

    //--------------------------------------------------------------------------

    height: childrenRect.height + rowLayout.anchors.margins * 2

    color: theme.pageHeaderColor

    //--------------------------------------------------------------------------

    RowLayout {
        id: rowLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10 * AppFramework.displayScaleFactor
        }

        Item {
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: Layout.preferredHeight

            StyledImageButton {
                anchors {
                    fill: parent
                    margins: - rowLayout.anchors.margins
                }

                source: "images/back.png"

                onClicked: {
                    forceActiveFocus();
                    back();
                }
            }
        }
        
        Text {
            id: titleText
            
            Layout.fillWidth: true

            text: title
            color: theme.pageHeaderTextColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font {
                pointSize: 22
                family: theme.fontFamily
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    titleClicked();
                }

                onPressAndHold: {
                    titlePressAndHold();
                }
            }
        }

        Item {
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: Layout.preferredHeight

            Item {
                id: actionItem

                anchors {
                    fill: parent
                    margins: 3 * AppFramework.displayScaleFactor - rowLayout.anchors.margins
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
