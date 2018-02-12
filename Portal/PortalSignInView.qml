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

import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../Controls"

//------------------------------------------------------------------------------

Rectangle {
    id: signInView

    property bool dialogStyle: false

    property alias bannerImage: image.source
    property alias bannerColor: banner.color
    property alias bannerTextColor: titleText.color
    property alias backgroundColor: signInView.color

    property string portalName: portal ? portal.name : "<Portal Name>"
    property string title: busy ? qsTr("Signing in to %1").arg(portalName) : qsTr("Sign in to %1").arg(portalName)
    property string reason: portal.signInReason

    property Portal portal

    readonly property bool busy: portal ? portal.busy: false

    readonly property string messageCodePasswordExired: "LLS_0002"

    readonly property bool useOAuth: portal.supportsOAuth
    readonly property bool useExternalUserAgent: useOAuth && portal.externalUserAgent //&& portal.redirectUri != portal.kRedirectOOB

    property int buttonHeight: 35 * AppFramework.displayScaleFactor

    property string fontFamily: portal.app.fontFamily

    signal accepted()
    signal rejected()

    color: "white"

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        onCanPublishChanged: {
            if(!portal.clientMode) {
                if(portal.canPublish) {
                    accepted()
                }
            }
        }

        onSignedInChanged: {
            //console.log("PortalSignInView::onSignedInChange: ", portal.info, portal.user, portal.token);
            if (portal.signedIn && portal.user && (portal.user.orgId || portal.isPortal)) {
                if(portal.clientMode) {
                    accepted();
                }
            }
        }

        onError: {
            //console.log("PortalSignInView::onError: ", error, portal.user.orgId, portal.signedIn, portal.token);
            portal.busy = false;
            signInItem.visible = !useOAuth;
            if (portal.user && !(portal.user.orgId || portal.isPortal)) {
                errorText.text = qsTr("ArcGIS public account is not supported.") + "<br><br><br>" + qsTr("ArcGIS public account is a free personal account with limited usage and capabilities.") + "<br><br>" + qsTr("Please sign in using your ArcGIS organization account.");
            } else {
                errorText.text = "%1<br><br>%2".arg(error.message).arg(error.details || "")
            }
        }
    }

    //--------------------------------------------------------------------------

    StackView {
        id: stackView
        
        anchors {
            fill: parent
        }
        
        initialItem: Rectangle {
            color: backgroundColor

            ColumnLayout {
                anchors.fill: parent

                spacing: 0

                Rectangle {
                    id: banner

                    Layout.fillWidth: true
                    Layout.preferredHeight: bannerColumn.height + 5 * AppFramework.displayScaleFactor * 2//+ buttonHeight

                    color: "#0079C1"

                    Column {
                        id: bannerColumn

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 5 * AppFramework.displayScaleFactor
                        }

                        spacing: 5 * AppFramework.displayScaleFactor

                        RowLayout {
                            id: bannerRow

                            width: parent.width
                            spacing: 10 * AppFramework.displayScaleFactor

                            Item {
                                Layout.preferredWidth: buttonHeight
                                Layout.preferredHeight: buttonHeight

                                ImageButton {
                                    id: rButton

                                    anchors.fill: parent

                                    source: dialogStyle ? "images/close.png" : "images/back.png"

                                    onClicked: {
                                        signInView.rejected();
                                    }
                                }

                                ColorOverlay {
                                    anchors.fill: rButton
                                    source: rButton.image
                                    color: bannerTextColor
                                }
                            }

                            Image {
                                id: image

                                Layout.fillHeight: true

                                fillMode: Image.PreserveAspectCrop
                                visible: source > ""
                            }

                            Text {
                                id: titleText

                                Layout.fillWidth: true

                                text: title
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                                font {
                                    pointSize: 22
                                    family: fontFamily
                                }
                            }

                            Column {
                                Layout.preferredWidth: buttonHeight

                                spacing: 5 * AppFramework.displayScaleFactor

                                Image {
                                    width: parent.width
                                    height: width

                                    source: "images/security_unlock.png"
                                    visible: portal.ignoreSslErrors
                                    fillMode: Image.PreserveAspectFit
                                }

                                Item {
                                    width: parent.width
                                    height: width

                                    ImageButton {
                                        id: configButton

                                        anchors.fill: parent

                                        source: "images/gear.png"
                                        enabled: !busy

                                        onClicked: {
                                            stackView.push(signInOptions);
                                        }
                                    }

                                    ColorOverlay {
                                        visible: configButton.visible
                                        anchors.fill: configButton
                                        source: configButton.image
                                        color: bannerTextColor
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: reasonText.visible
                            width: parent.width
                            color: AppFramework.alphaColor(reasonText.color, 0.5)
                            height: 1
                        }

                        Text {
                            id: reasonText

                            width: parent.width

                            visible: text > ""
                            text: reason
                            color: titleText.color
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                            font {
                                pointSize: 18
                                bold: true
                                family: fontFamily
                            }
                        }

                    }
                }

                Text {
                    id: errorText

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 10 * AppFramework.displayScaleFactor

                    visible: text > ""
                    color: "red"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight

                    font {
                        pointSize: 14
                        bold: true
                        family: fontFamily
                    }

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }

                    Rectangle {
                        anchors.fill: parent

                        color: "white"
                        z: parent.z - 1
                    }
                }

                Item {
                    id: signInItem

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        anchors.fill: parent
                        active: stackView.depth === 1;

                        sourceComponent: portal.singleSignOn ? singleSignOnView : useOAuth ? useExternalUserAgent ? externalUserAgentView : oauthSignInView : inputAreaComponent
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visible: !signInItem.visible
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent

        visible: busy
        color: "#60000000"

        ColorBusyIndicator {
            anchors.centerIn: parent

            backgroundColor: bannerColor
            running: busy
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: singleSignOnView

        Text {

            text: qsTr("This portal supports single sign-on")

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            font {
                pointSize: 16
                family: signInView.fontFamily
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: inputAreaComponent

        BuiltInSignInView {
            id: inputArea

            anchors.fill: parent

            username: portal.username
            fontFamily: signInView.fontFamily

            onRejected: {
                signInView.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: oauthSignInView

        OAuthSignInView {
            anchors.fill: parent

            //portal: signInView.portal
            visible: !busy
            authorizationUrl: signInView.portal.authorizationUrl
            hideCancel: !dialogStyle

            onAccepted: {
                portal.setAuthorizationCode(authorizationCode);
            }

            onRejected: {
                signInView.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: externalUserAgentView

        ExternalUserAgentView {
            anchors.fill: parent

            authorizationUrl: signInView.portal.authorizationUrl
            hideCancel: !dialogStyle
            fontFamily: signInView.fontFamily

            onAccepted: {
                portal.setAuthorizationCode(authorizationCode);
            }

            onRejected: {
                signInView.rejected();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: signInOptions

        PortalSettingsPage {

            portal: signInView.portal

            bannerColor: signInView.bannerColor
            bannerTextColor: signInView.bannerTextColor
            fontFamily: signInView.fontFamily

            onClose: {
                stackView.pop()
            }
        }
    }

    //--------------------------------------------------------------------------

    function forgotUrl(what) {
        var portalUrlInfo = AppFramework.urlInfo(portal.portalUrl);

        portalUrlInfo.scheme = "https";

        return portalUrlInfo.url + "/sharing/oauth2/troubleshoot?client_id=esriapps&redirect_uri=http://www.esri.com&response_type=token&forgotMy=" + what;
    }

    //--------------------------------------------------------------------------
}
