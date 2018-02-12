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

ListModel {
    property int sortType: kSortTypeProperty
    property string sortOrder: kSortOrderAsc

    property string sortProperty
    property int sortCaseSensitivity: Qt.CaseInsensitive

    property var sortFunction

    readonly property int kSortTypeProperty: 0
    readonly property int kSortTypeFunction: 1

    readonly property string kSortOrderAsc: "asc"
    readonly property string kSortOrderDesc: "desc"

    property bool debug: false

    //--------------------------------------------------------------------------

    dynamicRoles: true

    //--------------------------------------------------------------------------

    function sort(begin, end)
    {
        if (!(sortProperty > "")) {
            console.error("Empty sortProperty");
            return;
        }

        if (begin === undefined) {
            begin = 0;
        }

        if (end === undefined) {
            end = count;
        }

        if (debug) {
            console.log("Sorting:", begin, "to:", end, "property:", sortProperty, sortOrder);
        }

        qsort(begin, end);
    }

    //--------------------------------------------------------------------------

    function qsort(begin, end)
    {
        if (end - 1 > begin) {
            var pivot = begin + Math.floor(Math.random() * (end - begin));

            switch (sortType) {
            case kSortTypeProperty:
                pivot = partition_property(begin, end, pivot);
                break;

            case kSortTypeFunction:
                if (typeof sortFunction !== 'function') {
                    console.error("Invalid sort function:", sortFunction);
                    return;
                }

                pivot = partition_function(begin, end, pivot);
                break;

            default:
                console.error("Invalid sort type:", sortType);
                return;
            }

            qsort(begin, pivot);
            qsort(pivot + 1, end);
        }
    }

    //--------------------------------------------------------------------------

    function partition_property(begin, end, pivot)
    {
        var pivotValue = get(pivot)[sortProperty];
        if (sortCaseSensitivity === Qt.CaseInsensitive) {
            pivotValue = toCaseInsensitive(pivotValue);
        }

        swap(pivot, end - 1);
        var store = begin;

        for (var index = begin; index < end - 1; index++) {
            var indexValue = get(index)[sortProperty];
            if (sortCaseSensitivity === Qt.CaseInsensitive) {
                indexValue = toCaseInsensitive(indexValue);
            }

            if (sortOrder === kSortOrderAsc && indexValue < pivotValue) {
                swap(store, index);
                store++;
            } else if (sortOrder === kSortOrderDesc && indexValue > pivotValue) {
                swap(store, index);
                store++;
            }
        }

        swap(end - 1, store);

        return store;
    }

    //--------------------------------------------------------------------------

    function partition_function(begin, end, pivot)
    {
        var pivotItem = get(pivot);

        swap(pivot, end - 1);
        var store = begin;

        for (var index = begin; index < end - 1; index++) {
            var indexItem = get(index);

            var v = sortFunction(indexItem, pivotItem);
            if (sortOrder === kSortOrderAsc && v < 0) {
                swap(store, index);
                store++;
            } else if (sortOrder === kSortOrderDesc && v > 0) {
                swap(store, index);
                store++;
            }
        }

        swap(end - 1, store);

        return store;
    }

    //--------------------------------------------------------------------------

    function swap(a, b) {
        if (a < b) {
            move(a, b, 1);
            move(b - 1, a, 1);
        }
        else if (a > b) {
            move(b, a, 1);
            move(a - 1, b, 1);
        }
    }

    //--------------------------------------------------------------------------

    function toCaseInsensitive(value) {
        if (!value) {
            return value;
        }

        if (typeof value !== "string") {
            return value;
        }

        return value.toString().toLocaleLowerCase();
    }

    //--------------------------------------------------------------------------

    function toggleSortOrder() {
        sortOrder = sortOrder === kSortOrderAsc ? kSortOrderDesc : kSortOrderAsc;

        if (debug) {
            console.log("Toggled sort order:", sortProperty, sortOrder);
        }
    }

    //--------------------------------------------------------------------------
}
