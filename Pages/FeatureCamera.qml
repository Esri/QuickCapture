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
import QtMultimedia 5.9

import ArcGIS.AppFramework 1.0

Camera {
    id: camera
    
    //--------------------------------------------------------------------------

    property DataService dataService
    property FeatureButton featureButton
    property var featureProperties
    
    //--------------------------------------------------------------------------

    cameraState:  Camera.UnloadedState
    captureMode: Camera.CaptureStillImage
    
    focus {
        focusMode: Camera.FocusContinuous
        focusPointMode: Camera.FocusPointAuto
    }
    
    exposure {
        exposureCompensation: Camera.ExposureAuto
    }
    
    //--------------------------------------------------------------------------

    Component.onCompleted: {
        selectCamera();
    }
    
    onCameraStatusChanged: {
        console.log("cameraStatus:", cameraStatus);
    }
    
    //--------------------------------------------------------------------------

    imageCapture {
        onErrorStringChanged: {
            console.log("Camera error:", errorString);
        }
        
        onImageCaptured: {
            console.log("Image captured:", requestId, preview);
        }
        
        onCapturedImagePathChanged: {
            console.log("capturedImagePath: ", camera.imageCapture.capturedImagePath);
        }
        
        onImageSaved: {
            console.log("Image saved:", requestId, "path:", path);
            addPoint(camera.featureButton, camera.featureProperties, AppFramework.fileInfo(path).fileName);
        }
    }
    
    //--------------------------------------------------------------------------

    function captureImage(featureButton, properties) {
        if (!imageCapture.ready) {
            console.log("Image capture not ready");
            return;
        }
        
        camera.featureButton = featureButton;
        camera.featureProperties = properties;
        
        var fileName = "%1.jpg".arg(AppFramework.createUuidString(2));
        var filePath = dataService.attachmentsFolder.filePath(fileName);
        
        console.log("Capture image:", filePath);
        
        imageCapture.captureToLocation(filePath);
    }
    
    //--------------------------------------------------------------------------

    function selectCamera() {
        var cameraInfo = findCamera();
        if (cameraInfo) {
            camera.deviceId = cameraInfo.deviceId;
        }
    }

    //--------------------------------------------------------------------------

    // Return the backward facing camera if available, or the first one found otherwise
    function findCamera() {
        var cameras = QtMultimedia.availableCameras;

        if (cameras.length > 0) {
            for (var i = 0; i < cameras.length; i++) {
                var cameraInfo = cameras[i];

                // console.log("cameraInfo:", i, JSON.stringify(cameraInfo, undefined, 2));

                if (isBackCamera(cameraInfo)) {
                    return cameraInfo;
                }
            }

            return cameras[0];
        }
    }

    //--------------------------------------------------------------------------

    // return true if the camera is backward facing, false otherwise
    function isBackCamera(cameraInfo){
        if (cameraInfo) {
            var displayName = cameraInfo.displayName.toLowerCase();
            var deviceId = cameraInfo.deviceId.toLowerCase();

            if (cameraInfo.position === Camera.BackFace ||
                    displayName.indexOf("rear") >= 0 ||
                    displayName.indexOf("back") >= 0 ||
                    deviceId.indexOf("rear") >= 0 ||
                    deviceId.indexOf("back") >= 0) {
                return true;
            }
        }

        return false;
    }

    //--------------------------------------------------------------------------
}
