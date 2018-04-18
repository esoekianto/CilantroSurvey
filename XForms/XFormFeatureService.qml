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

import QtQuick 2.9
import QtQml 2.2

import ArcGIS.AppFramework 1.0

import "../Portal"

import "XForm.js" as XFormJS

Item {
    id: xformFeatureService

    property Portal portal
    property bool debug: false

    property string featureServiceItemId
    property url featureServiceUrl
    property var featureServiceInfo: null
    property var layerInfos
    property bool useUploadIds: false
    property bool useGlobalIds: useUploadIds

    property string progressMessage
    property real progress: 0

    property var objectCache: ({})

    property XFormSchema schema

    property XFormWebhooks webhooks

    //--------------------------------------------------------------------------

    signal serviceReady();
    signal applied(var edits, var response, var instanceData);
    signal failed(var error);

    //--------------------------------------------------------------------------

    readonly property var kContentTypes: ({
                                              "jpg": "image/jpeg",
                                              "jfif": "image/jpeg",
                                              "jpeg": "image/jpeg",
                                              "png": "image/png",
                                              "gif": "image/gif",
                                              "tif": "image/tiff",
                                              "tiff": "image/tiff",
                                              "txt": "text/plain",
                                              "csv": "text/plain",
                                              "zip": "application/zip",
                                              "mp3": "audio/basic",
                                              "mpeg": "audio/basic",
                                              "wav": "audio/wav",
                                              "xml": "text/xml",
                                          });

    readonly property string kDefaultContentType: "application/octet-stream"

    //--------------------------------------------------------------------------

    onApplied: {
        if (webhooks) {
            webhooks.submit(surveyInfo, featureServiceInfo, edits, response);
        }
    }

    //--------------------------------------------------------------------------

    function applyData(featureData, instanceData) {
        if (typeof featureData === "string") {
            featureData = JSON.parse(featureData);
        }

        console.log("applyData:", JSON.stringify(featureData, undefined, 2));

        if (true) { //!portal.isPortal) {
            useUploadIds = XFormJS.toBoolean(featureServiceInfo.supportsApplyEditsWithGlobalIds);

            layerInfos.forEach(function(layerInfo) {
                console.log("layer:", layerInfo.name, "supportsAttachmentsByUploadId:", layerInfo.supportsAttachmentsByUploadId);
                useUploadIds = useUploadIds && XFormJS.toBoolean(layerInfo.supportsAttachmentsByUploadId);
            });
        }

        console.log("Adding attachments by upload id:", useUploadIds);

        if (Array.isArray(featureData)) {
            applyEdits(featureData, instanceData);
        } else {
            var edit = {
                "id": 0,
                "adds": [],
                "attachments": []
            };

            edit.attachments.push(featureData.attachments);
            // delete featureData.attachments;
            featureData.attachments = undefined;

            edit.adds.push(featureData);

            applyEdits([edit], instanceData);
        }
    }

    //--------------------------------------------------------------------------

    function applyEdits(edits, instanceData, schema) {
        console.log("Applying edits to:", featureServiceUrl);

        var error = resolveLayerReferences(edits);
        if (error) {
            failed(error);
            return;
        }

        console.log("edits:", JSON.stringify(edits, undefined, 2));

        var attachments = {};

        edits.forEach(function (edit) {
            if (Array.isArray(edit.attachments) && edit.attachments.length > 0) {
                attachments[edit.id] = edit.attachments;
            }
            // delete edit.attachments;
            edit.attachments = undefined;
        });

        function doApplyEdits() {
            var formData = {
                "edits": XFormJS.encode(JSON.stringify(edits)),
                "rollbackOnFailure": true,
                "useGlobalIds": useGlobalIds
            }

            progressMessage = qsTr("Sending Data");

            applyEditsRequest.edits = edits;
            applyEditsRequest.attachments = attachments;
            applyEditsRequest.instanceData = instanceData;
            applyEditsRequest.sendRequest(formData);
        }

        if (useUploadIds) {
            var uploadsList = buildUploadsList(edits, attachments);

            uploadAttachments(uploadsList, function() {
                uploadsList.forEach(function(upload) {
                    //var edit = edits[upload.editId];

                    var edit;

                    for (var i = 0; i < edits.length; i++) {
                        if (edits[i].id === upload.editId) {
                            edit = edits[i];
                            break;
                        }
                    }

                    if (!edit) {
                        console.error("Unable to find an edit for id:", upload.editId, "in:", JSON.stringify(edits, undefined, 2));
                    }

                    if (!edit.attachments) {
                        edit.attachments = {};
                    }

                    if (!Array.isArray(edit.attachments.adds)) {
                        edit.attachments.adds = [];
                    }

                    var add = edit.adds[upload.index].attributes;

                    var layerInfo = findLayer(upload.editId, true);
                    var parentGlobalId = add[layerInfo.globalIdField];

                    var attachment = {
                        uploadId: upload.itemID,
                        globalId: AppFramework.createUuidString(0).toUpperCase(),
                        parentGlobalId: parentGlobalId,
                        name: upload.fileName,
                        contentType: upload.contentType,
                        keywords: upload.keywords
                    };

                    console.log("upload info:", JSON.stringify(upload, undefined, 2));
                    console.log("upload add:", JSON.stringify(add, undefined, 2));
                    console.log("upload attachment:", JSON.stringify(attachment, undefined, 2));

                    edit.attachments.adds.push(attachment);
                });
                doApplyEdits()
            });
        } else {
            doApplyEdits();
        }
    }

    //--------------------------------------------------------------------------

    function buildUploadsList(edits, attachments) {

        var list = [];

        for (var editIndex = 0; editIndex < edits.length; editIndex++) {
            var edit = edits[editIndex];
            if (!edit) {
                continue;
            }

            if (edit.adds) {
                var layer = findLayer(edit.id, true);

                if (!layer.supportsAttachmentsByUploadId) {
                    console.log("Uploads not supported for layer:", layer.name);
                    continue;
                }

                for (var addIndex = 0; addIndex < edit.adds.length; addIndex++) {
                    var addAttachments = attachments[edit.id][addIndex];
                    if (Array.isArray(addAttachments)) {
                        addAttachments.forEach(function (attachment) {

                            var upload = {
                                editId: edit.id,
                                index: addIndex
                                //edit: edit
                            };

                            if (typeof attachment === "object") {
                                upload.fieldName = attachment.fieldName;
                                upload.fileName = attachment.fileName;
                                upload.keywords = attachment.fieldName;
                            } else {
                                upload.fileName = attachment;
                            }

                            var description = "Attachment";
                            if (upload.fieldName) {
                                description += " field=" + upload.fieldName;
                            }

                            upload.description = description;

                            if (attachmentsFolder.fileExists(upload.fileName)) {
                                list.push(upload);
                            } else {
                                console.error("upload file not found:", attachmentsFolder.filePath(upload.fileName));
                            }
                        });
                    }
                }
            }
        }

        console.log("uploads list:", JSON.stringify(list, undefined, 2));

        return list;
    }

    //--------------------------------------------------------------------------

    function uploadAttachments(uploads, callback) {
        if (uploads.length <= 0) {
            callback();
            return;
        }

        uploadRequest.uploads = uploads;
        uploadRequest.uploadIndex = 0;
        uploadRequest.callback = callback;

        uploadRequest.uploadItem(0);
    }

    PortalRequest {
        id: uploadRequest

        property var uploads
        property int uploadIndex: 0
        property var callback

        portal: xformFeatureService.portal
        url: featureServiceUrl + "/uploads/upload"
        method: "POST"
        responseType: "json"
        trace: debug

        onSuccess: {
            console.log("upload response:", JSON.stringify(response, undefined, 2));

            if (response.error) {
                xformFeatureService.failed(response.error);
            } else {
                var item = response.item;

                var upload = uploads[uploadIndex];

                upload.itemID = item.itemID;
                upload.itemName = item.itemName;
                upload.date = item.date;
                upload.committed = item.committed;

                uploadIndex++;
                if (uploadIndex < uploads.length) {
                    uploadItem(uploadIndex);
                } else {
                    callback();
                }
            }
        }

        onFailed: {
            console.log("upload error:", JSON.stringify(response, undefined, 2));
            xformFeatureService.failed(response.error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }

        function uploadItem(index) {
            var upload = uploads[index];

            var filePath = attachmentsFolder.filePath(upload.fileName);
            var fileInfo = attachmentsFolder.fileInfo(upload.fileName);

            var contentType = kContentTypes[fileInfo.suffix.toLowerCase()];
            if (!contentType) {
                contentType = kDefaultContentType;
            }

            upload.contentType = contentType;

            var formData = {
                file: uploadPrefix + filePath, // + ";type=application/octet",
                description: upload.description
            }

            console.log("uploading:", JSON.stringify(formData, undefined, 2));

            progressMessage = qsTr("Uploading attachment %1 of %2").arg(index + 1).arg(uploads.length);
            sendRequest(formData);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: applyEditsRequest

        url: featureServiceUrl + "/applyEdits"
        portal: xformFeatureService.portal
        trace: debug
        property var edits
        property var attachments
        property var instanceData

        onSuccess: {
            console.log("applyEdits response:", JSON.stringify(response, undefined, 2));

            var errors = [];
            var summary = {
                adds: 0,
                updates: 0,
                deletes: 0
            };

            function syncResults(tableId, edits, results) {
                for (var i = 0; i < results.length; i++) {
                    var edit = edits[i];
                    var editResult = results[i];

                    edit.result = editResult;

                    if (editResult.error) {
                        var error = editResult.error;

                        error.tableId = tableId;
                        errors.push(error);
                    }
                }
            }

            response.forEach(function (editResult) {
                console.log("editResult:", JSON.stringify(editResult, undefined, 2));

                var edit;
                for (var i = 0; i < edits.length; i++) {
                    if (edits[i].id === editResult.id) {
                        edit = edits[i];

                        var layerInfo = findLayer(editResult.id, true);

                        edit.layerInfo = {
                            "id": layerInfo.id,
                            "name": layerInfo.name,
                            "type": layerInfo.type,
                            "objectIdField": layerInfo.objectIdField,
                            "globalIdField": layerInfo.globalIdField,
                            "relationships": layerInfo.relationships
                        };

                        break;
                    }
                }

                if (editResult.addResults) {
                    summary.adds += editResult.addResults.length;
                    syncResults(editResult.id, edit.adds, editResult.addResults);
                }

                if (editResult.updateResults) {
                    summary.updates += editResult.updateResults.length;
                    syncResults(editResult.id, edit.updates, editResult.updateResults);
                }

                if (editResult.deleteResults) {
                    summary.deletes += editResult.deleteResults.length;
                    syncResults(editResult.id, edit.deletes, editResult.deleteResults);
                }
            });


            console.log("applyEdits edit results:", JSON.stringify(edits, undefined, 2));

            if (errors.length > 0) {
                console.log("applyEdits:errors:", JSON.stringify(errors, undefined, 2));

                xformFeatureService.failed(edits, response, errors);

                if (webhooks) {
                    webhooks.submit(surveyInfo, featureServiceInfo, edits, response);
                }
            } else {
                edits.summary = summary;

                syncInstanceData(instanceData, edits);

                console.log("applyEdits:edits:", JSON.stringify(edits, undefined, 2));

                if (useUploadIds) {
                    xformFeatureService.applied(edits, response, instanceData);
                } else {
                    var attachmentsList = buildAttachmentsList(edits, attachments, response);

                    if (attachmentsList.length > 0) {
                        addAttachments(edits, attachmentsList, instanceData);
                    } else {
                        xformFeatureService.applied(edits, response, instanceData);
                    }
                }
            }
        }

        onFailed: {
            console.log("applyEdits error:", JSON.stringify(response, undefined, 2));
            xformFeatureService.failed(response.error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }
    }

    //--------------------------------------------------------------------------

    function buildAttachmentsList(edits, attachments, results) {

        //        console.log("edits:", JSON.stringify(edits, undefined, 2),
        //                    "attachments:", JSON.stringify(attachments, undefined, 2),
        //                    "results:", JSON.stringify(results, undefined, 2));

        var list = [];

        for (var editIndex = 0; editIndex < edits.length; editIndex++) {
            var edit = edits[editIndex];
            if (!edit) {
                continue;
            }

            if (edit.adds) {
                for (var addIndex = 0; addIndex < edit.adds.length; addIndex++) {
                    var objectId = results[editIndex].addResults[addIndex].objectId;

                    var addAttachments = attachments[edit.id][addIndex];
                    if (Array.isArray(addAttachments)) {
                        addAttachments.forEach(function (attachment) {
                            var item = {
                                id: edit.id,
                                objectId: objectId
                            };

                            if (typeof attachment === "object") {
                                item.fieldName = attachment.fieldName;
                                item.fileName = attachment.fileName;
                            } else {
                                item.fileName = attachment;
                            }

                            if (attachmentsFolder.fileExists(item.fileName)) {
                                list.push(item);
                            } else {
                                console.error("attachment file not found:", attachmentsFolder.filePath(item.fileName));
                            }
                        });
                    }
                }
            }
        }

        console.log("attachmentsList:", JSON.stringify(list, undefined, 2));

        return list;
    }

    //--------------------------------------------------------------------------

    function addAttachments(edits, attachments, instanceData) {
        addAttachmentRequest.edits = edits;
        addAttachmentRequest.attachments = attachments;
        addAttachmentRequest.attachmentIndex  = 0;
        addAttachmentRequest.instanceData = instanceData;

        addAttachmentRequest.addAttachment(0);
    }

    FileFolder {
        id: attachmentsFolder

        path: "~/ArcGIS/My Survey Attachments"

        Component.onCompleted: {
            makeFolder();
        }
    }

    PortalRequest {
        id: addAttachmentRequest

        property var edits
        property var attachments
        property int attachmentIndex: 0
        property var instanceData

        portal: xformFeatureService.portal
        method: "POST"
        responseType: "json"
        trace: debug

        onSuccess: {
            console.log("addAttachment:", JSON.stringify(response, undefined, 2));

            var addAttachmentResult = response.addAttachmentResult;

            if (addAttachmentResult.error) {
                xformFeatureService.failed(addAttachmentResult.error);
            } else {
                attachmentIndex++;
                if (attachmentIndex < attachments.length) {
                    addAttachment(attachmentIndex);
                } else {
                    xformFeatureService.applied(edits, response, instanceData);
                }
            }
        }

        onFailed: {
            console.log("addAttachment error:", JSON.stringify(response, undefined, 2));
            xformFeatureService.failed(response.error);
        }

        onProgressChanged: {
            xformFeatureService.progress = progress;
        }

        function addAttachment(index) {
            var attachment = attachments[index];

            url = featureServiceUrl + "/" + attachment.id.toString() + "/" + attachment.objectId.toString() + "/addAttachment";

            var filePath = attachmentsFolder.filePath(attachment.fileName);

            console.log("addAttachment:", filePath, "url", url);

            var formData = {
                attachment: uploadPrefix + filePath,
            }

            if (attachment.fieldName) {
                formData.keywords = attachment.fieldName;
            }

            progressMessage = qsTr("Adding Attachment %1 of %2").arg(index + 1).arg(attachments.length);
            sendRequest(formData);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: serviceInfoRequest

        portal: xformFeatureService.portal
        method: "POST"
        responseType: "json"

        onSuccess: {
            featureServiceInfo = response;
            objectCache[url] = featureServiceInfo;
        }

        onFailed: {
            featureServiceInfo = undefined;
            objectCache[url] = undefined;
            xformFeatureService.failed(error);
        }
    }

    onFeatureServiceUrlChanged: {
        featureServiceInfo = null;

        if (featureServiceUrl > "") {
            serviceInfoRequest.url = featureServiceUrl;

            var info = objectCache[featureServiceUrl];
            if (info) {
                console.log("Using cached featureServiceInfo:", featureServiceUrl);
                featureServiceInfo = info;
            } else {
                console.log("Requesting featureServiceInfo:", featureServiceUrl);
                serviceInfoRequest.sendRequest();
            }
        }
    }

    onFeatureServiceInfoChanged: {
        console.log("featureServiceInfo:", JSON.stringify(featureServiceInfo, undefined, 2));

        if (featureServiceInfo) {
            featureServiceInfo.itemId = featureServiceItemId;
            featureServiceInfo.url = featureServiceUrl.toString();

            var layers = featureServiceInfo.layers.concat(featureServiceInfo.tables);
            layerInfosRequest.requestInfos(featureServiceUrl, layers);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: layerInfosRequest

        portal: xformFeatureService.portal

        property string serviceUrl
        property var requestQueue: []
        property var currentLayer

        onSuccess: {
            var layerInfo = addLayerInfo(response);
            objectCache[url] = layerInfo;
            getNext();
        }

        onFailed: {
            objectCache[url] = undefined;
            xformFeatureService.failed(error);
        }

        function getNext() {
            if (!requestQueue.length) {
                if (updateRelationships()) {
                    serviceReady();
                }
                return;
            }

            currentLayer = requestQueue.shift();

            progressMessage = currentLayer.name;

            url = serviceUrl + "/" + currentLayer.id.toString();

            var layerInfo = objectCache[url];
            if (layerInfo) {
                console.log("Using cached layerInfo:", url);
                addLayerInfo(layerInfo);
                Qt.callLater(layerInfosRequest.getNext);
            } else {
                console.log("Requesting layerInfo:", url);
                sendRequest();
            }
        }

        function requestInfos(serviceUrl, requestQueue) {
            layerInfos = [];

            layerInfosRequest.serviceUrl = serviceUrl;
            layerInfosRequest.requestQueue = requestQueue;

            getNext();
        }
    }

    //--------------------------------------------------------------------------

    function addLayerInfo(layerInfo) {
        layerInfo.drawingInfo = undefined;
        layerInfo.templates = undefined;
        layerInfo.indexes = undefined;
        for (var i = 0; i < layerInfo.fields.length; i++) {
            layerInfo.fields[i].domain = undefined;
        }

        layerInfo.parentRelationships = [];
        layerInfo.childRelationships = [];

        console.log("Feature layerInfo:", JSON.stringify(layerInfo, undefined, 2));

        layerInfos[layerInfo.id] = layerInfo;

        return layerInfo;
    }

    //--------------------------------------------------------------------------

    function findLayer(name, searchIds) {
        for (var i = 0; i < featureServiceInfo.layers.length; i++) {
            var info = featureServiceInfo.layers[i];

            if (searchIds ? info.id == name : info.name === name) {
                return layerInfos[info.id];
            }
        }

        for (i = 0; i < featureServiceInfo.tables.length; i++) {
            info = featureServiceInfo.tables[i];

            if (searchIds ? info.id == name : info.name === name) {
                return layerInfos[info.id];
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    function findField(layerInfo, name) {
        for (var i = 0; i < layerInfo.fields.length; i++) {
            var layerField = layerInfo.fields[i];

            if (name === layerField.name) {
                return layerField;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    function findRelationship(layerInfo, relatedLayerInfo) {
        var relationships = layerInfo.relationships.filter(function(relationship) {
            return relationship.relatedTableId === relatedLayerInfo.id;
        });

        if (relationships.length <= 0) {
            console.error("Relationship not found in:", layerInfo.id, layerInfo.name, "for:", relatedLayerInfo.id, relatedLayerInfo.name);
            //console.error("Relationships:", JSON.stringify(layerInfo.relationships, undefined, 2));
            return;
        }

        return relationships[0];
    }

    //--------------------------------------------------------------------------

    function updateRelationships() {
        function updateChildRelationship(childLayerInfo) {
            if (XFormJS.isNullOrUndefined(childLayerInfo.relationships)) {
                return;
            }

            var childRelationship;

            for (var i = 0; i < childLayerInfo.relationships.length; i++) {
                var relationship = childLayerInfo.relationships[i];

                if (relationship.cardinality === "esriRelCardinalityOneToMany" &&
                        relationship.role === "esriRelRoleDestination") {
                    childRelationship = relationship;
                    break;
                }
            }

            if (!childRelationship) {
                return;
            }

            var childKeyField = findField(childLayerInfo, childRelationship.keyField);
            if (!childKeyField) {
                console.error("Child keyField not found:", childRelationship.keyField);
                return;
            }

            if (childKeyField.type !== "esriFieldTypeGUID") {
                console.error("Unsupported childKeyField type:", childKeyField.type);
                return;
            }

            childRelationship.keyFieldInfo = childKeyField;

            var parentLayerInfo = layerInfos[childRelationship.relatedTableId];
            if (!parentLayerInfo) {
                return;
            }

            var parentRelationship;

            for (i = 0; i < parentLayerInfo.relationships.length; i++) {
                relationship = parentLayerInfo.relationships[i];

                if (relationship.id === childRelationship.id) {
                    if (relationship.cardinality === "esriRelCardinalityOneToMany" &&
                            relationship.role === "esriRelRoleOrigin") {
                        parentRelationship = relationship;
                        console.log("relationship:", parentRelationship.id, parentRelationship.name, "<==>", childRelationship.name);
                        break;
                    } else {
                        return;
                    }
                }
            }

            if (!parentRelationship) {
                return;
            }

            var parentKeyField = findField(parentLayerInfo, parentRelationship.keyField);
            if (!parentKeyField) {
                console.error("Parent keyField not found:", parentRelationship.keyField);
                return;
            }

            if (parentKeyField.type !== "esriFieldTypeGUID" && parentKeyField.type !== "esriFieldTypeGlobalID") {
                console.error("Unsupported parentKeyField type:", parentKeyField.type);
                return;
            }

            if (parentKeyField.type === "esriFieldTypeGlobalID" && !featureServiceInfo.supportsApplyEditsWithGlobalIds) {
                console.error("Feature service requires supportsApplyEditsWithGlobalIds for parent keyField type:", parentKeyField.type);
                return;
            }

            parentRelationship.keyFieldInfo = parentKeyField;

            console.log("child name:", childLayerInfo.name, "childRelationship:", JSON.stringify(childRelationship, undefined, 2));
            console.log("parent name:", parentLayerInfo.name, "parentRelationship:", JSON.stringify(parentRelationship, undefined, 2));

            childLayerInfo.parentRelationships[parentLayerInfo.name] = childRelationship;
            parentLayerInfo.childRelationships[childLayerInfo.name] = parentRelationship;

            if (parentKeyField.type === "esriFieldTypeGlobalID") {
                useGlobalIds = true;
            }

            return true;
        }


        for (var i = 0; i < layerInfos.length; i++) {
            var layerInfo = layerInfos[i];
            console.log("Updating relationship for:", layerInfo.name);
            updateChildRelationship(layerInfo);
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function resolveLayerReferences(edits) {
        for (var i = 0; i < edits.length; i++) {
            var edit = edits[i];

            var layerRef = edit["id"].toString();
            var layerPrefix = layerRef.substring(0, 1);
            var layerInfo;
            if (layerPrefix === "%" || layerPrefix === "$") {
                var layerName = layerRef.substring(1);
                layerInfo = findLayer(layerName);
                if (layerInfo) {
                    edit["id"] = layerInfo.id;
                } else {
                    if (layerPrefix === "%") {
                        edit["id"] = 0;
                        layerInfo = findLayer(0, true);

                        console.warn("No match for layer:", layerName, "default to layer 0:", layerInfo.name);
                    } else {
                        return {
                            code: -100,
                            description: "No match for layer: %1".arg(layerName)
                        };
                    }
                }
            } else {
                var layerId = Number(layerRef);
                edit["id"] = layerId;
                layerInfo = findLayer(layerId, true);

                if (!layerInfo) {
                    return {
                        code: -101,
                        description: "No match for layer id: %1".arg(layerId)
                    };
                }
            }

            switch (layerInfo.type) {
            case "Feature Layer":
                checkGeometries(layerInfo, edit.adds);
                checkGeometries(layerInfo, edit.updates);
                break;

            case "Table":
                removeGeometries(edit.adds);
                removeGeometries(edit.updates);
                break;
            }

            var error = resolveFieldReferences(layerInfo, edits, edit.adds);
            if (!error) {
                error = resolveFieldReferences(layerInfo, edits, edit.updates);
            }

            if (error) {
                return error;
            }
        }

        removeMetaProperties(edits);
    }

    //--------------------------------------------------------------------------

    function findProperty(object, name, purpose) {
        if (!object) {
            console.error(arguments.callee.name, purpose, "Invalid object parameter");
            return;
        }

        if (typeof name !== "string") {
            console.error(arguments.callee.name, purpose, "Invalid name parameter");
            return;
        }

        var keys = Object.keys(object);

        for (var i = 0; i < keys.length; i++) {
            if (name === keys[i]) {
                return object[keys[i]];
            }
        }

        // console.debug(arguments.callee.name, purpose, "Trying case insensitive search for:", name);

        for (i = 0; i < keys.length; i++) {
            if (name.toLowerCase() === keys[i].toLowerCase()) {
                return object[keys[i]];
            }
        }

        //console.error(arguments.callee.name, purpose, "Unable to match name:", name, "in:", JSON.stringify(keys));

        //As in resolveLayerReferences(), assume a non-match is layer 0
        //This occurs only with the parent form so should be 1 length array
        console.warn("No match for relationship to:", name, "default to layer 0:")
        return object[keys[0]];
    }

    //--------------------------------------------------------------------------

    function removeMetaProperties(edits) {

        console.log("removing meta properties:", edits.length);

        function _removeMetaProperties(a) {
            if (!Array.isArray(a)) {
                return;
            }

            for (var i = 0; i < a.length; i++) {
                var atts = a[i].attributes;

                var keys = Object.keys(atts);
                for (var j = 0; j < keys.length; j++) {
                    var key = keys[j];
                    var c = key.substring(0, 1);
                    if (c === ">" || c === "<") {
                        atts[key] = undefined;
                    }
                }
            }
        }

        for (var i = 0; i < edits.length; i++) {
            var edit = edits[i];

            _removeMetaProperties(edit.adds);
            _removeMetaProperties(edit.updates);
            _removeMetaProperties(edit.deletes);
        }
    }

    //--------------------------------------------------------------------------

    function resolveFieldReferences(layerInfo, edits, features) {
        if (!Array.isArray(features)) {
            return;
        }

        // console.log("resolving features:", layerInfo.name);

        var error;

        function setError(code, description) {
            error = {
                code: code,
                description: description
            };
        }

        function findParentFeature(key, value) {

            function findByKey(a) {
                if (!Array.isArray(a)) {
                    return;
                }

                for (var i = 0; i < a.length; i++) {
                    if (a[i].attributes[key] === value) {
                        return a[i];
                    }
                }
            }

            for (var i = 0; i < edits.length; i++) {
                var feature = findByKey(edits[i].updates);
                if (feature) {
                    return feature;
                }

                feature = findByKey(edits[i].adds);
                if (feature) {
                    return feature;
                }
            }

            console.error("No feature found for key:", key, "=", value);
        }

        function resolveAttributes(attributes) {
            if (!attributes) {
                return;
            }

            function resolveKeyField(key) {
                var prefix = key.substring(0, 1);
                if ("<>".indexOf(prefix) < 0) {
                    return true;
                }

                var keyValue = attributes[key];
                var tableName = key.substring(1);

                function resolveParentKey() {
                    var relationship = findProperty(layerInfo.childRelationships, tableName, "Parent to child relationship");
                    if (!relationship) {
                        setError(-201, "Parent to child relationship not found for '%1 to '%2".arg(tableName).arg(layerInfo.name));
                        return;
                    }

                    var relationshipKeyValue = attributes[relationship.keyField];

                    if (XFormJS.isEmpty(relationshipKeyValue)) {
                        console.log("Setting keyValue for:", key, "==>", relationship.keyField, "=", keyValue);
                        attributes[relationship.keyField] = keyValue;
                    } else {
                        console.log("Using keyValue for:", key, "==>", relationship.keyField, "=", relationshipKeyValue);
                    }

                    return true;
                }

                function resolveChildKey() {
                    var relationship = findProperty(layerInfo.parentRelationships, tableName, "Child to parent relationship");
                    if (!relationship && tableName === "myform") {
                        tableName = Object.keys(layerInfo.parentRelationships)[0];
                        relationship = layerInfo.parentRelationships[tableName];

                        console.warn("Workaround for relationship key:", key, "using parent table name:", tableName);
                    }

                    if (!relationship) {
                        setError(-301, "Child to parent relationship not found for '%1 to '%2".arg(layerInfo.name).arg(tableName));
                        return;
                    }


                    var parentLayer = findLayer(relationship.relatedTableId, true);
                    var parentRelationship = findRelationship(parentLayer, layerInfo);
                    var parentFeature = findParentFeature(">" + layerInfo.name, keyValue);

                    console.log("parentFeature:", JSON.stringify(parentFeature, undefined, 2));

                    var parentKeyValue = parentFeature.attributes[parentRelationship.keyField];

                    if (XFormJS.isEmpty(parentKeyValue)) {
                        console.error("Parent key not defined:", key, "==>", parentRelationship.keyField, "=", parentKeyValue);
                        setError(-302, "Parent key not defined");
                        return;
                    }

                    console.log("Parent keyValue for:", key, "==>", relationship.keyField, "=", parentKeyValue);
                    attributes[relationship.keyField] = parentKeyValue;

                    return true;
                }

                switch (prefix) {
                case ">": // Parent/origin key
                    return resolveParentKey();

                case "<": // Child/destination key
                    return resolveChildKey();
                }

                return true;
            }

            // console.log("resolving attributes:", JSON.stringify(attributes, undefined, 2));

            var keys = Object.keys(attributes);
            for (var i = 0; i < keys.length; i++) {
                if (!resolveKeyField(keys[i])) {
                    console.error("Unable to resolve key field:", keys[i]);
                    return;
                }
            }

            //console.log("useGlobalIds for:", layerInfo.name, "=", useGlobalIds);

            if (useGlobalIds) {
                layerInfo.fields.forEach(function (fieldInfo) {
                    if (fieldInfo.type === "esriFieldTypeGlobalID") {
                        if (XFormJS.isEmpty(attributes[fieldInfo.name])) {
                            attributes[fieldInfo.name] = AppFramework.createUuidString(0).toUpperCase();
                        }
                    }
                });
            }

            return true;
        }

        for (var i = 0; i < features.length; i++) {
            if (!resolveAttributes(features[i].attributes))
            {
                return error;
            }
        }

        return error;
    }

    //--------------------------------------------------------------------------

    function checkGeometries(layerInfo, features) {
        if (!Array.isArray(features)) {
            return;
        }

        function checkGeometry(geometry) {
            if (!geometry) {
                return;
            }

            if (!layerInfo.hasZ) {
                //delete geometry.z;
                geometry.z = undefined;
            }

            if (!layerInfo.hasM) {
                //delete geometry.m;
                geometry.m = undefined;
            }
        }

        for (var i = 0; i < features.length; i++) {
            checkGeometry(features[i].geometry);
        }
    }

    //--------------------------------------------------------------------------

    function removeGeometries(features) {
        if (!Array.isArray(features)) {
            return;
        }

        for (var i = 0; i < features.length; i++) {
            var feature = features[i];

            if (feature.geometry) {
                //delete feature.geometry;
                feature.geometry = undefined;
            }
        }
    }

    //--------------------------------------------------------------------------

    function syncInstanceData(instanceData, edits) {
        console.log(arguments.callee.name, "instanceName:", schema.instanceName);

        xformData.instance = instanceData;

        var parentTable = schema.schema;
        var parentLayer = findLayer(parentTable.tableName);
        if (!parentLayer) {
            console.warn("parentLayer fallback");
            parentLayer = findLayer(0, true);
        }

        var parentData = instanceData[schema.instanceName];

        console.log("syncing instance parentLayer:", parentLayer.id, "name:", parentLayer.name, "type:", parentLayer.type, "#edits:", edits.length);

        edits.forEach(function (edit) {
            var layer;
            var relatedRows;

            if (edit.id === parentLayer.id) {
                layer = parentLayer;
                relatedRows = null;
            } else {
                layer = findLayer(edit.layerInfo.name);
                relatedRows = parentData[layer.name];
            }

            console.log("syncing layer:", layer.id, "name:", layer.name, "type:", layer.type);

            if (Array.isArray(edit.adds)) {

                console.log("Processing adds:", edit.adds.length);

                var addIndices = [];

                if (relatedRows) {
                    relatedRows.forEach(function (relatedData, index) {
                        var editMode = xformData.metaValue(relatedData, xformData.kMetaEditMode, xformData.kEditModeAdd);

                        if (editMode === xformData.kEditModeAdd) {
                            addIndices.push(index);
                        }
                    });

                    console.log("addIndices:", JSON.stringify(addIndices));
                }

                edit.adds.forEach(function (add, addIndex) {
                    var data;

                    if (edit.id === parentLayer.id) {
                        data = parentData;
                    }
                    else {
                        data = relatedRows[addIndices[addIndex]];
                    }

                    if (data) {
                        var globalId = add.result["globalId"];
                        var objectId = add.result["objectId"];
                        var globalIdField = edit.layerInfo.globalIdField;
                        var objectIdField = edit.layerInfo.objectIdField;

                        if (globalIdField > "" && globalId) {
                            data[globalIdField] = globalId;
                            xformData.setMetaValue(data, xformData.kMetaGlobalIdField, globalIdField);
                        }

                        if (objectIdField > "" && objectId) {
                            data[edit.layerInfo.objectIdField] = objectId;
                            xformData.setMetaValue(data, xformData.kMetaObjectIdField, objectIdField);
                        }

                        xformData.setMetaValue(data, xformData.kMetaEditMode, xformData.kEditModeUpdate);

                        if (Array.isArray(edit.layerInfo.relationships)) {
                            edit.layerInfo.relationships.forEach(function (relationship) {
                                data[relationship.keyField] = add.attributes[relationship.keyField];
                            });
                        }

                    } else {
                        console.error("No match for table:", edit.layerInfo.name);
                    }
                });
            }

            if (Array.isArray(edit.updates)) {

                console.log("Processing updates:", edit.updates.length);

                edit.updates.forEach(function (update) {
                    var data;

                    if (layer === parentLayer) {
                        data = parentData;
                    } else {
                        //                        data = matchRow(update);
                    }
                });
            }

            if (Array.isArray(edit.deletes)) {

                console.log("Processing deletes:", edit.deletes.length);

                edit.deletes.forEach(function (del) {
                });
            }

        });

        // console.log("synced instanceData:", JSON.stringify(instanceData, undefined, 2));
    }

    //--------------------------------------------------------------------------

    XFormData {
        id: xformData

        schema: xformFeatureService.schema
    }

    //--------------------------------------------------------------------------
}
