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

import ArcGIS.AppFramework 1.0


Item {
    id: _portal

    readonly property url kDefaultPortalUrl: "https://www.arcgis.com"

    readonly property bool signedIn: user && token > ""

    property string name: "ArcGIS Online"
    property url portalUrl: kDefaultPortalUrl
    property url tokenServicesUrl
    property url owningSystemUrl: portalUrl
    readonly property url restUrl: owningSystemUrl + "/sharing/rest"
    property string username
    property string password
    property string token
    property bool ssl: false
    property bool ignoreSslErrors: false
    property bool isPortal: false
    property bool busy: false
    property bool isBusy: false
    property bool clientMode: true
    property bool canPublish: false
    property bool supportsOAuth: true
    property bool externalUserAgent: false //singleInstanceSupport
    property bool networkAuthentication: false
    property string networkUsername
    property string networkPassword
    property bool singleSignOn: false
    property string currentVersion

    property App app
    property Settings settings
    property string settingsGroup: "Portal"

    readonly property string kSettingUrl: "url"
    readonly property string kSettingName: "name"
    readonly property string kSettingIgnoreSslErrors: "ignoreSslErrors"
    readonly property string kSettingIsPortal: "isPortal"
    readonly property string kSettingSupportsOAuth: "supportsOAuth"
    readonly property string kSettingExternalUserAgent: "externalUserAgent"
    readonly property string kSettingNetworkAuthentication: "networkAuthentication"
    readonly property string kSettingSingleSignOn: "singleSignOn"

    readonly property string kSettingUsername: "username"

    readonly property string kSettingRefreshToken: "refreshToken"
    readonly property string kSettingDateSaved: "dateSaved"


    property date expires
    property int expiryMode: expiryModeRefresh

    readonly property int expiryModeSignal: 0
    readonly property int expiryModeSignOut: 1
    readonly property int expiryModeSignIn: 2
    readonly property int expiryModeRefresh: 3
    readonly property int defaultExpiration: 120

    property int expiryMargin: 60000

    property var info: null
    property var user: null
    property url defaultUserThumbnail: "images/user.png"
    property url userThumbnailUrl: (token > "" && user && user.thumbnail)
                                   ? restUrl + "/community/users/" + user.username + "/info/" + user.thumbnail + "?token=" + token
                                   : defaultUserThumbnail


    readonly property string kRedirectOOB: "urn:ietf:wg:oauth:2.0:oob"

    property string redirectUri: kRedirectOOB
    property string authorizationCode: ""
    property var locale: Qt.locale()
    property string localeName: AppFramework.localeInfo(locale.uiLanguages[0]).esriName
    readonly property string authorizationEndpoint: portalUrl + "/sharing/rest/oauth2/authorize"
    readonly property string authorizationUrl: authorizationEndpoint + "?client_id=" + clientId + "&grant_type=code&response_type=code&expiration=-1&locale=%1&redirect_uri=%2".arg(localeName).arg(redirectUri)
    property string clientId: ""
    property string refreshToken: ""
    property date lastLogin
    property date lastRenewed

    property string signInReason

    property string userAgent

    property string redirectFileName: "approval"
    property string redirectHostPath: "localhost/oauth2/" + redirectFileName

    property string appInstallName: app ? app.info.title.replace(/[&\/\\#,+()\[\]$~%.'":*@^=\-_<>?!|;{}\s]/g, '') : ""
    property bool singleInstanceSupport: true//!(Qt.platform.os === "windows" || Qt.platform.os === "unix" || Qt.platform.os === "linux")
    property bool isStandaloneApp: Qt.application.name === appInstallName
    property string appScheme: app ? app.info.value("urlScheme") || "" : ""
    property string appRedirectUri: "%1://%2".arg(appScheme).arg(redirectHostPath)
    property bool useAppRedirectUri: singleInstanceSupport && isStandaloneApp && appScheme > ""

    property var checkUserPrivileges: _checkUserPrivileges


    signal expired()
    signal error(var error)
    signal credentialsRequest()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        userAgent = buildUserAgent(app);
        readSettings();
    }

    //--------------------------------------------------------------------------

    onPortalUrlChanged: {
        //signOut(true);
    }

    onSignedInChanged: {
        busy = false;
    }

    //--------------------------------------------------------------------------

    function signIn(reason, prompt) {

        signInReason = reason || ""

        console.log("signIn reason:", signInReason,
                    "canAutoSignIn:", canAutoSignIn(),
                    "prompt:", prompt);

        if (singleSignOn) {
            console.log("Single sign-on");

            autoSignIn();
        } else {
            if (!prompt && canAutoSignIn()) {
                autoSignIn();
            } else {
                credentialsRequest();
            }
        }
    }

    function signOut(reset) {
        console.log("signOut");
        token = "";
        user = null;
        canPublish = false;
        expiryTimer.stop();

        if (reset) {
            tokenServicesUrl = "";
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        onOpenUrl: {
            processApprovalUrl(url);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: Qt.application

        onStateChanged: {
            console.log("Application state changed:", Qt.application.state);
            switch (Qt.application.state) {
            case Qt.ApplicationActive:
                expiryTimer.reset();
                break;

//            case Qt.ApplicationInactive:
//            case Qt.ApplicationSuspended:
//                expiryTimer.stop();
//                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function setCredentials(username, password) {
        console.log("Setting credentials:", username);

        _portal.username = username;
        _portal.password = password;

        networkUsername = username;
        networkPassword = password;

        if (!AppFramework.network.isOnline) {
            return;
        }

        busy = true;

        builtInSignIn();
    }

    //--------------------------------------------------------------------------

    function setAuthorizationCode(authorizationCode) {
        busy = true;
        getTokenFromCode(clientId, redirectUri, authorizationCode);
    }

    //--------------------------------------------------------------------------

    function setRefreshToken(token) {
        refreshToken = token;

        if (refreshToken > "") {
            busy = true;
            getTokenFromRefreshToken(clientId, refreshToken);
        }
    }

    //--------------------------------------------------------------------------

    function setRequestCredentials(networkRequest, purpose) {
        if (networkAuthentication) {
            networkRequest.user = _portal.networkUsername;
            networkRequest.password = _portal.networkPassword;

            console.log("Setting network credentials for:", purpose, "user:", networkRequest.user);
        } else {
            //console.log("Clearing network credentials for:", purpose);

            networkRequest.user = "";
            networkRequest.password = "";
        }
    }

    //--------------------------------------------------------------------------

    function builtInSignIn() {
        if (!AppFramework.network.isOnline) {
            console.log("Not online")
            return;
        }

        console.log("Single sign-on");

        if (tokenServicesUrl > "") {
            generateToken.generateToken(username, password);
        } else {
            infoRequest.sendRequest();
        }
    }

    //--------------------------------------------------------------------------

    function canAutoSignIn() {
        if (!settings) {
            return false;
        }

        if (!supportsOAuth) {
            return false;
        }

        var refreshToken = settings.value(settingName(kSettingRefreshToken),"")

        return refreshToken > "";
    }

    function autoSignIn() {
        console.log("autoSignIn");

        if (!AppFramework.network.isOnline) {
            console.log("Network is offline");
            return;
        }

        if (!settings) {
            return;
        }

        console.log("Portal:: Trying to auto-sign-in ...");

        readSettings();

        if (singleSignOn) {
            builtInSignIn();
        } else {
            var refreshToken = settings.value(settingName(kSettingRefreshToken),"")
            var dateSaved = settings.value(settingName(kSettingDateSaved),"")

            lastLogin = dateSaved > "" ? new Date(dateSaved) : new Date()

            console.log("Portal:: Getting saved OAuth info: ", dateSaved, refreshToken);

            if (refreshToken > "") {
                console.log("Portal:: Found stored info, getting token now ...");
                getTokenFromRefreshToken(clientId, refreshToken);
            }
        }
    }

    //--------------------------------------------------------------------------

    function processApprovalUrl(url) {
        var urlInfo = AppFramework.urlInfo(url);

        // console.log("processApprovalUrl:", url, "fileName:", urlInfo.fileName, urlInfo.fileName.toLowerCase() !== redirectFileName);

        if (urlInfo.fileName.toLowerCase() !== redirectFileName) {
            return false;
        }

        var parameters = urlInfo.queryParameters;

        // console.log("Approval url parameters:", JSON.stringify(parameters, undefined, 2));

        if (parameters.code) {
            setAuthorizationCode(parameters.code);
        }
        else if (parameters.error) {
            var error = {
                message: parameters.error,
                details: [parameters.error_description]
            }

            _portal.error(error);
        }
        else {
            console.error("Unhandled approval url parameters:", JSON.stringify(parameters, undefined, 2));
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function writeSignedInState() {
        if (!settings) {
            return;
        }

        console.log("Storing signed in values:", settingsGroup);

        settings.setValue(settingName(kSettingRefreshToken), portal.refreshToken);
        settings.setValue(settingName(kSettingDateSaved), new Date().toString());

        writeUserSettings();
    }

    function clearSignedInState() {
        if (!settings) {
            return;
        }

        console.log("Clearing signed in values:", settingsGroup);

        settings.remove(settingName(kSettingRefreshToken));
        settings.remove(settingName(kSettingDateSaved));
        settings.remove(settingName("password"));
    }

    //--------------------------------------------------------------------------

    function autoLogin() {
        console.log("Portal:: Trying to auto-sign-in ...");

        if (localStorage) {
            var client_id = localStorage.value(settingsGroup + "/client_id","")
            var refresh_token = localStorage.value(settingsGroup + "/refresh_token","")
            var date_saved = localStorage.value(settingsGroup + "/date_saved","")

            _portal.lastLogin = date_saved > "" ? new Date(date_saved) : new Date()

            console.log("Portal:: Getting saved OAuth info: ", client_id, date_saved, refresh_token);

            if(client_id > "" && refresh_token > "") {
                console.log("Portal:: Found stored info, getting token now ...");
                _portal.getTokenFromRefreshToken(client_id, refresh_token);
            }
        }
    }

    //--------------------------------------------------------------------------

    function getTokenFromCode(client_id, redirect_uri, auth_code) {
        if(auth_code > "" && client_id > "") {
            _portal.refreshToken = "";
            _portal.clientId = client_id;

            var params = {
                grant_type: "authorization_code",
                code: auth_code,
                redirect_uri: redirect_uri
            };

            //console.log("getTokenFromCode:", JSON.stringify(params, undefined, 2));

            oAuthAccessTokenFromAuthCodeRequest.sendRequest(params);
        }
    }

    //--------------------------------------------------------------------------

    function getTokenFromRefreshToken(client_id, refresh_token) {
        if(refresh_token > "" && client_id > "") {
            _portal.refreshToken = refresh_token;
            _portal.clientId = client_id;

            var params = {
                grant_type: "refresh_token",
                refresh_token: refresh_token
            };

            //console.log("getTokenFromRefreshToken:", JSON.stringify(params, undefined, 2));

            oAuthAccessTokenFromAuthCodeRequest.sendRequest(params);
        }
    }

    //--------------------------------------------------------------------------

    function renew() {
        console.log("!!! Inside portal renew !!!");
        console.log(_portal.refreshToken, _portal.clientId)
        if (_portal.refreshToken > "" && _portal.clientId > "") {
            getTokenFromRefreshToken(_portal.clientId, _portal.refreshToken)
        }
        else {
            signOut();
        }
    }

    NetworkRequest {
        id: oAuthAccessTokenFromAuthCodeRequest

        url: portalUrl + "/sharing/rest/oauth2/token"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                console.log("oauth token info:", JSON.stringify(response, undefined, 2));

                if (response.error) {
                    _portal.error(response.error);
                    _portal.isBusy = false;
                    signOut();
                } else {
                    if (response.refresh_token) {
                        _portal.refreshToken = response.refresh_token;
                    }
                    _portal.username = response.username || "";

                    var now = new Date();
                    _portal.lastRenewed = now;

                    setToken(response.access_token || "", new Date(now.getTime() + response.expires_in*1000));

                    logAdditionalInformation.sendRequest({ "f": "json" });

                    _portal.isBusy = false;

                    versionRequest.headers.userAgent = _portal.userAgent;
                    versionRequest.send();
                    selfRequest.sendRequest();
                }
            }
        }

        onErrorTextChanged: {
            _portal.isBusy = false;
            console.log("oAuthAccessTokenRequest error", errorText);
            signOut();
        }

        function sendRequest(params) {
            expiryTimer.stop();

            headers.userAgent = _portal.userAgent;
            params.client_id =  _portal.clientId;

            // console.log("Requesting oauth token:", JSON.stringify(params, undefined, 2));

            _portal.isBusy = true;

            send(params);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: logAdditionalInformation
        url: restUrl + "/community/users/%1".arg(_portal.username)
        method: "POST"

        onReadyStateChanged: {
        }

        function sendRequest(params){
            headers.userAgent = _portal.userAgent;
            params.client_id =  _portal.clientId;
            send(params);
        }
    }

    //--------------------------------------------------------------------------

    function setToken(token, expires) {
        _portal.token = token;
        _portal.expires = expires;

        expiryTimer.reset();
    }

    //--------------------------------------------------------------------------

    function validateToken() {
        if (token > "" && (expires - Date.now()) < expiryMargin) {
            console.log("Clearing expired token");
            token = "";
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: expiryTimer

        onRunningChanged: {
            if (running) {
                console.log("Token expiry timer will trigger in %1 minutes".arg(interval/60000));
            } else {
                console.log("Token expiry timer disabled");
            }
        }

        onTriggered: {
            switch (expiryMode) {
            case expiryModeSignIn:
                signIn();
                break;

            case expiryModeSignOut:
                signOut();
                break;

            case expiryModeRefresh:
                renew();
                break;

            default:
                expired();
                break;
            }
        }

        function reset() {
            stop();

            if (token > "" && expires.valueOf()) {
                var msec = expires - Date.now() - expiryMargin;
                if (msec > expiryMargin) {
                    interval = msec;
                    restart();
                    console.log("Reset token expiry timer:", expires, "minutes:", interval / 60000);
                } else {
                    console.log("Triggering expiry action:", msec, "<", expiryMargin);
                    triggered();
                }
            } else {
                console.log("Token expiry timer not restarted");
            }
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: infoRequest

        url: portalUrl + "/sharing/rest/info?f=json"
        responseType: "json"
        ignoreSslErrors: portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                //console.log("info:", JSON.stringify(response, undefined, 2));

                if (response.authInfo) {
                    tokenServicesUrl = response.authInfo.tokenServicesUrl;
                    owningSystemUrl = response.owningSystemUrl;
                    generateToken.generateToken(_portal.username, _portal.password);
                }
            }
        }

        onErrorTextChanged: {
            console.log("infoRequest error", errorText);

            var details = "";
            if (errorCode === 204) {
                details = responseText;

                console.error("infoRequest user:", user);
            }

            portal.error( { message: errorText, details: details });
        }

        function sendRequest() {
            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "infoRequest");
            send();
        }
    }

    NetworkRequest {
        id: generateToken

        url: tokenServicesUrl
        method: "POST"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors
        uploadPrefix: ""

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.error) {
                    console.error("genetateToken error for:", user, username, "error:", JSON.stringify(response.error, undefined, 2));
                    portal.error(response.error);
                } else if (response.token) {
                    console.log("username", username, "generateToken:", JSON.stringify(response, undefined, 2));
                    ssl = response.ssl;
                    setToken(response.token, new Date(response.expires));

                    // Adjusting our URLS to be SSL-only based on the SSL property obtained from getToken call

                    if (ssl) {
                        portalUrl = httpsUrl(portalUrl);
                        owningSystemUrl = httpsUrl(owningSystemUrl);
                    }

                    versionRequest.sendRequest();
                    selfRequest.sendRequest();
                } else {
                    //
                }
            }
        }

        onErrorTextChanged: {
            console.error("generateToken error:", errorText);

            var details = "";
            if (errorCode === 204) {
                details = responseText;

                console.error("generateToken user:", user);
            }

            portal.error( { message: errorText, details: details });
        }

        function httpsUrl(url) {
            var urlInfo = AppFramework.urlInfo(url);

            urlInfo.scheme = "https";

            console.log("httpsUrl", url, "->", urlInfo.url);

            return urlInfo.url;
        }

        function generateToken(username, password, expiration, referer) {
            if (!expiration) {
                expiration = defaultExpiration;
            }

            if (!referer) {
                referer = portalUrl;
            }

            var formData = {
                "username": username,
                "password": password,
                "referer": referer,
                "expiration": expiration,
                "f": "json"
            };

            headers.userAgent = _portal.userAgent;

            setRequestCredentials(this, "generateToken");
            send(formData);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: selfRequest

        url: restUrl + "/portals/self"
        method: "POST"
        responseType: "json"
        ignoreSslErrors: _portal.ignoreSslErrors

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                // console.log("portal self:", JSON.stringify(response, undefined, 2));

                _portal.info = response;
                if (_portal.info && _portal.info.allSSL) {
                    ssl = _portal.info.allSSL;
                }

                if (_portal.info.user) {
                    var privilegeError = checkUserPrivileges
                            ? checkUserPrivileges(_portal.info.user)
                            : undefined;

                    if (privilegeError) {
                        _portal.error(privilegeError);
                        _portal.signOut();
                    } else {
                        _portal.username = _portal.info.user.username;
                        _portal.user = _portal.info.user;

                        //Use default user icon if thumbnail is not set in users profile
                        if (!_portal.user.thumbnail) {
                            _portal.userThumbnailUrl = defaultUserThumbnail;
                        }

                        console.log("portal user:", JSON.stringify(_portal.user, undefined, 2));
                    }
                }
            }
        }

        onErrorTextChanged: {
            console.error("selfRequest error:", errorText);
        }

        function sendRequest() {
            var formData = {
                f: "pjson"
            };

            if (_portal.token > "") {
                formData.token = _portal.token;
            }

            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "portalSelf");
            send(formData);
        }
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: versionRequest

        url: restUrl + "?f=json"
        responseType: "json"

        onReadyStateChanged: {
            if (readyState === NetworkRequest.ReadyStateComplete)
            {
                if (response.currentVersion) {
                    currentVersion = response.currentVersion;
                    console.log("Portal currentVersion:", currentVersion);
                } else {
                    console.error("Invalid version response:", JSON.stringify(response, undefined, 2));
                }
            }
        }

        onErrorTextChanged: {
            console.error("versionRequest error", errorText);
        }

        function sendRequest() {
            headers.userAgent = _portal.userAgent;
            setRequestCredentials(this, "versionRequest");
            send();
        }
    }

    //--------------------------------------------------------------------------

    function settingName(name) {
        return settingsGroup + "/" + name;
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        if (!settings) {
            return false;
        }

        portalUrl = settings.value(settingName(kSettingUrl), "https://www.arcgis.com");
        name = settings.value(settingName(kSettingName), "ArcGIS Online");
        ignoreSslErrors = settings.boolValue(settingName(kSettingIgnoreSslErrors), false);
        isPortal = settings.boolValue(settingName(kSettingIsPortal), false);
        supportsOAuth = settings.boolValue(settingName(kSettingSupportsOAuth), true);
        externalUserAgent = settings.boolValue(settingName(kSettingExternalUserAgent), false); //singleInstanceSupport);
        networkAuthentication = settings.boolValue(settingName(kSettingNetworkAuthentication), false);
        singleSignOn = settings.boolValue(settingName(kSettingSingleSignOn), false);

        updateRedirectUri();

        console.log("Portal settings:", name,
                    "url:", portalUrl,
                    "isPortal:", isPortal,
                    "ignoreSslErrors:", ignoreSslErrors,
                    "supportsOAuth:", supportsOAuth,
                    "redirectUri:", redirectUri,
                    "externalUserAgent:", externalUserAgent,
                    "networkAuthentication:", networkAuthentication,
                    "singleSignOn:", singleSignOn);

        readUserSettings();

        console.log("appName:", Qt.application.name, "installName:", appInstallName, "standalone:", isStandaloneApp, "singleInstance:", singleInstanceSupport, "appRedirect:", appRedirectUri, useAppRedirectUri);

        return true;
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        if (!settings) {
            return false;
        }

        console.log("Write portal settings:", name,
                    "url:", portalUrl,
                    "isPortal:", isPortal,
                    "ignoreSslErrors:", ignoreSslErrors,
                    "supportsOAuth:", supportsOAuth,
                    "redirectUri:", redirectUri,
                    "externalUserAgent:", externalUserAgent,
                    "networkAuthentication:", networkAuthentication,
                    "singleSignOn:", singleSignOn);

        settings.setValue(settingName(kSettingUrl), portalUrl);
        settings.setValue(settingName(kSettingName), name);
        settings.setValue(settingName(kSettingIgnoreSslErrors), ignoreSslErrors);
        settings.setValue(settingName(kSettingIsPortal), isPortal);
        settings.setValue(settingName(kSettingSupportsOAuth), supportsOAuth);
        settings.setValue(settingName(kSettingExternalUserAgent), externalUserAgent);
        settings.setValue(settingName(kSettingNetworkAuthentication), networkAuthentication);
        settings.setValue(settingName(kSettingSingleSignOn), singleSignOn);

        return true;
    }

    //--------------------------------------------------------------------------

    function readUserSettings() {
        if (!settings) {
            return false;
        }

        username = settings.value(settingName(kSettingUsername), "");

        //        if (autoSignIn) {
        //            password = rot13(settings.value(settingsGroup + "/password", ""));
        //        }

        return true;
    }

    function writeUserSettings() {
        if (!settings) {
            return false;
        }

        settings.setValue(settingName(kSettingUsername), portal.username);

        //        if (autoSignIn) {
        //            settings.setValue(settingsGroup + "/password", rot13(portal.password));
        //        } else {
        //            settings.remove(settingsGroup + "/password");
        //        }
    }

    function clearUserSettings() {
        if (!settings) {
            console.warn("clearUserSettings: Sign In settings not persisted");
            return false;
        }

        console.log("Clearing user credentials");

        settings.remove(settingName(kSettingUsername));
        settings.remove(settingName("password"));
    }

    //--------------------------------------------------------------------------

    function rot13(s) {
        return s.replace(/[A-Za-z]/g, function (c) {
            return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".charAt(
                        "NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm".indexOf(c)
                        );
        } );
    }

    //--------------------------------------------------------------------------

    function buildUserAgent(app) {
        var userAgent = "";

        function addProduct(name, version, comments) {
            if (!(name > "")) {
                return;
            }

            if (userAgent > "") {
                userAgent += " ";
            }

            name = name.replace(/\s/g, "");
            userAgent += name;

            if (version > "") {
                userAgent += "/" + version.replace(/\s/g, "");
            }

            if (comments) {
                userAgent += " (";

                for (var i = 2; i < arguments.length; i++) {
                    var comment = arguments[i];

                    if (!(comment > "")) {
                        continue;
                    }

                    if (i > 2) {
                        userAgent += "; "
                    }

                    userAgent += arguments[i];
                }

                userAgent += ")";
            }

            return name;
        }

        function addAppInfo(app) {
            var deployment = app.info.value("deployment");
            if (!deployment || typeof deployment !== 'object') {
                deployment = {};
            }

            var appName = deployment.shortcutName > ""
                    ? deployment.shortcutName
                    : app.info.title;

            var udid = app.settings.value("udid", "");

            appName = addProduct(appName, app.info.version, Qt.locale().name, AppFramework.currentCpuArchitecture, udid)

            return appName;
        }

        if (app) {
            addAppInfo(app);
        } else {
            addProduct(Qt.application.name, Qt.application.version, Qt.locale().name, AppFramework.currentCpuArchitecture, Qt.application.organization);
        }

        addProduct(Qt.platform.os, AppFramework.osVersion, AppFramework.osDisplayName);
        addProduct("AppFramework", AppFramework.version, "Qt " + AppFramework.qtVersion, AppFramework.buildAbi);
        addProduct(AppFramework.kernelType, AppFramework.kernelVersion);

        // console.log("userAgent:", userAgent);

        return userAgent;
    }

    //--------------------------------------------------------------------------

    function setPortal(portalInfo) {

        console.log("setPortal:", JSON.stringify(portalInfo, undefined, 2));

        signOut(true);

        name = portalInfo.name;
        ignoreSslErrors = portalInfo.ignoreSslErrors;
        isPortal = portalInfo.isPortal;
        supportsOAuth = portalInfo.supportsOAuth;
        portalUrl = portalInfo.url;
        externalUserAgent = portalInfo.externalUserAgent;
        networkAuthentication = portalInfo.networkAuthentication;
        singleSignOn = portalInfo.singleSignOn;

        writeSettings();

        updateRedirectUri();
    }

    //--------------------------------------------------------------------------

    function updateRedirectUri() {
        redirectUri = kRedirectOOB;
        if (externalUserAgent && supportsOAuth) {
            if (useAppRedirectUri) {
                redirectUri = appRedirectUri;
            }
        }

        console.log("updateRedirectUri:", redirectUri);
        console.log("appName:", Qt.application.name, "installName:", appInstallName, "standalone:", isStandaloneApp, "singleInstance:", singleInstanceSupport, "appRedirect:", appRedirectUri, useAppRedirectUri);
    }

    //--------------------------------------------------------------------------

    function _checkUserPrivileges(userInfo) {
        console.log("Checking privileges for:", userInfo.username);

        //Need to handle three usecases
        //1. Public Account Free user (no ORG ID) #242
        //2. Survey123 client app needs atleast feature editing permissions #new
        //3. Survey123 Connect app needs atleast 3 permission #154

        var privileges = userInfo.privileges;
        if (!Array.isArray(privileges)) {
            privileges = [];
        }

        var canPublish = privileges.indexOf("portal:publisher:publishFeatures") >= 0;
        var canShare = privileges.indexOf("portal:user:shareToGroup") >= 0;
        var canCreate = privileges.indexOf("portal:user:createItem") >= 0;
        var canEdit = privileges.indexOf("features:user:edit") >= 0;

        var error;

        if (clientMode) {
            if (!canEdit) {
                console.warn("Insufficient Client Privileges");

                error = {
                    message: qsTr("Insufficient Client Privileges"),
                    details: qsTr("Need minimum privileges of Features Edit in your Role. Please contact your ArcGIS Administrator to resolve this issue.")
                }
            }
        } else {
            //this is the connect app and need more privileges
            if (!canCreate || !canPublish || !canShare) {
                //need to alert that this account does not have sufficient privileges
                console.warn("Insufficient Privileges")

                error = {
                    message: qsTr("Insufficient Client Privileges"),
                    details: qsTr("Need minimum privileges of Create content, Publish hosted feature layers and Share with groups in your Role. Please contact your ArcGIS Administrator to resolve this issue.")
                }

                _portal.canPublish = false
            } else {
                _portal.canPublish = true
            }
        }

        return error;
    }

    //--------------------------------------------------------------------------
}
