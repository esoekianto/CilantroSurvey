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

QtObject {
    property FileFolder dataFolder
    property var lists: ({})
    property string dataSeparator: ","
    property bool debug: false

    //--------------------------------------------------------------------------

    function getList(listName) {
        if (lists[listName]) {
            return lists[listName];
        }

        var list = readList(listName);

        if (list) {
            lists[listName] = list;
        }

        return list;
    }

    //--------------------------------------------------------------------------

    function readList(listName) {
        var listFile = listName + ".csv";

        if (!dataFolder.fileExists(listFile)) {
            console.error("Itemsets data file not found:", dataFolder.filePath(listFile));
            return null;
        }

        var dataList = {
            columns: [],
            data: []
        };

        var data = dataFolder.readTextFile(listFile);
        var rows = data.split("\n");
        var columns = rows[0].split(dataSeparator);

        for (var i = 0; i < columns.length; i++) {
            columns[i] = columnValue(columns[i].trim());
        }

        dataList.columns = columns;

        if (rows < 1) {
            console.warn("No data rows in:", listFile);
            return dataList;
        }

        for (i = 1; i < rows.length; i++) {
            var values = rows[i].split(dataSeparator);

            if (values.length < 1) {
                continue;
            }

            var valuesObject = {};

            for (var j = 0; j < values.length; j++) {
                valuesObject[columns[j]] = columnValue(values[j]);
            }

            dataList.data.push(valuesObject);
        }

        if (debug) {
            console.log(listName, "columns:", JSON.stringify(columns));
            console.log(listName, "rows:", rows.length, JSON.stringify(dataList.data));
        }

        return dataList;
    }

    //--------------------------------------------------------------------------

    function columnValue(value) {
        var tokens = value.match(/\"(.*)\"/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return value.trim()
        }
    }

    //--------------------------------------------------------------------------
}
