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

Item {
    id: view

    property Portal portal

    property color bannerColor: "black"

    property real minimumVersionMajor: 3
    property real minimumVersionMinor: 7
    readonly property real kMinimumVersion: combineVersionParts(minimumVersionMajor, minimumVersionMinor)
    readonly property string kPortalHelpUrl: "http://doc.arcgis.com/en/survey123/desktop/create-surveys/survey123withenterprise.htm"

    property bool showExtraInfo: false

    property string fontFamily

    property int initialIndex: -1

    signal portalSelected(var portalInfo)
    signal doubleClicked()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        portalsList.read();
        initialIndex = portalsList.find(portal);
        portalsListView.currentIndex = initialIndex;
    }

    //--------------------------------------------------------------------------

    onPortalSelected: {
        portal.setPortal(portalInfo);
    }

    //--------------------------------------------------------------------------

    PortalsList {
        id: portalsList

        settings: portal.settings
        settingsGroup: portal.settingsGroup
        singleInstanceSupport: portal.singleInstanceSupport
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        ColumnLayout {
            Layout.fillWidth: true

            visible: showExtraInfo

            StyledButton {
                Layout.alignment: Qt.AlignHCenter

                visible: !addPortalGroupBox.visible
                text: "Clear Portals"

                fontFamily: view.fontFamily

                onClicked: {
                    portalsList.clear();
                    portal.setPortal(portalsList.kDefaultPortal);
                    initialIndex = -1;
                    portalsListView.currentIndex = 0;
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1

                color: bannerColor
            }
        }

        Text {
            Layout.fillWidth: true

            text: qsTr("Select your active ArcGIS Portal")
            font {
                pointSize: 14
                family: fontFamily
            }
            color: "#4c4c4c"
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    showExtraInfo = !showExtraInfo;
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1

            color: bannerColor
        }

        ListView {
            id: portalsListView

            Layout.fillHeight: true
            Layout.fillWidth: true

            model: portalsList.model
            highlightFollowsCurrentItem: true
            highlight: portalHighlight
            spacing: 5 * AppFramework.displayScaleFactor
            clip: true

            onCurrentIndexChanged: {
                if (currentIndex >= 0 && initialIndex >= 0) {
                    var portalInfo = portalsList.model.get(currentIndex);
                    portalSelected(portalInfo);
                }
            }

            delegate: Item {
                width: portalRow.width
                height: portalRow.height

                RowLayout {
                    id: portalRow

                    width: portalsListView.width

                    Image {
                        Layout.preferredWidth: 15 * AppFramework.displayScaleFactor * 2
                        Layout.preferredHeight: Layout.preferredWidth

                        source: isPortal ? "images/portal.png" : "images/online.png"
                        fillMode: Image.PreserveAspectFit
                    }

                    Image {
                        Layout.preferredWidth: 15 * AppFramework.displayScaleFactor * 2
                        Layout.preferredHeight: Layout.preferredWidth

                        source: supportsOAuth ? "images/oauth.png" : "images/builtin.png"
                        fillMode: Image.PreserveAspectFit
                        visible: source > "" && showExtraInfo
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: portalText.height

                        ColumnLayout {
                            id: portalText

                            width: parent.width

                            Text {
                                Layout.fillWidth: true

                                text: name
                                font {
                                    pointSize: 14
                                    bold: index == portalsListView.currentIndex
                                    family: fontFamily
                                }
                                color: "black"
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                visible: index > 0 || showExtraInfo

                                Image {
                                    Layout.preferredWidth: 15 * AppFramework.displayScaleFactor
                                    Layout.preferredHeight: Layout.preferredWidth

                                    source: ignoreSslErrors ? "images/security_unlock.png" : "" //"images/security_lock.png"
                                    fillMode: Image.PreserveAspectFit
                                    visible: source > ""
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: url
                                    font {
                                        pointSize: 12
                                        family: fontFamily
                                    }
                                    color: "#4c4c4c"
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                }
                            }

                            Flow {
                                Layout.fillWidth: true

                                visible: showExtraInfo

                                spacing: 5 * AppFramework.displayScaleFactor

                                Text {
                                    visible: networkAuthentication
                                    text: "NA"
                                }

                                Text {
                                    visible: externalUserAgent
                                    text: "EUA"
                                }

                                Text {
                                    visible: singleSignOn
                                    text: "SSO"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                portalsListView.currentIndex = index;
                            }

                            onDoubleClicked: {
                                portalsListView.currentIndex = index;
                                view.doubleClicked();
                            }

                            onPressAndHold: {
                                Qt.openUrlExternally(url);
                            }
                        }
                    }

                    ImageButton {
                        width: 20 * AppFramework.displayScaleFactor
                        height: width

                        source: "images/trash_bin.png"
                        visible: index > 0 && index == portalsListView.currentIndex

                        onClicked: {
                            portalsList.remove(index);
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1

            visible: !addPortalGroupBox.visible

            color: bannerColor
        }

        StyledButton {
            Layout.alignment: Qt.AlignHCenter

            visible: !addPortalGroupBox.visible
            text: qsTr("Add Portal")
            fontFamily: view.fontFamily

            onClicked: {
                addPortalGroupBox.visible = true;
            }
        }

        //        GroupBox {
        GroupRectangle {
            id: addPortalGroupBox

            Layout.fillWidth: true

            visible: false

            ColumnLayout {
                id: addPortalLayout

                width: parent.width

                spacing: 5 * AppFramework.displayScaleFactor

                Text {
                    Layout.preferredWidth: addPortalLayout.width

                    text: qsTr("URL of your Portal for ArcGIS")
                    font {
                        family: fontFamily
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight

                    MouseArea {
                        anchors.fill: parent

                        onPressAndHold: {
                            forceBuiltIn.visible = !forceBuiltIn.visible;
                        }
                    }
                }

                TextField {
                    id: portalUrlField

                    Layout.preferredWidth: addPortalLayout.width

                    enabled: !portalInfoRequest.isBusy
                    placeholderText: qsTr("Example: https://webadaptor.example.com/arcgis")
                    textColor: "black"
                }

                GridLayout {
                    id: credentialsLayout

                    Layout.preferredWidth: addPortalLayout.width

                    columns: 2
                    rows: 2
                    visible: false

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("Username")
                        font {
                            family: fontFamily
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("Password")
                        font {
                            family: fontFamily
                        }
                    }

                    TextField {
                        id: userField

                        Layout.fillWidth: true

                        placeholderText: "DOMAIN\\username"//qsTr("Username")
                    }

                    TextField {
                        id: passwordField

                        Layout.fillWidth: true

                        placeholderText: qsTr("Password")
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData
                    }
                }

                StyledSwitchBox {
                    id: externalUserAgent

                    Layout.preferredWidth: addPortalLayout.width

                    visible: !credentialsLayout.visible //&& showExtraInfo
                    checked: false //portal.singleInstanceSupport
                    text: qsTr("Use external web browser for sign in")
                    fontFamily: view.fontFamily
                }

                StyledSwitchBox {
                    id: sslCheckBox

                    Layout.preferredWidth: addPortalLayout.width

                    visible: false
                    checked: false
                    text: qsTr("Ignore SSL Errors")
                    fontFamily: view.fontFamily
                }

                StyledSwitchBox {
                    id: forceBuiltIn

                    Layout.fillWidth: true

                    visible: false
                    checked: false
                    text: "Force built In authentication"
                    fontFamily: view.fontFamily
                }

                Text {
                    id: addPortalError

                    Layout.preferredWidth: addPortalLayout.width

                    visible: text > ""
                    color: "red"
                    font {
                        pointSize: 14
                        family: fontFamily
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                }


                Text {
                    Layout.preferredWidth: addPortalLayout.width

                    text: qsTr('<a href="%1">Learn more about managing portal connections</a>').arg(kPortalHelpUrl)
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font {
                        family: fontFamily
                    }

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                Flow {
                    Layout.preferredWidth: addPortalLayout.width

                    StyledButton {
                        text: qsTr("Add Portal")
                        enabled: portalUrlField.text.substring(0, 4).toLocaleLowerCase() === "http" && !portalInfoRequest.isBusy
                        fontFamily: view.fontFamily

                        onClicked: {
                            addPortalError.text = "";
                            portalInfoRequest.sendRequest(portalUrlField.text.trim());
                        }
                    }

                    StyledButton {
                        text: qsTr("Cancel")
                        fontFamily: view.fontFamily

                        onClicked: {
                            addPortalGroupBox.visible = false;
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ColorBusyIndicator {
        anchors.centerIn: parent

        backgroundColor: bannerColor
        running: portalInfoRequest.isBusy
        visible: running
    }

    //--------------------------------------------------------------------------

    Component {
        id: portalHighlight

        Rectangle {
            width: ListView.view ? ListView.view.currentItem.width : 0
            height: ListView.view ? ListView.view.currentItem.height : 0
            color: "darkgrey"
            radius: 2
            y: ListView.view ? ListView.view.currentItem.y : 0
            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: portalInfoRequest

        property url portalUrl
        property string text
        property bool isBusy: readyState == NetworkRequest.ReadyStateProcessing || readyState == NetworkRequest.ReadyStateSending

        method: "POST"
        responseType: "json"
        ignoreSslErrors: sslCheckBox.checked

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (status === 200) {

                    console.log("self:", JSON.stringify(response, undefined, 2));

                    if (response.isPortal && !response.supportsHostedServices) {
                        addPortalError.text = qsTr("Survey123 requires Portal for ArcGIS 10.3.1 or later configured with a Hosting Server and Portal for ArcGIS Data Store.");
                    } else {
                        portalVersionRequest.send();
                        infoRequest.send();
                    }
                }
            }
        }

        onErrorTextChanged: {
            console.error("addPortal error:", errorCode, errorText);

            switch (errorCode) {
            case 6:
                if (showExtraInfo) {
                    sslCheckBox.visible = true;
                }
                break;

            case 204:
                credentialsLayout.visible = true;
                break;
            }

            if (errorCode) {
                addPortalError.text = "%1 (%2)".arg(errorText).arg(errorCode);
            } else {
                addPortalError.text = "";
            }
        }

        function sendRequest(u) {
            portalUrl = u;
            url = portalUrl + "/sharing/rest/portals/self";

            var formData = {
                f: "pjson"
            };

            if (credentialsLayout.visible) {
                user = userField.text;
                password =  passwordField.text

                console.log("Setting network user:", user);
            } else {
                user = "";
                password = "";
            }

            send(formData);
        }

        function addPortal(version) {
            var info = response;

            var name = info.name;
            if (!(name > "")) {
                name = qsTr("%1 (%2)").arg(info.portalName).arg(portalUrl);
            }

            var singleSignOn = typeof info.user === "object" && !credentialsLayout.visible;
            var supportsOAuth = info.supportsOAuth && !(forceBuiltIn.checked && forceBuiltIn.visible) && !credentialsLayout.visible; // && !info.isPortal;

            var portalInfo = {
                url: portalUrl.toString(),
                name: name,
                ignoreSslErrors: sslCheckBox.checked,
                isPortal: info.isPortal,
                supportsOAuth: supportsOAuth,
                externalUserAgent: externalUserAgent.checked, // && supportsOAuth && portal.singleInstanceSupport,
                networkAuthentication: credentialsLayout.visible,
                singleSignOn: singleSignOn
            };

            var portalIndex = portalsList.append(portalInfo);

            portalsListView.currentIndex = portalIndex;
            portalUrlField.text = "";
            userField.text = "";
            passwordField.text = "";
            sslCheckBox.checked = false;
            externalUserAgent.checked = false; //portal.singleInstanceSupport;
            addPortalGroupBox.visible = false;
            credentialsLayout.visible = false;

            console.log("portalInfo:", JSON.stringify(portalsList.model.get(portalIndex), undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: portalVersionRequest

        url: portalInfoRequest.portalUrl + "/sharing/rest?f=json"
        responseType: "json"
        user: userField.text
        password: passwordField.text

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.currentVersion) {
                    var versionParts = response.currentVersion.split(".");
                    var versionMajor = versionParts.length > 0 ? Number(versionParts[0]) : 0;
                    var versionMinor = versionParts.length > 1 ? Number(versionParts[1]) : 0;
                    var version = combineVersionParts(versionMajor, versionMinor);

                    console.log("Portal version:", versionMajor, versionMinor, "response:", JSON.stringify(response, undefined, 2));

                    if (version >= kMinimumVersion) {
                        portalInfoRequest.addPortal(response.currentVersion);
                    } else {
                        addPortalError.text = qsTr("Survey123 requires Portal for ArcGIS 10.3.1 or later");
                    }
                } else {
                    console.error("Invalid version response:", JSON.stringify(response, undefined, 2));
                }
            }
        }

        onErrorTextChanged: {
            console.error("portalVersionRequest error", errorText);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: infoRequest

        url: portalInfoRequest.portalUrl + "/sharing/rest/info?f=json"
        responseType: "json"
        user: userField.text
        password: passwordField.text

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                console.log("info:", JSON.stringify(response, undefined, 2));
            }
        }

        onErrorTextChanged: {
            console.log("infoRequest error", errorText);
            //addPortalError.text = errorText;
        }
    }

    //--------------------------------------------------------------------------

    function combineVersionParts(major, minor) {
        return major + minor / 1000;
    }

    //--------------------------------------------------------------------------
}
