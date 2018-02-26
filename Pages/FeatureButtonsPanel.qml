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
    property var currentPosition

    readonly property real columnWidth: (width - (columns - 1) * columnSpacing) / columns

    //--------------------------------------------------------------------------

    readonly property var kGeometryTypes: [
        dataService.kGeometryPoint,
        dataService.kGeometryPolyline,
        dataService.kGeometryPolygon
    ]

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
            if (kGeometryTypes.indexOf(layer.geometryType) >= 0
                    && (layer.templates.length > 0 || layer.types.length > 0)) {
                captureLayers++;
            }
        });

        dataService.featureServiceInfo.layers.forEach(function (layer) {
            addLayer(layer, captureLayers > 1);
        });
    }

    //--------------------------------------------------------------------------

    function addLayer(layerInfo, multipleLayers) {
        console.log("Layer:", layerInfo.id, layerInfo.name, "mutiple:", multipleLayers);

        if (kGeometryTypes.indexOf(layerInfo.geometryType) < 0) {
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

        layerInfo.templates.forEach(function (templateInfo, index, array) {
            addTemplate(layerItem, undefined, templateInfo, index, array);
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

        var symbol = layerItem.findSymbol(typeInfo.id);

        var typeItem = typeItemComponent.createObject(panel,
                                                      {
                                                          typeInfo: typeInfo,
                                                          name: name,
                                                          options: options,
                                                          symbolInfo: symbol
                                                      });

        typeItem.layerCollapsed = Qt.binding(function() { return layerItem.collapsed; });
        typeItem.visible = Qt.binding(function () { return typeInfo.templates.length > 1 && !layerItem.collapsed; });

        typeInfo.templates.forEach(function (templateInfo, index, array) {
            addTemplate(layerItem, typeItem, templateInfo, index, array);
        });
    }

    //--------------------------------------------------------------------------

    function addTemplate(layerItem, typeItem, templateInfo, index, array) {

        console.log("Template:", templateInfo.name, templateInfo.description);

        var description = dataService.parseText(templateInfo.description);
        var options = dataService.parseOptions(templateInfo.description);
        var symbol = typeItem ? typeItem.symbol : layerItem.symbol;
        var groupItemVisible = typeItem ? typeItem.visible : layerItem.visible;

        var buttonComponent;

        var buttonGroup = null;

        switch (layerItem.layerInfo.geometryType) {
        case dataService.kGeometryPoint:
            buttonComponent = symbol.type === "esriPMS" ? imageButtonComponent : textButtonComponent;
            break;

        case dataService.kGeometryPolyline:
        case dataService.kGeometryPolygon:
            buttonGroup = typeItem ? typeItem.buttonGroup : layerItem.buttonGroup;
            buttonComponent = polyButtonComponent;
            break;
        }

        if (!buttonComponent) {
            console.error("Null button component");
            return;
        }

        var buttonItem = buttonComponent.createObject(panel,
                                                      {
                                                          buttonGroup: buttonGroup,
                                                          layerId: layerItem.layerId,
                                                          template: templateInfo,
                                                          description: description,
                                                          options: options,
                                                          symbol: symbol
                                                      });

        buttonItem.Layout.fillHeight = true;
        buttonItem.Layout.preferredWidth = Qt.binding(function() { return columnWidth; });

        if (array.length === 1 && groupItemVisible) {
            buttonItem.Layout.columnSpan = columns;
            buttonItem.Layout.fillWidth = true;
        } else {
            buttonItem.Layout.columnSpan = 1;
        }

        if (typeItem) {
            buttonItem.visible = Qt.binding(function() { return !typeItem.collapsed; });
        } else {
            buttonItem.visible = Qt.binding(function() { return !layerItem.collapsed; });
        }

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
            Layout.fillWidth: true
            Layout.columnSpan: columns
            Layout.topMargin: 5 * AppFramework.displayScaleFactor
            Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

            textColor: HelpersLib.contrastColor(background.color)
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: typeItemComponent

        TypeItem {
            Layout.fillWidth: true
            Layout.columnSpan: columns
            Layout.topMargin: 5 * AppFramework.displayScaleFactor
            Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

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

    Component {
        id: polyButtonComponent

        FeaturePolyButton {
            currentPosition: panel.currentPosition
            pulseOn: pulseTimer.pulseOn
            flashOn: flashTimer.flashOn

            onBeginFeature: {
                dataService.beginPoly(currentFeatureId, layerId, template.prototype.attributes);
            }

            onAddFeaturePoint: {
                dataService.insertPolyPoint(currentFeatureId, currentPosition);
            }

            onEndFeature: {
                lastInsertId = dataService.endPoly(currentFeatureId);
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: pulseTimer

        property bool pulseOn

        running: true
        interval: 1000 / 3
        repeat: true

        onTriggered: {
            pulseOn = !pulseOn;
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: flashTimer

        property bool flashOn

        running: true
        interval: 100
        repeat: true

        onTriggered: {
            flashOn = !flashOn;
        }
    }

    //--------------------------------------------------------------------------
}
