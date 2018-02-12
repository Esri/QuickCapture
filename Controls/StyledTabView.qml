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
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

TabView {
    id: tabView

    property color tabsTextColor: app.titleBarTextColor
    property color tabsSelectedTextColor: tabsBackgroundColor
    property color tabsSelectedBackgroundColor: tabsTextColor
    property color tabsBackgroundColor: app.titleBarBackgroundColor
    property color tabsBorderColor: tabsTextColor
    property color backgroundColor: app.backgroundColor
    property color disabledColor: "grey"
    property int tabsPadding: (showImages ? 2 : 4) * AppFramework.displayScaleFactor
    property real textSize: showImages ? 9 : 13
    property int tabsAlignment: rightCorner ? Qt.AlignLeft : Qt.AlignHCenter
    property string fontFamily

    property bool hideDisabled: true
    property bool showTabs: true
    property bool showImages: false
    property real imageSize: 25 * AppFramework.displayScaleFactor
    property string imageProperty: "image"

    property Component leftCorner
    property Component rightCorner

    //--------------------------------------------------------------------------

    style: TabViewStyle {
        id: tabViewStyle

        tabsAlignment: tabView.tabsAlignment

        tab: Item {
            property int totalOverlap: tabOverlap * (control.count - 1)
            property real minTabWidth: height
            property real maxTabWidth: control.count > 0 ? (styleData.availableWidth + totalOverlap) / control.count : 0

            visible: showTabs && (styleData.enabled || !hideDisabled)

            implicitWidth: visible ? Math.round(Math.max(minTabWidth, Math.min(maxTabWidth, tabText.implicitWidth + tabsPadding * 8))) : 0
            //implicitHeight: Math.round(tabText.implicitHeight + tabsPadding * 4)
            height: Math.round(tabText.implicitHeight + tabsPadding * 4.5) + (showImages ? imageSize : 0)

            Rectangle {
                anchors {
                    fill: parent
                    margins: tabsPadding
                }

                color: styleData.selected ? tabsSelectedBackgroundColor : tabsBackgroundColor
                border {
                    color:  tabsBorderColor
                    width: 1
                }
                radius: showImages ? 5 * AppFramework.displayScaleFactor : height / 2

                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: tabsPadding
                        rightMargin: tabsPadding
                    }

                    spacing: 0

                    Item {
                        Layout.preferredWidth: imageSize
                        Layout.preferredHeight: imageSize
                        Layout.alignment: Qt.AlignCenter

                        visible: showImages && imageProperty > ""

                        Image {
                            id: tabImage

                            anchors.fill: parent
                            source: control.getTab(styleData.index)[imageProperty] || ""
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: tabImage
                            source: tabImage
                            color: tabText.color
                        }
                    }

                    Text {
                        id: tabText

                        Layout.fillWidth: true

                        text: styleData.title
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: styleData.enabled ? styleData.selected ? tabsSelectedTextColor : tabsTextColor : disabledColor
                        font {
                            bold: false//true//styleData.selected
                            pointSize: textSize
                            family: fontFamily
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: -tabsPadding
                    }

                    visible: showImages && styleData.selected
                    height: 2 * AppFramework.displayScaleFactor
                    color: tabsSelectedTextColor
                }
            }
        }

        tabBar: Rectangle {
            color: tabsBackgroundColor

            //            Rectangle {
            //                anchors {
            //                    left: parent.left
            //                    right: parent.right
            //                    bottom: parent.bottom
            //                }

            //                height: 1
            //                color: "#30FFFFFF"
            //            }
        }

        frame: Rectangle {
            color: backgroundColor
        }

        leftCorner: tabView.leftCorner
        rightCorner: tabView.rightCorner
    }

    //--------------------------------------------------------------------------
}
