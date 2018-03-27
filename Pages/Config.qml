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
import ArcGIS.AppFramework.Notifications 1.0

QtObject {
    property Settings settings

    property bool captureVibrate: Vibration.supported
    property int captureSound: kSoundBeep

    //--------------------------------------------------------------------------

    readonly property string kKeyCaptureVibrate: "captureVibrate"
    readonly property string kKeyCaptureSound: "captureSound"

    readonly property int kSoundNone: 0
    readonly property int kSoundBeep: 1
    readonly property int kSoundTextToSpeech: 2

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        read();
    }

    //--------------------------------------------------------------------------

    function read() {
        captureVibrate = settings.boolValue(kKeyCaptureVibrate, captureVibrate);
        captureSound = settings.numberValue(kKeyCaptureSound, captureSound);
    }

    //--------------------------------------------------------------------------

    function write () {
        settings.setValue(kKeyCaptureVibrate, captureVibrate);
        settings.setValue(kKeyCaptureSound, captureSound);
    }

    //--------------------------------------------------------------------------
}
