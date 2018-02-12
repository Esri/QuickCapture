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

import QtQuick 2.4

import ArcGIS.AppFramework 1.0

NetworkRequest {
    id: request

    property Portal portal
    property bool trace: false

    signal success();
    signal failed(var error)

    responseType: "json"
    method: "POST"
    ignoreSslErrors: portal && portal.ignoreSslErrors

//    headers {
//        referrer: portal.portalUrl
//    }

    // TODO : This is a work around for above crashing when portal changes

    onPortalChanged: {
        if (portal) {
            headers.referrer = portal.portalUrl.toString();
        }
    }

    onReadyStateChanged: {
        //console.log("portalRequest readyState", readyState);

        if (readyState === NetworkRequest.ReadyStateComplete)
        {
            //console.log("portalRequest status", status, statusText, "responseText", responseText);

            if (status === 200) {
                if (responsePath) {
                    success();
                } else {
                    if (response.error) {
                        failed(response.error);
                    } else {
                        success();
                    }
                }
            } else {
                console.error("PortalRequest status:", status, statusText);

                failed({
                           code: status,
                           message: statusText
                       });
            }
        }
    }

    onErrorTextChanged: {
        console.error("portalRequest:", url, "error", errorText);
    }

    onFailed: {
        console.error("PortalRequest failed: url", url, "error", JSON.stringify(error, undefined, 2));
    }

    function sendRequest(formData) {
        if (!formData) {
            formData = {};
        }

        formData.token = portal.token;

        if (responseType === "json") {
            formData.f = "pjson";
        }

        if (trace) {
            console.log("formData:", JSON.stringify(formData, undefined, 2));
        }

        headers.userAgent = portal.userAgent;
        portal.setRequestCredentials(this, "PortalRequest");
        send(formData);
    }
}
