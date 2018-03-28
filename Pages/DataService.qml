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

    property var tag: null

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kGeometryPoint: "esriGeometryPoint"
    readonly property string kGeometryPolyline: "esriGeometryPolyline"
    readonly property string kGeometryPolygon: "esriGeometryPolygon"


    readonly property int kWGS84: 4326

    readonly property int kStatusReady: 0
    readonly property int kStatusInProgress: 1

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
                            console.log("Unable to parse value:", JSON.stringify(value));
                            //value = undefined;
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
        autoPolyEnd();
    }

    //--------------------------------------------------------------------------
    
    function createTables() {

        database.query("PRAGMA foreign_keys = ON;");

        database.query("CREATE TABLE IF NOT EXISTS Features (Status INTEGER, FeatureId TEXT UNIQUE, Timestamp NUMBER, LayerId NUMBER, TypeId TEXT, Feature TEXT)");
        database.query("CREATE TABLE IF NOT EXISTS Points (FeatureId TEXT, Timestamp NUMBER, Latitude NUMBER, Longitude NUMBER, Altitude NUMBER, FOREIGN KEY(FeatureId) REFERENCES Features(FeatureId) ON UPDATE CASCADE ON DELETE CASCADE)");
    }
    
    //--------------------------------------------------------------------------
    
    function insertPointFeature(properties, layerId, attributes) {
        console.log(JSON.stringify(properties));

        var position = properties.position;

        var layer = findLayer(layerId);

        var geometry = {
            x: position.coordinate.longitude,
            y: position.coordinate.latitude,
            spatialReference: {
                wkid: kWGS84
            }
        };

        if (layer.hasZ && position.altitudeValid) {
            geometry.z = position.coordinate.altitude;
        }

        var feature = {
            geometry: geometry,
            attributes: replaceVariables(layerId, clone(attributes), properties)
        }

        console.log("Insert layerId:", layerId, "feature:", JSON.stringify(feature, undefined, 2));

        var query = database.query("INSERT INTO Features (Status, Timestamp, LayerId, Feature) VALUES (?,?,?,?)",
                                   kStatusReady,
                                   position.timestamp.valueOf(),
                                   layerId,
                                   JSON.stringify(feature));

        console.log("insertId:", query.insertId);

        update();

        return query.insertId;
    }

    //--------------------------------------------------------------------------

    function replaceVariables(layerId, attributes, properties) {
        var keys = Object.keys(attributes);

        keys.forEach(function (key) {
            var field = findField(layerId, key);
            attributes[key] = replaceVariable(field, attributes[key], properties);
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

    function replaceVariable(field, value, properties) {
        if (debug) {
            console.log("replaceVariable field:", JSON.stringify(field), "value:", value, typeof value, "properties:", JSON.stringify(properties));
        }

        var position = properties.position;
        if (!position) {
            position = {};
        }

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

        if (field.type == "esriFieldTypeDate") {
            console.log("Date:", new Date(value));
            switch (value) {
            case -31575600000: // 1-Jan-1969
                if (properties.startDateTime) {
                    value = properties.startDateTime.valueOf();
                }
                break;

            case -126000000: // 31-Dec-1969
                if (properties.endDateTime) {
                    value = properties.endDateTime.valueOf();
                }
                break;
            }
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
                value = validValue(position.directionValid, position.direction);
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

            case "${tag}":
                value = tag;
                break;
            }
        }

        if (debug) {
            console.log("Return:", field.name, "=", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function count(status) {
        if (!status) {
            status = kStatusReady;
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
        var query = database.query("SELECT rowid, LayerId, Feature From Features WHERE Status = ? LIMIT 1", kStatusReady);
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

    function beginPoly(featureId, layerId, attributes, properties) {
        var feature = {
            attributes: replaceVariables(layerId, clone(attributes), properties)
        }

        console.log("Insert layerId:", layerId, "feature:", JSON.stringify(feature, undefined, 2));

        var query = database.query("INSERT INTO Features (Status, FeatureId, Timestamp, LayerId, Feature) VALUES (?,?,?,?,?)",
                                   kStatusInProgress,
                                   featureId,
                                   (new Date()).valueOf(),
                                   layerId,
                                   JSON.stringify(feature));

        console.log("beginPoly insertId:", query.insertId);
    }

    //--------------------------------------------------------------------------

    function endPoly(featureId, properties) {
        console.log("Ending poly:", featureId);

        var featureQuery = database.query("SELECT rowid, * FROM Features WHERE FeatureId = ?", featureId);

        if (!featureQuery.first()) {
            console.error("Error finding feature:", featureId);
            return;
        }

        var rowId = featureQuery.value("rowid");
        var layerId = featureQuery.value("LayerId");
        var feature = JSON.parse(featureQuery.value("Feature"));

        var layer = findLayer(featureQuery.value("LayerId"));

        featureQuery.finish();

        var pointsQuery = database.query("SELECT * FROM Points WHERE FeatureId = ? ORDER BY Timestamp", featureId);

        var points = [];
        var count = 0;

        var lastX;
        var lastY;

        if (pointsQuery.first()) {
            do {
                var x = pointsQuery.value("longitude");
                var y = pointsQuery.value("latitude");

                if (x === lastX && y === lastY) {
                    console.log("Skipping duplicate coordinate:", x, y);
                    continue;
                }

                var point = [x, y];

                points.push(point);

                count++;

            } while (pointsQuery.next());
        }


        var isPolygon = layer.geometryType === kGeometryPolygon;
        if (isPolygon && count) {
            console.log("Closing polygon");
            points.push(points[0]);
        }

        pointsQuery.finish();

        //console.log("count:", count, "points:", JSON.striginfy(points));

        var geometry = {
            spatialReference: {
                wkid: kWGS84
            }
        };

        geometry[isPolygon ? "rings": "paths"] = [ points ];

        feature.geometry = geometry;
        replaceVariables(layerId, feature.attributes, properties);

        console.log("End feature:", featureId, JSON.stringify(feature, undefined, 2));

        var updateQuery = database.query("UPDATE Features SET Status = ?, Feature = ? WHERE FeatureId = ?",
                                         kStatusReady,
                                         JSON.stringify(feature),
                                         featureId);


        console.log("endPoly rowsAffected:", updateQuery.rowsAffected);

        update();

        return rowId;
    }

    //--------------------------------------------------------------------------

    function insertPolyPoint(featureId, position) {
        var query = database.query("INSERT INTO Points (FeatureId, Timestamp, Latitude, Longitude, Altitude) VALUES (?,?,?,?,?)",
                                   featureId,
                                   position.timestamp.valueOf(),
                                   position.coordinate.latitude,
                                   position.coordinate.longitude,
                                   position.coordinate.altitude);

        console.log("insertPolyPoint insertId:", query.insertId);
    }

    //--------------------------------------------------------------------------

    function autoPolyEnd() {
        console.log("Checking for in progress features");

        var featureQuery = database.query("SELECT * FROM Features WHERE Status = ?", kStatusInProgress);

        if (!featureQuery.first()) {
            console.log("No features in progress");
            return;
        }

        do {
            var properties = {
                endDateTime: new Date()
            };

            endPoly(featureQuery.value("FeatureId"), properties);
        } while (featureQuery.next());

        featureQuery.finish();
    }

    //--------------------------------------------------------------------------

    function clone(o) {
        return JSON.parse(JSON.stringify(o));
    }

    //--------------------------------------------------------------------------
}
