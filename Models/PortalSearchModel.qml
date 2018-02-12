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

import "Portal"
import "Models"

SortedListModel {
    id: itemsModel
    
    property bool busy: false
    property alias num: searchRequest.num
    property alias portal: searchRequest.portal
    property alias q: searchRequest.q
    property alias progress: searchRequest.searchProgress
    property bool debug

    property var resultCallback: null

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyDescription: "description"
    readonly property string kPropertyModified: "modified"

    signal searchCompleted();

    sortProperty: kPropertyTitle
    
    //--------------------------------------------------------------------------

    function sortItems() {
        sort();
    }

    //--------------------------------------------------------------------------

    function startSearch() {
        if (debug) {
            console.log("Searing for items:", q);
        }

        if (busy) {
            console.warn("Search in progress:", q);
            return;
        }

        itemsModel.clear();
        busy = true;
        searchRequest.search();
    }


    //--------------------------------------------------------------------------

    function infoUrl(itemId, infoFile) {
        return portal.restUrl + "/content/items/" + itemId + "/info/" + infoFile + (portal.signedIn ? "?token=" + portal.token : "")
    }

    //--------------------------------------------------------------------------

    onResultCallbackChanged: {
        if (resultCallback && typeof resultCallback !== "function") {
            console.error("resultCallback not a function:", typeof resultCallback);
        }
    }

    //--------------------------------------------------------------------------

    onSearchCompleted: {
        console.log("Search completed:", count, "item(s)");
    }

    //--------------------------------------------------------------------------

    readonly property PortalSearch searchRequest: PortalSearch {
        id: searchRequest

        sortField: "title"
        sortOrder: "asc"

        onSuccess: {
            response.results.forEach(function (result) {
                if (!result.description) {
                    result.description = "";
                }

                if (resultCallback) {
                    result = resultCallback(result);
                }

                if (result) {
                    itemsModel.append(result);

                    if (debug) {
                        console.log("searchResult:", JSON.stringify(result, undefined, 2));
                    }
                }
            });

            itemsModel.sortItems();

            if (response.nextStart > 0) {
                search(response.nextStart);
            } else {
                busy = false;
                searchCompleted();
            }
        }
    }

    //--------------------------------------------------------------------------
}
