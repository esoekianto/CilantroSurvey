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

import QtQuick 2.3
import QtQuick.LocalStorage 2.0

import "../Models"
import "../template/SurveyHelper.js" as Helper

SortedListModel {
    id: model

    property var db

    property string dbIdentifer: "SurveysData"
    property string dbVersion: "1.0"
    property string dbDescription: "Surveys Database"
    property int dbEstimatedSize: 1000000

    readonly property int statusDraft: 0
    readonly property int statusComplete: 1
    readonly property int statusSubmitted: 2
    readonly property int statusSubmitError: 3
    readonly property int statusInbox: 4

    property int statusFilter: -1
    property int statusFilter2: statusFilter
    property int changed: 0

    property bool validSchema
    property bool hasDateValues

    //--------------------------------------------------------------------------

    sortProperty: "updated"
    sortOrder: kSortOrderDesc

    //--------------------------------------------------------------------------
    /*
    onStatusFilterChanged: {
        refresh();
    }
*/

    //--------------------------------------------------------------------------

    function open() {
        if (!db) {
            db = LocalStorage.openDatabaseSync(
                        dbIdentifer,
                        dbVersion,
                        dbDescription,
                        dbEstimatedSize);
        }

        return db;
    }

    //--------------------------------------------------------------------------

    function initialize() {
        open();

        clear();

        db.transaction(function(tx) {
            var results = tx.executeSql("CREATE TABLE IF NOT EXISTS Surveys(name TEXT, path TEXT, created DATE, updated DATE, status INTEGER, statusText TEXT, data TEXT, feature TEXT, snippet TEXT, favorite INTEGER DEFAULT 0)");

            console.log("initialize", JSON.stringify(results, undefined, 2));
        });

        //consoleWrite();

        if (Qt.platform.os === "ios") {
            console.log("Checking survey paths");
            fixSurveysPath();
        }

        changed++;
    }

    //--------------------------------------------------------------------------

    function reinitialize() {
        open();

        db.transaction(function(tx) {
            var results = tx.executeSql("DROP TABLE IF EXISTS Surveys");

            console.log("reinitialize", JSON.stringify(results, undefined, 2));
        });

        initialize();
    }

    //--------------------------------------------------------------------------

    function validateSchema() {

        var columns = [];

        db.transaction(function(tx) {
            var rs = tx.executeSql("PRAGMA table_info(Surveys)");

            if (rs) {
                for (var i = 0; i < rs.rows.length; i++) {
                    var row = rs.rows.item(i);
                    //console.log("row", JSON.stringify(row, undefined, 2));
                    columns.push(row.name);
                }
            }
        });

        validSchema = true;

        var requiredColumns = [
                    "name",
                    "path",
                    "created",
                    "updated",
                    "status",
                    "statusText",
                    "data",
                    "feature",
                    "snippet"
                ];

        requiredColumns.forEach(function (name) {
            if (columns.indexOf(name) < 0) {
                console.error("Column not found:", name);
                validSchema = false;
            }
        });

        //console.log("valid", valid, JSON.stringify(columns), JSON.stringify(requiredColumns));

        return validSchema;
    }

    //--------------------------------------------------------------------------

    function refresh(path) {
        clear();
        hasDateValues = false;

        db.readTransaction(function(tx) {
            var rs;

            var select = "SELECT rowid, * FROM Surveys ";
            var orderClause = "";//" ORDER BY updated desc";

            if (statusFilter >= 0) {
                if (path > "") {
                    rs = tx.executeSql(select + 'WHERE path = ? AND (status = ? OR status = ?)' + orderClause, [path, statusFilter, statusFilter2]);
                } else {
                    rs = tx.executeSql(select + 'WHERE status = ?' + orderClause, statusFilter);
                }
            } else {
                if (path > "") {
                    rs = tx.executeSql(select + 'WHERE path = ?' + orderClause, path);
                } else {
                    rs = tx.executeSql(select + orderClause);
                }
            }

            for(var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);

                if (row.data > "") {
                    row.data = JSON.parse(row.data);
                } else {
                    row.data = null;
                }

                if (row.feature > "") {
                    row.feature = JSON.parse(row.feature);
                } else {
                    row.feature = null;
                }

                //console.log(i, JSON.stringify(row, undefined, 2));

                if (row.updated > "") {
                    hasDateValues = true;
                } else {
                    row.updated = "";
                }

                append(row);
            }
        });
    }

    //--------------------------------------------------------------------------

    function addRow(rowData) {

        if (!rowData.statusText) {
            rowData.statusText = "";
        }

        var now = new Date();

        if (!rowData.created) {
            rowData.created = new Date(now.getTime() + now.getTimezoneOffset() * 60000);
        }

        if (!rowData.updated) {
            rowData.updated = rowData.created;
        }

        // console.log("addRow:", JSON.stringify(rowData, undefined, 2));

        function isValidDate(value) {
            return value instanceof Date && isFinite(value.valueOf());
        }

        if (!isValidDate(rowData.created)) {
            rowData.created = null;
        }

        if (!isValidDate(rowData.updated)) {
            rowData.updated = null;
        }

        db.transaction(function(tx) {
            var result = tx.executeSql("INSERT INTO Surveys (name, path, created, updated, status, statusText, data, feature, snippet) VALUES (?,?,?,?,?,?,?,?,?)",
                                       [
                                           rowData.name,
                                           rowData.path,
                                           rowData.created,
                                           rowData.updated,
                                           rowData.status,
                                           rowData.statusText,
                                           JSON.stringify(rowData.data),
                                           _stringify(rowData.feature),
                                           rowData.snippet
                                       ]);

            //console.log("addRow result:", JSON.stringify(result, undefined, 2));

            rowData.rowid = result.insertId;

            if (rowData.favorite) {
                updateFavorite(rowData);
            }

            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function queryRow(rowid) {
        var rowData;

        db.transaction(function(tx) {
            var result = tx.executeSql("SELECT rowid, * FROM Surveys WHERE rowid = ?",
                                       [
                                           rowid
                                       ]);

            if (result.rows.length) {
                var row = result.rows.item(0);

                rowData = {
                    rowid: row.rowid,
                    data: JSON.parse(row.data),
                    feature: JSON.parse(row.feature),
                    snippet: row.snippet,
                    updated: new Date(row.updated),
                    status: row.status,
                    statusText: row.statusText,
                };
            }
        });

        //console.log("queryRow result:", JSON.stringify(rowData, undefined, 2));

        return rowData;
    }

    //--------------------------------------------------------------------------

    function updateRow(rowData, setUpdatedTimeStamp) {

        if (setUpdatedTimeStamp === undefined) {
            setUpdatedTimeStamp = true;
        }

        if (!rowData.statusText) {
            rowData.statusText = "";
        }

        var now = new Date();

        if (setUpdatedTimeStamp){
             rowData.updated = new Date(now.getTime() + now.getTimezoneOffset() * 60000);
        }

        db.transaction(function(tx) {

            var results = tx.executeSql("UPDATE Surveys SET status = ?, statusText = ?, data = ?, feature = ?, snippet = ? WHERE rowid = ?",
                                        [
                                            rowData.status,
                                            rowData.statusText,
                                            JSON.stringify(rowData.data),
                                            _stringify(rowData.feature),
                                            rowData.snippet,
                                            rowData.rowid
                                        ]);

            console.log("updateSurvey", JSON.stringify(results, undefined, 2));

            if (setUpdatedTimeStamp) {
                var timeStampUpdateResults = tx.executeSql("UPDATE Surveys SET updated = ? WHERE rowid = ?",
                                            [
                                                rowData.updated,
                                                rowData.rowid
                                            ]);
            }

            if (rowData.favorite) {
                updateFavorite(rowData);
            }

            updateModelRow(rowData);
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function updateStatus(rowid, status, statusText) {

        if (!statusText) {
            statusText = "";
        }

        db.transaction(function(tx) {
            var results = tx.executeSql("UPDATE Surveys SET status = ?, statusText = ? WHERE rowid = ?",
                                        [
                                            status,
                                            statusText,
                                            rowid
                                        ]);

            console.log("updateStatus:", JSON.stringify(results, undefined, 2));
            updateModelRow({
                               "rowid": rowid,
                               "status": status,
                               "statusText": statusText
                           });
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function updateDataStatus(rowid, data, status, statusText) {

        if (!statusText) {
            statusText = "";
        }

        db.transaction(function(tx) {
            var results = tx.executeSql("UPDATE Surveys SET data = ?, status = ?, statusText = ? WHERE rowid = ?",
                                        [
                                            JSON.stringify(data),
                                            status,
                                            statusText,
                                            rowid
                                        ]);

            console.log("updateDataStatus:", JSON.stringify(results, undefined, 2));
            updateModelRow({
                               "rowid": rowid,
                               "data": data,
                               "status": status,
                               "statusText": statusText
                           });
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function updateModelRow(rowData) {
        var modelRow;
        var i;

        if (rowData.favorite) {
            for (i = 0; i < count; i++) {
                modelRow = get(i);
                if (modelRow.path === rowData.path) {

                    modelRow.favorite = modelRow.rowid === rowData.rowid ? 1 : 0;

                    set(i, modelRow);
                }
            }
        }

        for (i = 0; i < count; i++) {
            modelRow = get(i);
            if (modelRow.rowid === rowData.rowid) {
                modelRow.status = rowData.status;

                if (rowData.statusText) {
                    modelRow.statusText = rowData.statusText;
                }

                if (rowData.data) {
                    modelRow.data = rowData.data;
                }

                if (rowData.feature) {
                    modelRow.feature = rowData.feature;
                }

                set(i, modelRow);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function updateFavorite(rowData) {
        db.transaction(function(tx) {
            var results = tx.executeSql("UPDATE Surveys SET favorite = 0 WHERE path = ?",
                                        [
                                            rowData.path
                                        ]);

            results = tx.executeSql("UPDATE Surveys SET favorite = 1 WHERE rowid = ?",
                                    [
                                        rowData.rowid
                                    ]);

            console.log("updateFavorite", JSON.stringify(results, undefined, 2));
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function getFavorite(path) {

        var row = {};

        db.readTransaction(function(tx) {
            var rs = tx.executeSql('SELECT rowid, * FROM Surveys WHERE path = ? AND favorite > 0', path);

            if (rs.rows.length ) {
                row = rs.rows.item(0);

                if (row.data > "") {
                    row.data = JSON.parse(row.data);
                } else {
                    row.data = null;
                }

                if (row.feature > "") {
                    row.feature = JSON.parse(row.feature);
                } else {
                    row.feature = null;
                }
            }
        });

        console.log("getFavorite", path, "row:", JSON.stringify(row, undefined, 2));

        return row;
    }

    //--------------------------------------------------------------------------

    function deleteSurvey(rowid) {
        db.transaction(function(tx) {
            var results = tx.executeSql("DELETE FROM Surveys WHERE rowid = ?",
                                        [
                                            rowid
                                        ]);

            console.log("deleteSurvey", JSON.stringify(results, undefined, 2));
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function deleteSurveys(status) {
        db.transaction(function(tx) {
            var results = tx.executeSql("DELETE FROM Surveys WHERE status = ? AND favorite = 0",
                                        [
                                            status
                                        ]);

            console.log("deleteSurveys", JSON.stringify(results, undefined, 2));
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function deleteSurveyBox(formname, status) {
        db.transaction(function(tx) {
            var results = tx.executeSql("DELETE FROM Surveys WHERE name = ? AND status = ? AND favorite = 0",
                                        [
                                            formname, status
                                        ]);
            console.log("deleteSurveyBox", JSON.stringify(results, undefined, 2));
            changed++;
        });

    }

    //--------------------------------------------------------------------------

    function deleteSurveyData(path) {
        db.transaction(function(tx) {
            var results = tx.executeSql("DELETE FROM Surveys WHERE path = ?",
                                        [
                                            path
                                        ]);

            console.log("deleteSurveyData", JSON.stringify(results, undefined, 2));
            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function surveyCount(path) {
        var count = 0;

        db.readTransaction(function(tx) {
            var results = tx.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE path = ?",
                                        [
                                            path
                                        ]);

            count = results.rows.item(0).count;
        });

        return count;
    }

    //--------------------------------------------------------------------------

    function statusCount(path, status) {
        var count = 0;

        db.readTransaction(function(tx) {
            var results;
            if (path > "") {
                results = tx.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE path = ? AND status = ?",
                                        [
                                            path,
                                            status
                                        ]);
            } else {
                results = tx.executeSql("SELECT COUNT(*) AS count FROM Surveys WHERE status = ?",
                                        [
                                            status
                                        ]);
            }

            count = results.rows.item(0).count;
        });

        return count;
    }

    //--------------------------------------------------------------------------

    function fixSurveysPath() {
        db.readTransaction(function(tx) {
            var rs;
            rs = tx.executeSql("SELECT rowid, * FROM Surveys");

            for(var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);

                var resolvedPath = Helper.resolveSurveyPath(row.path, surveysFolder);

                if ((resolvedPath !== null) && (row.path !== resolvedPath)) {
                    var rowData = {
                        "path": resolvedPath,
                        "rowid": row.rowid
                    };

                    updatePath(rowData);
                }
            }
        });
    }

    //--------------------------------------------------------------------------

    function updatePath(rowData) {
        db.transaction(function(tx) {
            var results = tx.executeSql("UPDATE Surveys SET path = ? WHERE rowid = ?",
                                        [
                                            rowData.path,
                                            rowData.rowid
                                        ]);

            console.log("updatePath", JSON.stringify(results, undefined, 2));

            changed++;
        });
    }

    //--------------------------------------------------------------------------

    function getSurvey(index) {
        return get(index);
    }

    //--------------------------------------------------------------------------

    function _stringify(value) {
        if (value === null) {
            return null;
        }

        return JSON.stringify(value);
    }

    //--------------------------------------------------------------------------
}

