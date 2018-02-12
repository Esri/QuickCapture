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

GridView {
    id: gridView

    property int referenceWidth: 200 * AppFramework.displayScaleFactor
    property int cells: calcCells(width)
    property bool dynamicSpacing: false
    property int minimumSpacing: 10 * AppFramework.displayScaleFactor
    property int cellSize: 175 * AppFramework.displayScaleFactor

    //property alias refreshHeader: refreshHeader

    signal clicked()
    signal pressAndHold()
    signal indicatorClicked(int indicator);
    signal refresh()

    cellWidth: width / cells
    cellHeight: dynamicSpacing ? cellSize + minimumSpacing : cellWidth
    
    clip: true
//    highlight: highlightDelegate
//    highlightFollowsCurrentItem: true

    //--------------------------------------------------------------------------

    function calcCells(w) {
        if (dynamicSpacing) {
            return Math.max(1, Math.floor(w / (cellSize + minimumSpacing)));
        }

        var rw =  referenceWidth;
        var c = Math.max(1, Math.round(w / referenceWidth));
        
        var cw = w / c;
        
        if (cw > rw) {
            c++;
        }
        
        cw = w / c;
        
        if (c > 1 && cw < (rw * 0.85)) {
            c--;
        }
        
        cw = w / c;
        
        if (cw > rw) {
            c++;
        }
        
        return c;
    }

    //--------------------------------------------------------------------------

    Component {
        id: highlightDelegate

        Rectangle {
            width: gridView.cellWidth
            height: gridView.cellHeight
            color: "#fefefe"
            x: gridView.currentItem.x
            y: gridView.currentItem.y
        }
    }

    //--------------------------------------------------------------------------

    //    RefreshHeader {
    //        id: refreshHeader

    //        onRefresh: {
    //            gridView.refresh();
    //        }
    //    }

    //--------------------------------------------------------------------------
}
