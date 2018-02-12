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

SortedListModel {
    id: filteredModel

    property SortedListModel sourceModel
    property string filterText
    property int baseItems: 0

    property var filterFunction: defaultFilterFunction
    property var appendFunction
    property var filterProperties: ["title"]
    property int filterCaseSensitivity: sortCaseSensitivity

    readonly property bool filtered: filterText > ""
    readonly property ListModel visualModel: filtered ? filteredModel : sourceModel

    signal updated()

    //--------------------------------------------------------------------------

    sortProperty: sourceModel ? sourceModel.sortProperty : ""
    sortOrder: sourceModel ? sourceModel.sortOrder : kSortOrderAsc
    sortCaseSensitivity: sourceModel ? sourceModel.sortCaseSensitivity : Qt.CaseInsensitive

    //--------------------------------------------------------------------------

    onFilterTextChanged: {
        update();
    }

    //--------------------------------------------------------------------------

    function update() {
        clear();

        if (!sourceModel) {
            console.warn("Undefined filtered sourceModel");
            return;
        }

        if (!(filterText > "")) {
            console.log("Empty filterText")
            updated();
            return;
        }

        var filterPattern = new RegExp(filterText, filterCaseSensitivity == Qt.CaseInsensitive ? "i" : undefined);

        if (debug) {
            console.log("Filtering:", filterText, "baseItems:", baseItems, "of:", sourceModel.count);
        }

        var i;
        var item;

        for (i = 0; i < baseItems && i < sourceModel.count; i++ ) {
            if (appendFunction) {
                appendFunction(sourceModel.get(i));
            } else {
                append(sourceModel.get(i));
            }
        }

        for (i = baseItems; i < sourceModel.count; i++ ) {
            item = sourceModel.get(i);

            if (filterFunction(item, filterPattern)) {
                if (appendFunction) {
                    appendFunction(item, i);
                } else {
                    append(item);
                }
            }
        }

        sortItems();

        if (debug) {
            console.log("Filtered:", count, "of:", sourceModel.count);
        }

        updated();
    }

    //--------------------------------------------------------------------------

    function sortItems() {
        sort(baseItems);
    }

    //--------------------------------------------------------------------------

    function defaultFilterFunction(item, pattern) {
        for (var i = 0; i < filterProperties.length; i++) {
            var value = item[filterProperties[i]];
            if (value > "" && value.search(pattern) >= 0) {
                return true;
            }
        }
    }

    //--------------------------------------------------------------------------
}
