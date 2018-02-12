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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

import "HelpersLib.js" as HelpersLib

GridLayout {
    id: panel

    //--------------------------------------------------------------------------

    property DataService dataService
    property Rectangle background

    readonly property real columnWidth: (width - (columns - 1) * columnSpacing) / columns

    //--------------------------------------------------------------------------

    signal addFeature(int layerId, var template)

    //--------------------------------------------------------------------------

    columns: 2
    layoutDirection: GridLayout.LeftToRight
    flow: GridLayout.LeftToRight

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var captureLayers = 0;
        dataService.featureServiceInfo.layers.forEach(function (layer) {
            if (layer.geometryType === "esriGeometryPoint"
                    && layer.types.length > 0) {
                captureLayers++;
            }
        });

        dataService.featureServiceInfo.layers.forEach(function (layer) {
            addLayer(layer, captureLayers > 1);
        });
    }

    //--------------------------------------------------------------------------

    function addLayer(layerInfo, multipleLayers) {
        console.log("Layer:", layerInfo.id, layerInfo.name);

        if (layerInfo.geometryType !== "esriGeometryPoint") {
            return;
        }

        if (layerInfo.templates.length < 1 && layerInfo.types.length < 1) {
            return;
        }

        //        var name = dataService.parseText(layerInfo.description);
        var options = dataService.parseOptions(layerInfo.description);

        var layerItem = layerItemComponent.createObject(panel,
                                                        {
                                                            layerInfo: layerInfo,
                                                            name: layerInfo.name,
                                                            options: options,
                                                            visible: multipleLayers
                                                        });

        layerItem.Layout.fillWidth = true;
        layerItem.Layout.columnSpan = columns;

        layerInfo.templates.forEach(function (templateInfo) {
            addTemplate(layerItem, undefined, templateInfo);
        });

        layerInfo.types.forEach(function (typeInfo) {
            addType(layerItem, typeInfo);
        });
    }

    //--------------------------------------------------------------------------

    function addType(layerItem, typeInfo) {
        console.log("Type:", typeInfo.id, typeInfo.name);

        var name = dataService.parseText(typeInfo.name);
        var options = dataService.parseOptions(typeInfo.name);

        //console.log("UV:", JSON.stringify(uniqueValueInfo, undefined, 2));

        var uniqueValueInfo = layerItem.findUniqueValueInfo(typeInfo.id);

        var typeItem = typeItemComponent.createObject(panel,
                                                      {
                                                          typeInfo: typeInfo,
                                                          name: name,
                                                          options: options,
                                                          symbolInfo: uniqueValueInfo.symbol,
                                                          visible: typeInfo.templates.length > 1
                                                      });

        typeItem.Layout.fillWidth = true;
        typeItem.Layout.columnSpan = columns;

        typeInfo.templates.forEach(function (templateInfo) {
            addTemplate(layerItem, typeItem, templateInfo);
        });
    }

    //--------------------------------------------------------------------------

    function addTemplate(layerItem, typeItem, templateInfo) {

        console.log("Template:", templateInfo.name, templateInfo.description);

        var description = dataService.parseText(templateInfo.description);
        var options = dataService.parseOptions(templateInfo.description);
        var symbol = typeItem ? typeItem.symbol : layerItem.symbol;

        var buttonComponent = symbol.type === "esriPMS" ? imageButtonComponent : textButtonComponent;
        var buttonItem = buttonComponent.createObject(panel,
                                                      {
                                                          layerId: layerItem.layerId,
                                                          template: templateInfo,
                                                          description: description,
                                                          options: options,
                                                          symbol: symbol
                                                      });

        //buttonItem.Layout.fillWidth = true;
        buttonItem.Layout.preferredWidth = Qt.binding(function() { return columnWidth; });
        buttonItem.Layout.fillHeight = true;
        buttonItem.Layout.columnSpan = 1;

        buttonItem.addFeature.connect(addFeatureClicked);
    }

    //--------------------------------------------------------------------------

    function addFeatureClicked(button) {
        console.log("addFeatureClicked:", button.layerId, button.template);
        addFeature(button.layerId, button.template);
    }

    //--------------------------------------------------------------------------

    Component {
        id: layerItemComponent

        LayerItem {
            textColor: HelpersLib.contrastColor(background.color)
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: typeItemComponent

        TypeItem {
            textColor: HelpersLib.contrastColor(background.color)
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: textButtonComponent

        FeatureTextButton {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageButtonComponent

        FeatureImageButton {
        }
    }

    //--------------------------------------------------------------------------
}
