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
import QtQuick.Controls 1.4
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

Item {
    id: refreshHeader
    
    property Flickable target: parent
    property string pullText: qsTr("Pull to refresh")
    property string releaseText: qsTr("Release to refresh")
    property string refreshingText: qsTr("Refreshing")
    property real releaseThreshold: refreshLayout.height * 2
    property color textColor: "#777777"
    property bool refreshing: false

    //--------------------------------------------------------------------------

    signal refresh();

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        top: parent.top
        right: parent.right
    }
    
    height: visible ? -target.contentY : 0
    visible: target.contentY <= -refreshLayout.height && enabled

    Connections {
        target: refreshHeader.target

        onDragEnded: {
            if (refreshHeader.state == "pulled") {
                refresh();
            }
        }
    }
    
    RowLayout {
        id: refreshLayout
        
        height: 50 * AppFramework.displayScaleFactor
        spacing: 5 * AppFramework.displayScaleFactor
        anchors.centerIn: parent

        BusyIndicator {
            Layout.preferredHeight: refreshLayout.height
            Layout.preferredWidth: Layout.preferredHeight

            running: refreshing
            visible: running
        }
        
        Image {
            id: refreshArrow
            
            Layout.preferredHeight: refreshLayout.height
            Layout.preferredWidth: Layout.preferredHeight

            source: "images/refresh-arrow.png"
            transformOrigin: Item.Center
            
            Behavior on rotation {
                NumberAnimation {
                    duration: 200
                }
            }
        }
        
        Text {
            id: refreshText
            
            font {
                pointSize: 15
            }
            
            color: textColor
        }
    }

    states: [
        State {
            name: "base"
            when: target.contentY >= -releaseThreshold && !refreshing && enabled
            
            PropertyChanges {
                target: refreshText
                text: pullText
            }

            PropertyChanges {
                target: refreshArrow
                rotation: 180
                visible: true
            }
        },

        State {
            name: "pulled"
            when: target.contentY < -releaseThreshold && !refreshing && enabled
            
            PropertyChanges {
                target: refreshText
                text: releaseText
            }
            
            PropertyChanges {
                target: refreshArrow
                rotation: 0
                visible: true
            }
        },

        State {
            name: "refreshing"
            when: target.contentY < 0 && refreshing && enabled

            PropertyChanges {
                target: refreshText
                text: refreshingText
            }

            PropertyChanges {
                target: refreshArrow
                visible: false
            }
        }
    ]
}
