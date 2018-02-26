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


FeatureButton {
    id: control

    implicitHeight: 50 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    property var currentPosition
    property bool pulseOn
    property bool flashOn
    readonly property bool pulse: checked && pulseOn


    property string currentFeatureId
    property date startTime
    property var lastPosition

    property int minimumInterval: 0
    property real minimumDistance: 0

    property bool lightOn
    property bool active

    property color pulseBorderColor: "white"
    property real pulseBorderWidth: 3 * AppFramework.displayScaleFactor

    property color blinkOnColor: "red"
    property color blinkOffColor: "darkred"
    property color blinkBorderOnColor: "white"
    property color blinkBorderOffColor: "silver"

    //--------------------------------------------------------------------------

    signal beginFeature()
    signal endFeature()
    signal addFeaturePoint()

    //--------------------------------------------------------------------------

    checkable: true
    autoExclusive: false

    //--------------------------------------------------------------------------

    Component.onCompleted: {

        if (options.interval) {
            minimumInterval = options.interval;
        }

        if (options.distance) {
            minimumDistance = options.distance;
        }

        switch (symbol.style) {
        case symbol.kCircleStyle:
            background.radius = Qt.binding(function() { return background.height / 2; })
            break;

        case symbol.kSquareStyle:
            background.radius = 0;
            break;

        default:
            break;
        }
    }

    //--------------------------------------------------------------------------

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? downTextColor : textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    }

    //--------------------------------------------------------------------------

    background: Rectangle {
        implicitWidth: 100 * AppFramework.displayScaleFactor
        implicitHeight: 40 * AppFramework.displayScaleFactor

        color: (control.down || pulse) ? Qt.lighter(backgroundColor, 1.2) : backgroundColor
        opacity: enabled ? 1 : 0.3
        border {
            color: control.down ? downBorderColor : pulse ? pulseBorderColor : borderColor
            width: pulse ? pulseBorderWidth : borderWidth * (control.down ? 1 : 1.3)
        }

        radius: 5 * AppFramework.displayScaleFactor

        Rectangle {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 10 * AppFramework.displayScaleFactor
            }

            visible: checked
            width: 20 * AppFramework.displayScaleFactor
            height: width
            radius: height / 2

            color: lightOn ? blinkOnColor : blinkOffColor

            border {
                width: 1 * AppFramework.displayScaleFactor
                color: lightOn ? blinkBorderOnColor : blinkBorderOffColor
            }
        }
    }

    //--------------------------------------------------------------------------

    onClicked: {
        console.log("checked:", checked, currentFeatureId);

        if (active) {
            active = false;
            toggle();
        } else {
            active = checked;
        }
    }

    onCheckedChanged: {
        console.log("onCheckedChanged:", checked);

        if (!checked) {
            endPoly();
        } else {
            beginPoly();
        }
    }

    //--------------------------------------------------------------------------

    function beginPoly() {
        startTime = new Date();
        lastPosition = null;
        currentFeatureId = AppFramework.createUuidString(2);
        console.log("Begin poly:", template.name, currentFeatureId);

        beginFeature();
    }

    //--------------------------------------------------------------------------

    function endPoly() {
        console.log("End poly:", template.name, currentFeatureId);

        endFeature();

        currentFeatureId = "";
        lastPosition = null;
    }

    //--------------------------------------------------------------------------

    onCurrentPositionChanged: {
        if (!checked) {
            return;
        }

        if (!lastPosition) {
            addPosition();
        } else {
            checkPosition();
        }
    }

    //--------------------------------------------------------------------------

    function checkPosition() {
        var interval = (currentPosition.timestamp.valueOf() - lastPosition.timestamp.valueOf()) / 1000;
        var distance = lastPosition.coordinate.distanceTo(currentPosition.coordinate);

        console.log("interval:", interval, "<", minimumInterval, interval < minimumInterval, "distance:", distance, "<", minimumDistance, distance < minimumDistance);

        if (interval < minimumInterval || distance < minimumDistance) {
            return;
        }

        addPosition();
    }

    //--------------------------------------------------------------------------

    function addPosition() {
        lastPosition = currentPosition;

        //console.log("Add position:", JSON.stringify(currentPosition));

        lightOn = true;
        addFeaturePoint();
    }

    onFlashOnChanged: {
        lightOn = false;
    }

    //--------------------------------------------------------------------------
}
