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

import "Portal"
import "Pages"

App {
    id: app

    width: 400
    height: 640

    //--------------------------------------------------------------------------

    property alias portal: portal
    property alias userInfo: userInfo
    property alias theme: theme

    property string fontFamily: ""

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        fontFamily = app.info.propertyValue("fontFamily", "");

        userInfo.read();

        console.log("Setting font family:", fontFamily);
    }

    //--------------------------------------------------------------------------

    AppTheme {
        id:theme

        app: app
    }

    //--------------------------------------------------------------------------

    UserInfo {
        id: userInfo

        settings: app.settings
    }

    //--------------------------------------------------------------------------

    StackView {
        id: stackView

        anchors.fill: parent

        initialItem: startPage
    }

    //--------------------------------------------------------------------------

    Component {
        id: startPage

        StartPage {
            portal: app.portal
            userInfo: app.userInfo

            onStart: {
                StackView.view.push(dataServicesPage,
                               {
                                   online: online
                               });
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dataServicesPage

        DataServicesPage {
            theme: app.theme
            portal: app.portal
            userInfo: app.userInfo

            onSelected: {
                StackView.view.push(infoPage ? dataServicePage : dataCapturePage,
                               {
                                   dataService: dataService,
                                   online: online
                               });
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dataServicePage

        DataServicePage {
            theme: app.theme
            dataService: page.dataService
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: dataCapturePage

        DataCapturePage {
            theme: app.theme
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalSignInPage

        PortalSignInView {
            property bool isPortalSignInView: true

            portal: app.portal
            bannerColor: theme.pageHeaderColor

            onRejected: {
                portal.actionCallback = null;
                StackView.view.pop();
            }
        }
    }

    //--------------------------------------------------------------------------

    Portal {
        id: portal

        property bool staySignedIn: settings.value(settingsGroup + "/staySignedIn", app.info.propertyValue("staySignedIn", true))
        property var actionCallback: null

        app: app
        settings: app.settings
        clientId: app.info.value("deployment").clientId
        defaultUserThumbnail: app.folder.fileUrl("template/images/user.png")

        onCredentialsRequest: {
            console.log("Show sign in page");
            stackView.push(portalSignInPage,
                           {
                           });
        }

        function signInAction(reason, callback) {
            validateToken();

            if (signedIn) {
                actionCallback = null;
                callback();
                return;
            }

            actionCallback = callback;
            signIn(reason);
        }

        onSignedInChanged: {
            console.log("onSignedInChanged");

            var callback = actionCallback;
            actionCallback = null;

            if (signedIn) {
                if (staySignedIn) {
                    writeSignedInState();
                } else {
                    clearSignedInState();
                }
            } else {
                clearSignedInState();
            }

            if (signedIn) {
                userInfo.write(portal);
            } else {
                userInfo.clear();
            }

            if (signedIn && stackView.currentItem.isPortalSignInView) {
                stackView.pop();
            }

            if (signedIn && callback) {
                callback();
            }
        }
    }

    //--------------------------------------------------------------------------
}

