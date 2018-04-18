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

import "XForm.js" as XFormJS

Item {
    property alias dataFolder: dataFolder
    property string dataFileName: "itemsets.csv"
    readonly property string dataSeparator: ","
    readonly property string listNameColumn: "list_name"
    property var itemLists: ({})

    //--------------------------------------------------------------------------

    FileFolder {
        id: dataFolder

        onPathChanged: {
            loadExternal();
        }
    }

    //--------------------------------------------------------------------------

    function findItems(listName) {
        if (Array.isArray(itemLists[listName])) {
            return itemLists[listName];
        }

        var instance = findInstance(listName);

        if (!instance) {
            console.log("List instance not found:", listName);
            return [];
        }

        //console.log("instance:", JSON.stringify(instance));

        var items = XFormJS.childElements(instance["root"]);

        //console.log("items:", JSON.stringify(items, undefined, 2));

        itemLists[listName] = items;

        return items;
    }

    //--------------------------------------------------------------------------

    function loadExternal() {
        if (!dataFolder.fileExists(dataFileName)) {
            console.log("Itemsets data file not found:", dataFolder.filePath(dataFileName));

            return;
        }

        console.log("Reading itemsets:", dataFolder.filePath(dataFileName));

        var data = dataFolder.readTextFile(dataFileName);

        var rows = data.split("\n");

        if (rows < 1) {
            console.log("No data rows");
            return;
        }

        var columns = rows[0].split(dataSeparator);

        for (var i = 0; i < columns.length; i++) {
            columns[i] = columnValue(columns[i]);
        }

        console.log("# rows", rows.length, "columns:", JSON.stringify(columns, undefined, 2));

        for (i = 1; i < rows.length; i++) {
            var values = rows[i].split(dataSeparator);

            if (values.length < 1) {
                continue;
            }

            var valuesObject = {};

            for (var j = 0; j < values.length; j++) {
                valuesObject[columns[j]] = columnValue(values[j]);
            }

            addListRow(valuesObject);
        }

        // console.log("itemLists:", JSON.stringify(itemLists, undefined, 2));
    }
    
    //--------------------------------------------------------------------------

    function addListRow(values) {
        var listName = values[listNameColumn];

        if (!(listName > "")) {
            console.log("Skip:", JSON.stringify(values, undefined, 2));
            return;
        }

        values[listNameColumn] = undefined;

        if (!Array.isArray(itemLists[listName])) {
            itemLists[listName] = [];
        }

        itemLists[listName].push(values);
    }

    //--------------------------------------------------------------------------

    function columnValue(value) {
        var tokens = value.match(/\"(.*)\"/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return value;
        }
    }

    //--------------------------------------------------------------------------

    function findInstance(instanceName) {
        for (var i = 0; i < xform.instances.length; i++) {
            var instance = xform.instances[i];

            if (instance["@id"] === instanceName) {
                return instance;
            }
        }

        console.error("instance not found:", instanceName);

        return undefined;
    }

    //--------------------------------------------------------------------------
}
