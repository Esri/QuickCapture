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

import ArcGIS.AppFramework 1.0

QtObject {
    property App app

    property string fontFamily: app.info.propertyValue("fontFamily", "")

    property color backgroundColor: "#202020"
    property color textColor: "#fefefe"
    property color highlightColor: "#00b2ff"
    property color selectedColor: "#fefefe"

    property color pageHeaderColor: "#303030"
    property color pageHeaderTextColor: "#fefefe"

    property color pageFooterColor: "#303030"
    property color pageFooterTextColor: "#fefefe"
    property color pageBackgroundColor: "#fafafa"

    property color popupSelectedColor: "#f0f0f0"

    property color switchOnColor: "#17a81a"
    property color switchOffColor: "darkgrey"

    property real faderMinimumOpacity: 0.3

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        read();
    }

    //--------------------------------------------------------------------------

    function read() {
    }

    //--------------------------------------------------------------------------
}
