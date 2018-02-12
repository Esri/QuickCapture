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

Item {
    property Settings settings

    readonly property string kGroupInfo: "Info"
    readonly property string kKeyUserInfo: kGroupInfo + "/user"

    property var info: null

    readonly property bool isValid: typeof info === "object" && info !== null

    //--------------------------------------------------------------------------

    function read() {
        try {
            info = JSON.parse(settings.value(kKeyUserInfo, ""));
        } catch (e) {
            info = null;
        }

        if (!info || typeof info !== "object") {
            info = null;
        }

        console.log("read userInfo:", JSON.stringify(info, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function write(portal) {

        var user = portal.user;

        info = {
            orgId: user.orgId,
            username: user.username,
            firstName: user.firstName,
            lastName: user.lastName,
            fullName: user.fullName,
            email: user.email
        };

        console.log("write userInfo:", JSON.stringify(info, undefined, 2));

        settings.setValue(kKeyUserInfo, JSON.stringify(info));
    }

    //--------------------------------------------------------------------------

    function clear() {
        info = null;
        settings.remove(kKeyUserInfo);
    }

    //--------------------------------------------------------------------------
}
