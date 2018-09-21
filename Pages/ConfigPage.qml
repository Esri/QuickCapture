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
import ArcGIS.AppFramework.Notifications 1.0

import "../Controls"

PageView {
    id: page

    property Config config

    //--------------------------------------------------------------------------

    title: qsTr("Settings")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        config.read();
    }

    Component.onDestruction: {
        config.write();
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        color: "lightgrey" //theme.backgroundColor

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            GroupBox {
                Layout.fillWidth: true

                title: qsTr("Capture feedback");

                ColumnLayout {
                    anchors.fill: parent

                    ColumnLayout {
                        Layout.fillWidth: parent

                        RadioButton {
                            text: qsTr("No sound")

                            checked: config.captureSound == config.kSoundNone

                            onCheckedChanged: {
                                if (checked) {
                                    config.captureSound = config.kSoundNone;
                                }
                            }
                        }

                        RadioButton {
                            text: qsTr("Beep")

                            checked: config.captureSound == config.kSoundBeep

                            onCheckedChanged: {
                                if (checked) {
                                    config.captureSound = config.kSoundBeep;
                                }
                            }
                        }

                        RadioButton {
                            text: qsTr("Text to speech")

                            checked: config.captureSound == config.kSoundTextToSpeech

                            onCheckedChanged: {
                                if (checked) {
                                    config.captureSound = config.kSoundTextToSpeech;
                                }
                            }
                        }
                    }

                    Switch {
                        Layout.fillWidth: true

                        enabled: Vibration.supported
                        text: qsTr("Vibrate")
                        checked: config.captureVibrate

                        onCheckedChanged: {
                            config.captureVibrate = checked;
                        }
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true

                title: qsTr("Auto upload");

                ColumnLayout {
                    anchors.fill: parent

                    Switch {
                        Layout.fillWidth: true

                        text: qsTr("Enabled")
                        checked: config.autoUpload

                        onCheckedChanged: {
                            config.autoUpload = checked;
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("Interval (seconds)")
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    TextField {
                        Layout.fillWidth: true

                        enabled: config.autoUpload
                        text: config.autoUploadInterval
                        validator: IntValidator {
                            bottom: 1
                        }

                        inputMethodHints: Qt.ImhDigitsOnly

                        onEditingFinished: {
                            config.autoUploadInterval = Number(text);
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
