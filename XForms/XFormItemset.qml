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

import QtQuick 2.4

import ArcGIS.AppFramework 1.0

Item {
    property var itemset
    property XFormData formData
    property string nodeset: itemset["@nodeset"]
    property string valueRef: itemset.value["@ref"]
    property string labelRef: itemset.label["@ref"]
    property string labelProperty
    property string listName
    property var itemsPath
    property string expression
    property XFormExpression expressionInstance
    property var expressionNodesets
    property var items
    property string filterExpression
    property var filteredItems: []
    property var nodesetValues
    property var previousNodesetValues

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("itemset:", JSON.stringify(itemset, undefined, 2));
        console.log("nodeset:", nodeset);
        console.log("valueRef:", valueRef);
        console.log("labelRef:", labelRef);
        labelProperty = labelRef.match(/jr:itext\((.*)\)/)[1];
        console.log("labelProperty:", labelProperty);

        var nodesetTokens = nodeset.match(/instance\(\s*\'([A-Za-z0-9_]+)\'\s*\)([0-9A-Za-z_\/.']+)\[([0-9A-Za-z=_\ \/]+)\]/);

        // console.log("nodesetTokens:", nodeset, "=", JSON.stringify(nodesetTokens, undefined, 2));

        listName = nodesetTokens[1];
        itemsPath = nodesetTokens[2].split("/");
        expression = nodesetTokens[3];

        console.log("listName:", listName);
        console.log("itemsPath:", JSON.stringify(itemsPath, undefined, 2));
        console.log("expression:", expression);

        items = xform.itemsets.findItems(listName);

        console.log("items count:", items.length);
        //console.log("items:", JSON.stringify(items, undefined, 2));

        expressionInstance = formData.expressionsList.addExpression(expression, undefined, "select");
        expressionNodesets = expressionInstance.nodesets;
        nodesetValues = expressionInstance.nodesetValuesBinding();
    }

    //--------------------------------------------------------------------------

    onNodesetValuesChanged: {
        console.log("onNodesetValuesChanged:", JSON.stringify(nodesetValues, undefined, 2));

        var changed = false;

        if (!previousNodesetValues) {
            previousNodesetValues = {};
        }

        expressionNodesets.forEach(function (nodeset) {
            if (nodesetValues[nodeset] != previousNodesetValues[nodeset]) {
                previousNodesetValues[nodeset] = nodesetValues[nodeset];
                changed = true;
            }
        });

        console.log("Itemset changed:", changed);

        if (changed) {

            function valueToken(nodeset) {
                return formData.valueToken(formData.valueById(nodeset));
            }

            filterExpression = expressionInstance.translate(expression, "", undefined, valueToken);

            filteredItems = filterItems(filterExpression);

            //            console.log("filteredItems", JSON.stringify(filteredItems, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onLanguageChanged: {
            console.log('Language:', language);

            if (itemset.external) {
                filteredItems = filterItems(filterExpression);
            }
        }
    }

    //--------------------------------------------------------------------------

    function filterItems(expression) {
        var filteredItems = [];

        if (!Array.isArray(items)) {
            return filteredItems;
        }

        console.log("Filtering", items.length, "items with expression:", expression, "language:", xform.language);

        var translatedLabelProperty = labelProperty + "::" + xform.language;

        for (var i = 0; i < items.length; i++) {
            var item = items[i];

            with (item) {
                if (Boolean(eval(expression))) {
                    filteredItems.push({
                                           value: item[valueRef],
                                           label: itemset.external
                                                  ? translatedLabel(item, translatedLabelProperty)
                                                  : { "@ref": "jr:itext('" + item[labelProperty] + "')" }
                                       });
                }
            }
        }

        console.log("# Filtered:", filteredItems.length);

        return filteredItems;
    }

    //--------------------------------------------------------------------------

    function translatedLabel(item, translatedLabelProperty) {
        if (item[translatedLabelProperty]) {
            return item [translatedLabelProperty];
        }

        return item[labelProperty];
    }

    //--------------------------------------------------------------------------
}
