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
import QtQuick.Controls 1.4

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Sql 1.0

import "../Portal"

Item {
    id: dataService

    property Portal portal
    property alias folder: folder
    property alias database: database
    property UserInfo userInfo


    property Settings settings
    property var itemInfo: null
    property var featureServiceInfo: null
    property url thumbnail

    readonly property bool isOpen: itemInfo && featureServiceInfo && database.isOpen
    readonly property string title: itemInfo ? itemInfo.title : ""

    readonly property string kSuffixSettings: "settings"
    readonly property string kSuffixItemInfo: "itemInfo"
    readonly property string kSuffixFeatureServiceInfo: "serviceInfo"
    readonly property string kSuffixDatabase: "sqlite"

    readonly property string kOptionsTag: "//"

    readonly property string kNull: "null"

    //readonly property string kSettingZMode: "zMode"

    property bool updating
    property bool uploading
    property int points

    //--------------------------------------------------------------------------

    signal created()
    signal ready();
    signal opened();
    signal uploaded();
    signal downloaded();
    signal deleted();

    //--------------------------------------------------------------------------

    onIsOpenChanged: {
        if (isOpen) {
            update();
            opened();
        } else {
            points = -1;
        }
    }

    //--------------------------------------------------------------------------

    function sync(itemId) {
        if (!itemId) {
            itemId = itemInfo.id;
        }

        close();

        console.log("DataService.sync:", itemId);

        updating = true;

        portalItem.itemId = itemId;
        portalItem.requestInfo();
    }

    //--------------------------------------------------------------------------

    function open(itemId) {
        console.log("DataService.open:", itemId);

        close();

        if (!(itemId > "")) {
            return;
        }

        itemInfo = folder.readJsonFile("%1.%2".arg(itemId).arg(kSuffixItemInfo));
        featureServiceInfo = folder.readJsonFile("%1.%2".arg(itemId).arg(kSuffixFeatureServiceInfo));
        if (itemInfo.thumbnail > "") {
            var thumbnailSuffix = AppFramework.fileInfo(itemInfo.thumbnail).suffix;
            thumbnail = folder.fileUrl("%1.%2".arg(itemId).arg(thumbnailSuffix));
        } else {
            thumbnail = "images/data-thumbnail.png";
        }

        itemInfo.thumbnailUrl = thumbnail;

        settings = folder.settingsFile("%1.%2".arg(itemId).arg(kSuffixSettings));

        readSettings();

        openDb();

        ready();

        return true;
    }

    //--------------------------------------------------------------------------

    function close() {
        itemInfo = null;
        featureServiceInfo = null;
        database.close();
        settings = null;

        gc();
    }

    //--------------------------------------------------------------------------

    function deleteFiles() {
        var itemId = itemInfo.id;
        var files = folder.fileNames(itemId + ".*");

        console.log("Delete dataService files:", itemId);

        close();

        files.forEach(function(fileName) {
            var deleted = folder.removeFile(fileName);
            console.log("Deleted:", deleted, "fileName:", fileName)
        });

        deleted();
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        //zMode = settings.numberValue(kSettingZMode, 0);

        log();
    }

    //--------------------------------------------------------------------------

    function saveSettings() {
        //settings.setValue(kSettingZMode, zMode);

        log();
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log("Data source:", itemInfo.id);

        console.log("title:", title);
    }

    //--------------------------------------------------------------------------

    function parseText(text) {
        if (!text) {
            return "";
        }

        var i = text.indexOf(kOptionsTag);
        if (i < 0) {
            return text;
        }

        return text.substring(0, i);
    }

    //--------------------------------------------------------------------------

    function parseOptions(text) {
        if (!text) {
            return {};
        }

        var i = text.indexOf(kOptionsTag);
        if (i < 0) {
            return {};
        }

        var optionsText = text.substring(i + kOptionsTag.length);

        var optionsMatch = optionsText.match(/((?:\\.|[^=,]+)*)=("(?:\\.|[^"\\]+)*"|(?:\\.|[^,"\\]+)*)/g);

        var options = {};

        if (Array.isArray(optionsMatch)) {
            optionsMatch.forEach(function (keyValue) {
                var i = keyValue.indexOf("=");
                if (i > 0) {
                    var key = keyValue.substring(0, i).trim();
                    var value = keyValue.substring(i + 1).trim();

                    if (key > "" && value > "") {
                        try {
                            value = JSON.parse('{"value":%1}'.arg(value)).value;
                        } catch (e) {
                            console.log("Unable to parse value:", value);
                            value = undefined;
                        }

                        try {
                            options[key] = value;
                        } catch (e) {
                            console.log("Unable to set key:", key, "value:", value);
                        }
                    }
                }

            });
        }

        return options;
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: folder
    }

    //--------------------------------------------------------------------------

    SqlDatabase {
        id: database
    }

    //--------------------------------------------------------------------------

    PortalItem {
        id: portalItem

        portal: dataService.portal

        onItemInfoDownloaded: {
            dataService.itemInfo = portalItem.itemInfo;
            featureServiceInfoRequest.request();
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: featureServiceInfoRequest
        
        portal: dataService.portal
        responseType: "json"
        method: "POST"
        
        onSuccess: {
            featureServiceInfo = response;
            thumbnailRequest.request();
        }
        
        onFailed: {
            console.log("featureServiceInfoRequest error:", JSON.stringify(error, undefined, 2));
        }
        
        function request(layerId) {
            console.log("Requesting featureServiceInfo for layerId:", layerId);

            url = itemInfo.url + "/%1".arg(typeof layerId === "number" ? layerId : "layers");
            sendRequest();
        }
    }
    
    //--------------------------------------------------------------------------
    
    PortalRequest {
        id: thumbnailRequest
        
        portal: dataService.portal
        
        onSuccess: {
            updating = false;
            downloaded();
            createDb();
        }
        
        onFailed: {
        }
        
        onProgressChanged: {
        }
        
        function request() {
            if (!(itemInfo.thumbnail > "")) {
                return;
            }
            
            var fileInfo = AppFramework.fileInfo(itemInfo.thumbnail);
            responsePath = folder.filePath("%1.%2".arg(itemInfo.id).arg(fileInfo.suffix));
            url = portal.restUrl + "/content/items/%1/info/%2".arg(itemInfo.id).arg(itemInfo.thumbnail);
            
            sendRequest();
        }
    }
    
    //--------------------------------------------------------------------------
    
    function createDb() {
        var itemId = itemInfo.id;

        console.log("createDb itemInfo:", itemId, "featureServiceInfo:", JSON.stringify(featureServiceInfo, undefined, 2));
        
        folder.writeJsonFile("%1.%2".arg(itemId).arg(kSuffixItemInfo), itemInfo);
        folder.writeJsonFile("%1.%2".arg(itemId).arg(kSuffixFeatureServiceInfo), featureServiceInfo);

        openDb();

        created();
        ready();
    }

    //--------------------------------------------------------------------------

    function openDb() {
        database.databaseName = folder.filePath(itemInfo.id + "." + kSuffixDatabase);

        if (!database.open()) {
            console.error("Error opening database:", database.databaseName);

            return;
        }

        createTables();
    }

    //--------------------------------------------------------------------------
    
    function createTables() {
        database.query("CREATE TABLE IF NOT EXISTS Features (Status INTEGER, Timestamp DATE, Latitude REAL, Longitude REAL, Speed REAL, LayerId NUMBER, TypeId TEXT, Feature TEXT)");
    }
    
    //--------------------------------------------------------------------------
    
    function insertFeature(position, layerId, attributes) {
        console.log(JSON.stringify(position));

        var layer = findLayer(layerId);

        var geometry = {
            x: position.coordinate.longitude,
            y: position.coordinate.latitude,
            spatialReference: {
                wkid: 4326
            }
        };

        if (layer.hasZ && position.altitudeValid) {
            geometry.z = position.coordinate.altitude;
        }

        var feature = {
            geometry: geometry,
            attributes: replaceVariables(layerId, JSON.parse(JSON.stringify(attributes)), position)
        }

        console.log("Insert layerId:", layerId, "feature:", JSON.stringify(feature, undefined, 2));

        var query = database.query("INSERT INTO Features (Status, Timestamp, Latitude, Longitude, Speed, LayerId, Feature) VALUES (?,?,?,?,?,?,?)",
                                   0,
                                   position.timestamp.toString(),
                                   position.coordinate.latitude,
                                   position.coordinate.longitude,
                                   position.speed,
                                   layerId,
                                   JSON.stringify(feature));

        console.log("insertId:", query.insertId);

        update();

        return query.insertId;
    }

    //--------------------------------------------------------------------------

    function replaceVariables(layerId, attributes, position) {

        var keys = Object.keys(attributes);

        keys.forEach(function (key) {
            var field = findField(layerId, key);
            attributes[key] = replaceVariable(field, attributes[key], position);
        });

        return attributes;
    }

    //--------------------------------------------------------------------------

    //  0000   timestamp
    //  0010   latitude
    //  0020   longitude
    //  0030   altitude
    //  0040   horizontalAccuracy
    //  0050   verticalAccuracy
    //  0060   speed - M/S
    //  0061   speed - KPH
    //  0062   speed - MPH
    //  0063   speed - KTS
    //  0070   verticalSpeed - M/S
    //  0071   verticalSpeed - KPH
    //  0072   verticalSpeed - MPH
    //  0073   verticalSpeed - KTS
    //  0080   direction
    //  0090   magneticVariation

    function replaceVariable(field, value, position) {
        //console.log("field:", JSON.stringify(field), "value:", value);

        function validValue(isValid, validValue, invalidValue) {
            if (typeof invalidValue === "undefined") {
                invalidValue = null;
            }

            return isValid ? validValue : invalidValue;
        }

        function validSpeed(isValid, speedUnits, speed, invalidValue) {
            if (!isValid) {
                return invalidValue;
            }

            switch (speedUnits) {
            case 1: // KPH
                speed *= 3.6;
                break;

            case 2: // MPH
                speed *= 2.23694;
                break;

            case 3: // KTS
                speed *= 1.94384;
                break;
            }

            return speed;
        }


        if (typeof value === "number") {
            var valueType = -value - 99990000;

            if (valueType < 0 || valueType > 9999) {
                return value;
            }

            //console.log("value:", value, valueType);

            switch (valueType) {
            case 0:
                value = position.timestamp.valueOf();
                break;

            case 10:
                value = validValue(position.latitudeValid, position.coordinate.latitude);
                break;

            case 20:
                value = validValue(position.longitudeValid, position.coordinate.longitude);
                break;

            case 30:
                value = validValue(position.altitudeValid, position.coordinate.altitude);
                break;

            case 40:
                value = validValue(position.horizontalAccuracyValid, position.horizontalAccuracy);
                break;

            case 50:
                value = validValue(position.verticalAccuracyValid, position.verticalAccuracy);
                break;

            case 60:
            case 61:
            case 62:
            case 63:
                value = validSpeed(position.speedValid, valueType - 60, position.speed);
                break;

            case 70:
            case 71:
            case 72:
            case 73:
                value = validSpeed(position.verticalSpeedValid, valueType - 70, position.verticalSpeed);
                break;

            case 80:
                value = validValue(position.direcitonValid, position.direction);
                break;

            case 90:
                value = validValue(position.magneticVariationValid, position.magneticVariation);
                break;

            default:
                console.warn("Unknown numeric variable:", key, "=", value);
                break;
            }

        } else if (typeof value === "string") {
            switch (value) {
            case "${username}":
                value = userInfo.info.username;
                break;
            }
        }

        // console.log("Return:", key, "=", value);

        return value;
    }

    //--------------------------------------------------------------------------

    function count(status) {
        if (!status) {
            status = 0;
        }

        var query = database.query("SELECT COUNT(*) FROM Features WHERE Status = ?", status);
        if (!query.first()) {
            return 0;
        }

        return query.value(0);
    }

    //--------------------------------------------------------------------------

    function deleteRow(rowId) {
        var query = database.query("DELETE FROM Features WHERE rowid = ?", rowId);

        console.log("rows deleted:", query.rowsAffected);

        update();
    }

    //--------------------------------------------------------------------------

    function deleteAll() {
        var query = database.query("DELETE FROM Features");

        console.log("rows deleted:", query.rowsAffected);

        update();
    }

    //--------------------------------------------------------------------------

    function findLayer(layerId) {
        for (var i = 0; i < featureServiceInfo.layers.length; i++) {
            var layer = featureServiceInfo.layers[i];

            if (layer.id === layerId) {
                return layer;
            }
        }
    }

    //--------------------------------------------------------------------------

    function findField(layerId, fieldName) {
        var layer = findLayer(layerId);

        for (var i = 0; i < layer.fields.length; i++) {
            var field = layer.fields[i];

            if (field.name === fieldName) {
                return field;
            }
        }
    }

    //--------------------------------------------------------------------------

    function upload() {
        if (!portal.signedIn) {
            console.error("Not signed in");
            return;
        }

        uploading = true;
        uploadNext();
    }

    function uploadNext() {
        var query = database.query("SELECT rowid, LayerId, Feature From Features WHERE Status = 0 LIMIT 1");
        if (!query.first()) {
            console.log("End of data reached");
            uploading = false;
            return;
        }

        addFeatureRequest.addFeature(query.values);
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: addFeatureRequest

        portal: dataService.portal
        trace: true

        property var rowId

        onSuccess: {
            deleteRow(rowId);
            uploaded();
            uploadNext();
        }

        onError: {
            console.error("AddFeatures failed");
        }

        function addFeature(rowData) {
            console.log("Adding:", JSON.stringify(rowData, undefined, 2));

            var feature = JSON.parse(rowData.Feature);
            var features = [ feature ];

            var formData = {
                features: JSON.stringify(features)
            };

            url = "%1/%2/addFeatures".arg(itemInfo.url).arg(rowData.LayerId);
            rowId = rowData.rowid;

            sendRequest(formData);
        }
    }

    //--------------------------------------------------------------------------

    function update() {
        points = dataService.count();
    }

    //--------------------------------------------------------------------------
}
