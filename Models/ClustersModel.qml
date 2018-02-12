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
import QtPositioning 5.3

ListModel {
    id: clustersModel

    property var grid
    property real level: -1
    property real precision: 1000000
    property real tileSize
    property real cellSize
    property real tileCells: 8
    property real minimumCount
    property real maximumCount

    //--------------------------------------------------------------------------

    function reset() {
        clear();
        level = -1;
    }

    //--------------------------------------------------------------------------

    function initialize(zoomLevel) {
        clear();

        level = zoomLevel;
        grid = {};

        tileSize = 360 / Math.pow(2, zoomLevel);
        cellSize = Math.round(tileSize / tileCells * precision);

        // console.log("clusterLevel:", clusterLevel, "tileSize:", tileSize, "cellSize:", cellSize);
    }

    //--------------------------------------------------------------------------

    function addPoint(coordinate) {
        if (!coordinate || !coordinate.isValid) {
            return;
        }

        var x = Math.round((coordinate.longitude + 180) * precision);
        var y = Math.round((coordinate.latitude + 90) * precision);

        var xCell = Math.round(x / cellSize);
        var yCell = Math.round(y / cellSize);

        // console.log("i:", i, "x:", coordinate.longitude, x, "y:", coordinate.latitude, y, "xCell:", xCell, "yCell:", yCell);

        var row = grid[yCell];
        if (!row) {
            row = {};
            grid[yCell] = row;
        }

        var cell = row[xCell];
        if (!cell) {
            cell = {
                cx: xCell * cellSize / precision - 180,
                cy: yCell * cellSize / precision - 90,
                count: 0
            };
            row[xCell] = cell;
        }

        if (cell.count) {
            cell.xMin = Math.min(cell.xMin, coordinate.longitude);
            cell.xMax = Math.max(cell.xMax, coordinate.longitude);
            cell.yMin = Math.min(cell.yMin, coordinate.latitude);
            cell.yMax = Math.max(cell.yMax, coordinate.latitude);
        } else {
            cell.xMin = coordinate.longitude;
            cell.yMin = coordinate.latitude;
            cell.xMax = cell.xMin;
            cell.yMax = cell.yMin;
        }

        cell.count++;
    }

    //--------------------------------------------------------------------------

    function finalize() {
        // console.log("clusters grid:", JSON.stringify(grid, undefined, 2));

        minimumCount = 99999999;
        maximumCount = 0;

        Object.keys(grid).forEach(function (rowKey) {
            var row = grid[rowKey];
            Object.keys(row).forEach(function (cellKey) {
                var cell = row[cellKey];
                cell.ex = (cell.xMin + cell.xMax) / 2;
                cell.ey = (cell.yMin + cell.yMax) / 2;

                //console.log("cell:", JSON.stringify(cell, undefined, 2));

                minimumCount = Math.min(minimumCount, cell.count);
                maximumCount = Math.max(maximumCount, cell.count);

                append(cell);

            });
        });

        grid = undefined;
    }

    //--------------------------------------------------------------------------
}
