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

import ArcGIS.AppFramework 1.0

import "../Controls"

ListView {
    id: listView

    property string headerText

    //--------------------------------------------------------------------------

    property alias refreshHeader: refreshHeader

    //--------------------------------------------------------------------------

    signal refresh();

    //--------------------------------------------------------------------------

    clip: true
    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    RefreshHeader {
        id: refreshHeader

        onRefresh: {
            listView.refresh();
        }

    }

    Text {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        text: headerText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        color: refreshHeader.textColor

        fontSizeMode: Text.HorizontalFit
        minimumPointSize: 8
        font {
            pointSize: 12
        }

        visible: parent.contentY <= -header.height
    }

    //--------------------------------------------------------------------------
}
