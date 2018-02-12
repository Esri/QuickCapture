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

import "../Portal"
import "../Models"

Item {
    id: databaseList

    property Portal portal
    property bool online
    property string path
    property alias model: model
    property bool debug: true
    property bool busy

    signal searchCompleted();
    signal searchResult(var itemInfo)

    //--------------------------------------------------------------------------

    readonly property string kDataServiceTag: "QuickCapture"

    //--------------------------------------------------------------------------

    SortedListModel {
        id: model
    }

    //--------------------------------------------------------------------------

    PortalSearch {
        id: portalSearch

        portal: databaseList.portal
        sortField: "modified"
        sortOrder: "desc"

        onSuccess: {
            response.results.forEach(function (result) {
                if (!result.description) {
                    result.description = "";
                }


                if (result) {
                    searchResult(result);

                    if (debug) {
                        console.log("searchResult:", JSON.stringify(result, undefined, 2));
                    }
                }
            });

//            itemsModel.sortItems();

            if (response.nextStart > 0) {
                search(response.nextStart);
            } else {
                busy = false;
                searchCompleted();
            }
        }
    }

    //--------------------------------------------------------------------------

    function refresh() {
        model.clear();

        console.log("Refresh:", path, portal.signedIn);

        var folder = AppFramework.fileFolder(path);

        var files = folder.fileNames("*.itemInfo");

        files.forEach(function(fileName) {
            var fileInfo = AppFramework.fileInfo(fileName);
            var name = fileInfo.baseName;

            var itemInfo = folder.readJsonFile(name + ".itemInfo");
            itemInfo.local = true;
            itemInfo.localPath = folder.path;
            itemInfo.localBaseName = name;
            itemInfo.thumbnailUrl = folder.fileUrl(name + "." + AppFramework.fileInfo(itemInfo.thumbnail).suffix).toString()
            itemInfo.updateAvailable = false;

            console.log("info:", JSON.stringify(info, undefined, 2));

            model.append(itemInfo);
        });

        if (online && portal.signedIn) {
            startSearch();
        }
    }

    //--------------------------------------------------------------------------

    onSearchResult: {
        console.log("search info:", JSON.stringify(itemInfo, undefined, 2));

        var thumbnailUrl = portal.restUrl + "/content/items/%1/info/%2?token=%3".arg(itemInfo.id).arg(itemInfo.thumbnail).arg(portal.token);

        for (var i = 0; i < model.count; i++) {
            var modelItemInfo = model.get(i);
            if (modelItemInfo.id === itemInfo.id) {

                if (itemInfo.modified > modelItemInfo.modified) {
                    console.log("Item modified:", itemInfo.id, new Date(itemInfo.modified), ">", new Date(modelItemInfo.modified));

                    model.setProperty(i, "thumbnailUrl", thumbnailUrl);
                    model.setProperty(i, "updateAvailable", true);
                    model.setProperty(i, "modified", itemInfo.modified);
                    model.setProperty(i, "title", itemInfo.title);
                    model.setProperty(i, "snippet", itemInfo.snippet);
                    model.setProperty(i, "description", itemInfo.description);
                }

                return;
            }
        }

        itemInfo.local = false;
        itemInfo.localPath = null;
        itemInfo.localBaseName = null;
        itemInfo.thumbnailUrl = thumbnailUrl;
        itemInfo.updateAvailable = false;

        model.append(removeArrayProperties(itemInfo));
    }

    //--------------------------------------------------------------------------

    function startSearch() {
        portalSearch.q = 'type:"Feature Service" AND (tags:"%1") AND ((NOT access:public) OR orgid:%2)'.arg(kDataServiceTag).arg(portal.user.orgId)

        if (debug) {
            console.log("Searching for items:", portalSearch.q);
        }

        if (busy) {
            console.warn("Search in progress:", portalSearch.q);
            return;
        }

        busy = true;
        portalSearch.search();
    }

    //--------------------------------------------------------------------------

    function removeArrayProperties(o) {
        if (!o || (typeof o !== "object")) {
            return o;
        }

        var keys = Object.keys(o);

        keys.forEach(function (key) {
            if (Array.isArray(o[key])) {
                delete o[key];
            }
        });

        return o;
    }

    //--------------------------------------------------------------------------
}
