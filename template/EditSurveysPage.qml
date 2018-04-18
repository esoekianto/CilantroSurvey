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
import QtPositioning 5.2

import ArcGIS.AppFramework 1.0

import "../Portal"
import "../XForms"
import "../XForms/XForm.js" as XFormJS
import "../template/SurveyHelper.js" as Helper


SurveysListPage {
    id: page

    property bool isPublic: false
    property bool refreshing: false

    property alias objectCache: xformFeatureService.objectCache

    //--------------------------------------------------------------------------

    title: qsTr("%1 Inbox").arg(surveyTitle)
    statusFilter: xformsDatabase.statusInbox
    showDelete: false
    closeOnEmpty: false
    emptyMessage: qsTr("The inbox is empty")
    refreshEnabled: true

    /*
    listActionButton {
        text: qsTr("Refresh")
        visible: AppFramework.network.isOnline

        onClicked: {
            refreshDatabase();
        }
    }
*/
    listAction: ConfirmButton {
        visible: AppFramework.network.isOnline

        text: qsTr("Refresh")
        iconSource: "images/refresh_update.png"

        onClicked: {
            refreshDatabase();
        }
    }

    onRefresh: {
        refreshDatabase();
    }

    //--------------------------------------------------------------------------

    Rectangle {
        parent: app
        anchors.fill:  parent
        color: "#40000000"
        visible: refreshing

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }
    }

    //--------------------------------------------------------------------------

    function refreshDatabase() {
        if (isPublic) {
            refreshStart();
        } else {
            portal.signInAction(qsTr("Please sign in to refresh surveys"), refreshStart);
        }
    }

    function refreshStart() {
        refreshing = true;
        progressPanel.open();

        if (xformFeatureService.isReady(surveyPath)) {
            xformFeatureService.serviceReady();
        } else {
            getServiceInfo(surveyPath);
        }
    }


    function refreshComplete() {
        refreshing = false;
        progressPanel.close();
        refreshList();
    }

    function refreshError(error) {
        refreshing = false;
        progressPanel.closeError(progressPanel.title, error.message, "Code %1".arg(error.code));
    }

    //--------------------------------------------------------------------------

    function getServiceInfo(surveyPath) {

        function setFeatureServiceUrl(url) {
            var urlInfo = AppFramework.urlInfo(url);

            if (portal.ssl) {
                urlInfo.scheme = "https";
            }

            console.log("setFeatureServiceUrl:", urlInfo.url);

            xformFeatureService.surveyPath = surveyPath;
            xformFeatureService.featureServiceUrl = urlInfo.url;
        }

        function getSurveyInfoUrl() {
            var submissionUrl = getSubmissionUrl(surveyPath);
            if (submissionUrl > "") {
                return submissionUrl;
            }

            var surveyInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".info");

            return surveyInfo.serviceInfo.url;
        }

        var surveyFileInfo = AppFramework.fileInfo(surveyPath);
        var surveyItemInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".itemInfo");

        progressPanel.title = qsTr("Getting service information");

        if (surveyItemInfo.id > "" && surveyItemInfo.type === "Form") {
            survey2ServiceRequest.requestUrl(surveyItemInfo.id, function(url) {
                console.log("Survey2Service url:", url);
                if (url > "") {
                    setFeatureServiceUrl(url);
                } else {
                    setFeatureServiceUrl(getSurveyInfoUrl())
                }
            });
        } else {
            setFeatureServiceUrl(getSurveyInfoUrl())
        }
    }

    //--------------------------------------------------------------------------

    function getSubmissionUrl(surveyPath) {
        var xml = AppFramework.userHomeFolder.readTextFile(surveyPath);
        var json = AppFramework.xmlToJson(xml);

        var submission = {};

        if (json.head && json.head.model && json.head.model.submission) {
            submission = json.head.model.submission;
        }

        console.log("submission:", JSON.stringify(submission, undefined, 2));

        return submission["@action"];
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: survey2ServiceRequest

        property var callback

        portal: app.portal

        onSuccess: {
            // console.log("Survey2Service:", JSON.stringify(response, undefined, 2));

            if (response.total > 0) {
                callback(response.relatedItems[0].url);
            } else {
                callback();
            }
        }

        onFailed: {
            callback();
        }

        onProgressChanged: {
        }

        function requestUrl(itemId, callback) {
            survey2ServiceRequest.callback = callback;
            url = portal.restUrl + "/content/items/" + itemId + "/relatedItems";

            sendRequest({
                            "relationshipType": "Survey2Service",
                            "direction": "forward"
                        });
        }
    }

    //--------------------------------------------------------------------------

    XFormFeatureService {
        id: xformFeatureService

        property string surveyPath

        portal: app.portal
        schema: page.schema

        onServiceReady: {
            console.log("Refreshing");

            console.log("featureServiceInfo:", JSON.stringify(featureServiceInfo));

            function queryProperty(name, defaultValue) {
                return surveyInfo.queryInfo.hasOwnProperty(name) ? surveyInfo.queryInfo[name] : defaultValue;
            }

            progressPanel.title = qsTr("Searching for surveys");

            var table = schema.schema;
            var layer = findLayer(table.tableName);
            if (!layer) {
                console.log("Default to layer 0 for table:", schema.schema.tableName);
                layer = findLayer(0, true);
            }

            var outFields = getOutFields(table, layer);

            if (layer.editFieldsInfo) {
                var editDateField = layer.editFieldsInfo.editDateField;
                if (editDateField > "") {
                    outFields.push(editDateField);
                }

                var creationDateField = layer.editFieldsInfo.creationDateField;
                if (creationDateField > "") {
                    outFields.push(creationDateField);
                }
            }

            table.relatedTables.forEach(function (relatedTable) {
                var relatedLayer = xformFeatureService.findLayer(relatedTable.tableName);

                console.log("relatedTable:", relatedTable.tableName, "id:", relatedLayer.id);

                var relationship = xformFeatureService.findRelationship(layer, relatedLayer);

                if (relationship) {
                    pushUnique(outFields, relationship.keyField);
                } else {
                    console.error("Relationship to child not found for:", relatedTable.tableName);
                }
            });


            var where = replaceWhereVars(queryProperty("where", ""));
            if (!(where > "")) {
                where = "1=1";
            }

            var body = {
                "outFields": queryProperty("outFields", outFields.join(",")),
                "where": where,
                "outSR": queryProperty("outSR", 4326),
                "returnGeometry": queryProperty("returnGeometry", true),
                "returnZ": queryProperty("returnZ", true),
                "returnM": queryProperty("returnM", false),
            };

            var applySpatialFilter = queryProperty("applySpatialFilter", true);
            console.log("applySpatialFilter:", applySpatialFilter, "tabIndex:", tabView.currentIndex, "map:", page.map);

            if (applySpatialFilter && tabView.currentIndex === 1 && page.map) {
                var extent = QtPositioning.shapeToRectangle(map.visibleRegion);

                body.spatialRel = "esriSpatialRelIntersects";
                body.inSR = 4326;
                body.geometryType = "esriGeometryEnvelope";
                body.geometry = "%1,%2,%3,%4"
                .arg(extent.topLeft.longitude)
                .arg(extent.bottomRight.latitude)
                .arg(extent.bottomRight.longitude)
                .arg(extent.topLeft.latitude);
            }

            console.log("query body:", JSON.stringify(body, undefined, 2));

            queryRequest.layerId = layer.id;
            queryRequest.sendRequest(body);
        }

        onFailed: {
            refreshError(error);
        }

        function isReady(path) {
            return surveyPath === path && featureServiceUrl > "" && featureServiceInfo;
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: queryRequest

        property int layerId
        url: xformFeatureService.featureServiceUrl + "/%1/query".arg(layerId)
        portal: xformFeatureService.portal
        trace: true

        onSuccess: {
            var features = response.features;

            if (!Array.isArray(features)) {
                console.error("No features array in response:", JSON.stringify(response, undefined, 2));
                features = [];
            }

            //console.log("query success:", JSON.stringify(response, undefined, 2));

            xformsDatabase.deleteSurveyBox(surveyInfo.name, xformsDatabase.statusInbox);

            var dateOffset = (new Date()).getTimezoneOffset() * 60000;

            console.log("Adding rows to inbox:", features.length);

            progressPanel.title = qsTr("Adding %1 rows to inbox").arg(features.length);
            progressPanel.progressBar.minimumValue = 0;
            progressPanel.progressBar.maximumValue = features.length;
            progressPanel.progressBar.value = 0;

            var instanceNameNodeset = "/" + schema.instanceName + "/meta/instanceName";
            formData.instanceNameBinding = schema.findBinding(instanceNameNodeset);

            var table = schema.schema;
            var layer = xformFeatureService.findLayer(table.tableName);

            var creationDateField;
            var editDateField;
            if (layer.editFieldsInfo) {
                creationDateField = layer.editFieldsInfo.creationDateField;
                editDateField = layer.editFieldsInfo.editDateField;
            }

            var invalidDate = new Date("");

            var rowIds = {};
            var objectIds = [];

            features.forEach(function (feature) {

                progressPanel.progressBar.value++;

                formData.instance = featureToInstance(feature, layer);

                var rowData = {
                    "name": surveyInfo.name,
                    "path": surveyPath,
                    "data": formData.instance,
                    "feature": null, //JSON.stringify(feature),
                    "snippet": formData.snippet(),
                    "status": xformsDatabase.statusInbox,
                    "statusText": "",
                    "favorite": 0
                };

                if (creationDateField > "") {
                    var creationDate = feature.attributes[creationDateField];
                    rowData.created = new Date(creationDate + dateOffset);
                } else {
                    rowData.updated = invalidDate;
                }

                if (editDateField > "") {
                    var editDate = feature.attributes[editDateField];
                    rowData.updated = new Date(editDate + dateOffset);
                } else {
                    rowData.updated = invalidDate;
                }

                xformsDatabase.addRow(rowData);

                if (layer.objectIdField > "") {
                    var objectId = feature.attributes[layer.objectIdField];
                    objectIds.push(objectId);
                    rowIds[objectId] =  rowData.rowid;
                }
            });

            if (objectIds.length <= 0) {
                refreshComplete();
                return;
            }

            var relatedQueries = [];

            console.log("table:", table.tableName);

            table.relatedTables.forEach(function (relatedTable) {
                var relatedLayer = xformFeatureService.findLayer(relatedTable.tableName);

                console.log("relatedTable:", relatedTable.tableName, "id:", relatedLayer.id, "esriParameters:", JSON.stringify(relatedTable.esriParameters));

                var query = relatedTable.esriParameters.query;

                if (!(XFormJS.toBoolean(query) || typeof query === "string")) {
                    console.log("Skipping related data download:", relatedTable.tableName, "query:", query);
                    return;
                }

                var relationship = xformFeatureService.findRelationship(layer, relatedLayer);
                var parentRelationship = xformFeatureService.findRelationship(relatedLayer, layer);

                if (relationship && parentRelationship) {
                    var outFields = getOutFields(relatedTable, relatedLayer);

                    pushUnique(outFields, parentRelationship.keyField);

                    relatedQueries.push({
                                            name: relatedTable.tableName,
                                            table: relatedTable,
                                            layer: relatedLayer,
                                            relationship: relationship,
                                            parentRelationship: parentRelationship,
                                            outFields: outFields,
                                            query: query,
                                            orderBy: relatedTable.esriParameters.orderBy
                                        });
                } else {
                    console.error("Relationships not found for:", table.tableName, "<=>", relatedTable.tableName);
                }
            });

            if (relatedQueries.length) {
                console.log("objectIds:", JSON.stringify(objectIds));
                //console.log("relatedQueries:", relatedQueries.length, JSON.stringify(relatedQueries, undefined, 2));

                relatedQueryRequest.layerId = layerId;
                relatedQueryRequest.rowIds = rowIds;
                relatedQueryRequest.objectIds = objectIds;
                relatedQueryRequest.relatedQueries = relatedQueries;
                relatedQueryRequest.next();

            } else {
                refreshComplete();
            }
        }

        onFailed: {
            refreshError(error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: relatedQueryRequest

        property int layerId
        property var rowIds;
        property var objectIds
        property var relatedQueries
        property var relatedQuery

        url: xformFeatureService.featureServiceUrl + "/%1/queryRelatedRecords".arg(layerId)
        portal: xformFeatureService.portal
        trace: true

        onSuccess: {
            console.log("related response:", JSON.stringify(response, undefined, 2));

            var relatedRecordGroups = response.relatedRecordGroups;

            relatedRecordGroups.forEach(function (relatedRecordGroup) {
                var rowId = rowIds[relatedRecordGroup.objectId];

                console.log("related records:", relatedRecordGroup.relatedRecords.length, "rowId:", rowId, "objectId:", relatedRecordGroup.objectId);

                var rowData = xformsDatabase.queryRow(rowId);

                //console.log("rowData:", JSON.stringify(rowData, undefined, 2));

                var relatedData = [];
                relatedRecordGroup.relatedRecords.forEach(function (relatedRecord) {
                    var featureData = featureToInstanceData(relatedRecord, relatedQuery.table, relatedQuery.layer);

                    relatedData.push(featureData);
                });

                //console.log("relatedData:", relatedQuery.name, ":", JSON.stringify(relatedData, undefined, 2));

                rowData.data[schema.instanceName][relatedQuery.name] = relatedData;

                console.log("rowData:", JSON.stringify(rowData, undefined, 2));

                xformsDatabase.updateRow(rowData, false);
            });

            next();
        }

        onFailed: {
            refreshError(error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }

        function next() {
            if (!relatedQueries.length) {
                refreshComplete();
                return;
            }

            relatedQuery = relatedQueries.shift();

            progressPanel.title = qsTr("Searching for related data (%1)").arg(relatedQuery.name);

            console.log("related query:", JSON.stringify(relatedQuery, undefined, 2));

            var body = {
                "objectIds": objectIds.join(","),
                "relationshipId": relatedQuery.relationship.id,
                "outFields": relatedQuery.outFields.join(","),
                "outSR": 4326,
                "returnGeometry": true,
                "returnZ": true,
                "returnM": false,
            };

            if (typeof relatedQuery.query === "string" && relatedQuery.query > "") {
                body.definitionExpression = replaceWhereVars(relatedQuery.query);
            }

            if (relatedQuery.orderBy > "") {
                body.orderByFields = relatedQuery.orderBy;
            }


            console.log("related query body:", JSON.stringify(body, undefined, 2));

            sendRequest(body);
        }
    }

    //--------------------------------------------------------------------------

    function getOutFields(table, layer) {
        var outFields = [];

        if (layer.objectIdField > "") {
            outFields.push(layer.objectIdField)
        }

        if (layer.globalIdField > "") {
            outFields.push(layer.globalIdField)
        }

        table.fields.forEach(function(field) {

            if (field.esriGeometryType) {
                return;
            }

            if (field.attachment) {
                return;
            }

            var fieldInfo;
            for (var i = 0; i < layer.fields.length; i++) {
                if (layer.fields[i].name === field.name) {
                    fieldInfo = layer.fields[i];
                    break;
                }
            }

            if (fieldInfo) {
                pushUnique(outFields, fieldInfo.name);
            }
        });

        return outFields;
    }

    //--------------------------------------------------------------------------

    function pushUnique(array, value) {
        if (array.indexOf(value) < 0) {
            array.push(value);
        }
    }

    //--------------------------------------------------------------------------

    function replaceWhereVars(where) {
        var names = ["username", "email", "firstName", "lastName"];

        names.forEach(function (name) {
            var varName = "\\$\\{" + name + "\\}";
            var value = "'" + XFormJS.userProperty(app, name) + "'";
            where = XFormJS.replaceAll(where, varName, value);
        });

        return where;
    }

    //--------------------------------------------------------------------------

    function featureToInstance(feature, layer) {
        var instance = {};

        instance[schema.instanceName] = featureToInstanceData(feature, schema.schema, layer);

        return instance;
    }

    //--------------------------------------------------------------------------

    function featureToInstanceData(feature, table, layer) {
        var data = {}

        var keys = Object.keys(feature.attributes);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            data[key] = feature.attributes[key];
        }

        if (table.geometryFieldName && feature.geometry) {
            data[table.geometryFieldName] = feature.geometry;
        }

        formData.setMetaValue(data, formData.kMetaObjectIdField, layer.objectIdField);
        formData.setMetaValue(data, formData.kMetaGlobalIdField, layer.globalIdField);
        formData.setMetaValue(data, formData.kMetaEditMode, formData.kEditModeUpdate);

        // console.log("table:", table.tableName, "feature:", JSON.stringify(feature, undefined, 2), "instanceData:", JSON.stringify(data, undefined, 2));

        return data;
    }

    //--------------------------------------------------------------------------

    XFormData {
        id: formData

        schema: page.schema
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        parent: app
        message: xformFeatureService.progressMessage
        progressBar.value: xformFeatureService.progress
        progressBar.visible: progressBar.value > 0

        z: 99999
    }

    //--------------------------------------------------------------------------
}
