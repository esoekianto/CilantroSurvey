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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Item {
    id: formData

    property var instance: ({})
    property var tableRowIndicies;
    property var changeBinding

    property bool debug: false

    property XFormSchema schema
    property string snippetExpression
    property var instanceNameBinding

    property int defaultWkid: 4326
    property var nullGeometry: { "x": 0, "y": 0, "z": Number.NaN, "spatialReference": { "wkid": 4326 } }

    readonly property alias expressionsList: expressionsList

    property var locale: Qt.locale()

    property int editMode: kEditModeAdd

    //--------------------------------------------------------------------------

    readonly property string kKeyMetadata: "__meta__"
    readonly property string kMetaEditMode: "editMode"
    readonly property string kMetaObjectIdField: "objectIdField"
    readonly property string kMetaGlobalIdField: "globalIdField"

    readonly property int kEditModeAdd: 0
    readonly property int kEditModeUpdate: 1
    readonly property int kEditModeDelete: 2

    //--------------------------------------------------------------------------

    signal tableRowIndexChanged(string name, int rowIndex);

    //--------------------------------------------------------------------------

    XFormExpressionList {
        id: expressionsList

        getValue: typedValue
        getValues: typedValues
        debug: formData.debug
    }

    //--------------------------------------------------------------------------

    onInstanceChanged: {
        editMode = metaValue(instance[schema.instanceName], kMetaEditMode, kEditModeAdd);
        console.log("Data editMode:", editMode);
    }

    //--------------------------------------------------------------------------

    function getTableRow(name, rowIndex, noCreate) {

        var table = schema.tableNodes[name];
        var rootTableName = table.parentNames.length === 0 ? table.name : table.parentNames[0];

        if (typeof instance[rootTableName] != "object") {
            if (noCreate) {
                return;
            }

            instance[rootTableName] = {};
        }

        var rootData = instance[rootTableName];
        var rowData = rootData;

        if (table.parentNames.length > 0) {
            var tableNames = table.parentNames.concat([table.name]);

            for (var i = 1; i < tableNames.length; i++) {
                var tableName = tableNames[i];

                if (!Array.isArray(rowData[tableName])) {
                    if (noCreate) {
                        return;
                    }

                    rowData[tableName] = [];
                }

                if (!isNumber(rowIndex)) {
                    rowIndex = tableRowIndex(tableName);
                }

                //                if (rowIndex >= rowData[tableName].length) {
                //                    rowIndex = 0;
                //                }

                if (typeof rowData[tableName][rowIndex] != "object") {
                    if (noCreate) {
                        return;
                    }

                    rowData[tableName][rowIndex] = {};
                }

                rowData = rowData[tableName][rowIndex];
            }
        }

        return rowData;
    }

    //--------------------------------------------------------------------------

    function getTableRows(name) {
        var table = schema.tableNodes[name];

        if (!table) {
            console.warn("getTableRows:", name, "Schema not ready");
            return [];
        }

        var rootTableName = table.parentNames.length === 0 ? table.name : table.parentNames[0];

        if (typeof instance[rootTableName] != "object") {
            instance[rootTableName] = {};
        }

        var rootData = instance[rootTableName];
        var rowData = rootData;

        var tableNames = table.parentNames.concat([table.name]);

        for (var i = 1; i < tableNames.length; i++) {
            var tableName = tableNames[i];

            if (!Array.isArray(rowData[tableName])) {
                rowData[tableName] = [];
            }
        }

        return rowData[table.name];
    }

    //--------------------------------------------------------------------------

    function tableRowIndex(name) {
        if (!tableRowIndicies) {
            return 0;
        }

        var rowIndex = tableRowIndicies[name];

        if (!isNumber(rowIndex)) {
            rowIndex = 0;
        }

        return rowIndex;
    }

    function setTableRowIndex(name, rowIndex) {

        if (!tableRowIndicies) {
            tableRowIndicies = {};
        }

        if (tableRowIndicies[name] === rowIndex) {
            return;
        }

        console.log("setTableRowIndex:", name, rowIndex, "was:", tableRowIndicies[name]);

        tableRowIndicies[name] = rowIndex;

        tableRowIndexChanged(name, rowIndex);
    }

    //--------------------------------------------------------------------------

    function deleteTableRow(name, rowIndex) {
        var tableRows = getTableRows(name);

        if (rowIndex < 0 || rowIndex >= tableRows.length) {
            console.log("deleteTableRow:", name, rowIndex, "out of range", tableRows.length);

            return false;
        }

        tableRows.splice(rowIndex, 1);

        if (rowIndex > 0 && rowIndex >= tableRows.length) {
            rowIndex = tableRows.length - 1;
        }

        tableRowIndexChanged(name, rowIndex);

        return true;
    }

    //--------------------------------------------------------------------------

    function setTableRows(name, rowCount) {
        var tableRows = getTableRows(name);


        var defaultValues = schema.tableInstance(name);

        if (!defaultValues) {
            defaultValues = {};
        }

        console.log("setTableRows:", name, "length:", tableRows.length, "rowCount:", rowCount, "defaultValues:", JSON.stringify(defaultValues));

        while (tableRows.length > rowCount) {
            tableRows.pop();
        }

        while (tableRows.length < rowCount) {
            tableRows.push(XFormJS.clone(defaultValues));
        }
    }

    //--------------------------------------------------------------------------

    function value(binding) {
        var nodeset = binding["@nodeset"];

        //console.log("value for", JSON.stringify(binding, undefined, 2));

        return valueById(nodeset);
    }

    //--------------------------------------------------------------------------

    function typedValue(nodeset) {
        var field = schema.fieldNodes[nodeset];

        if (!field) {
            console.error("typedValue: No matching field for:", nodeset);
            return;
        }

        var data = getTableRow(field.tableName, undefined, true);
        if (!data) {
            if (debug) {
                console.log("typedValued empty data:", field.tableName)
            }

            return XFormJS.toBindingType(undefined, field.binding);
        }

        var value = XFormJS.toBindingType(data[field.name], field.binding);

        if (debug) {
            console.log("typedValue:", typeof value, nodeset, '=', value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function typedValues(nodeset) {
        var field = schema.fieldNodes[nodeset];

        if (!field) {
            console.error("typedValues: No matching field for:", nodeset);
            return;
        }

        var values = [];
        var dataRows = getTableRows(field.tableName);
        dataRows.forEach(function(data) {
            if (data) {
                var value = XFormJS.toBindingType(data[field.name], field.binding);
                if (!XFormJS.isEmpty(value)) {
                    values.push(value);
                }
            }
        });

        if (debug) {
            console.log("typedValues:", nodeset, '=', JSON.stringify(values));
        }

        return values;
    }

    //--------------------------------------------------------------------------

    function valueById(id) {
        var field = schema.fieldNodes[id];

        if (!field) {
            console.error("valueById: No matching field for", id);
            return;
        }

        var data = getTableRow(field.tableName, undefined, true);
        if (!data) {
            return;
        }

        var value = data[field.name];

        if (debug) {
            console.log("valueById:", typeof value, id, '=', value);
        }

        return typeof value === "undefined" ? "" : value;
    }

    //--------------------------------------------------------------------------

    function valueByField(field, values) {
        if (!values) {
            values = getTableRow(field.tableName, undefined, true);
        }

        if (!values) {
            return;
        }


        var value = values[field.name];

        // console.log("valuesByField:", field.name, "value:", value, "values:", JSON.stringify(values, undefined, 2));

        if (debug) {
            console.log("valueByField", field.name, '=', value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function setValue(binding, value, rowIndex) {
        if (debug) {
            console.log("setValue", value, "binding", JSON.stringify(binding, undefined, 2));
        }

        var nodeset = binding["@nodeset"];

        if (!nodeset) {
            console.warn("setValue: No nodeset in binding:", JSON.stringify(binding));
            return;
        }

        var field = schema.fieldNodes[nodeset];

        if (!field) {
            console.error("setValue: No matching field for nodeset:", nodeset);
            //console.trace();
            return;
        }

        if (typeof value !== "number" && isDateField(field)) {
            var dateValue = XFormJS.toDate(value);
            value = dateValue.valueOf();
        }

        setFieldValue(field, value, rowIndex);

        if (debug) {
            console.log("setValue: instance", JSON.stringify(instance, undefined, 2));
        }

        changeBinding = binding;

        expressionsList.valueChanged(nodeset, value);
    }

    //--------------------------------------------------------------------------

    function setFieldValue(field, value, rowIndex) {

        if (debug) {
            console.log("table", field.tableName, "rowIndex", rowIndex, "field", field.name, "value", value);
        }

        var rowData = getTableRow(field.tableName, rowIndex);

        if (XFormJS.isEmpty(value)) {
            if (field.required) {
                value = nullValue(field);
            } else {
                value = null;
            }
        }

        rowData[field.name] = value;
    }

    //--------------------------------------------------------------------------

    function nullValue(field) {
        var value;

        switch (field.esriFieldType) {
        case "esriFieldTypeString" :
            value = "";
            break;

        case "esriFieldTypeInteger":
        case "esriFieldTypeDouble":
            value = null;
            break;

        case "esriFieldTypeDate":
            value = null;
            break;

        case "esriFieldTypeGUID":
        default:
            console.warn("Undefined null value for field:", field.name, "type:", field.esriFieldType);
            break;
        }

        console.warn("Default null value:", JSON.stringify(value), "field:", field.name, "type:", field.esriFieldType);

        return value;
    }

    //--------------------------------------------------------------------------

    function isDateField(field) {
        return field.type === "date" ||
                field.type === "dateTime" ||
                field.esriFieldType === "esriFieldTypeDate";
    }

    //--------------------------------------------------------------------------

    function relevantBinding(binding) {
        var expressionInstance = expressionsList.addExpression(
                    binding["@relevant"],
                    binding["@nodeset"],
                    "relevant");

        return expressionInstance.boolBinding(true);
    }

    //--------------------------------------------------------------------------

    function calculateBinding(binding) {
        if (!binding) {
            return "";
        }

        var calculate = binding["@calculate"];
        if (!calculate) {
            return "";
        }

        var expressionInstance = expressionsList.addExpression(calculate, binding["@nodeset"], "calculate");

        return expressionInstance.binding();
    }

    //--------------------------------------------------------------------------

    function numberBinding(expression, purpose) {
        var expressionInstance = expressionsList.addExpression(expression, purpose);

        return expressionInstance.numberBinding();
    }

    //--------------------------------------------------------------------------

    function valueToken(value) {
        switch (typeof value) {
        case "string":
            return "'" + value + "'";

        case "number":
        case "boolean":
            return value.toString();

        case "undefined":
            return "''";

        default:
            if (Array.isArray(value)) {
                // return "'" + value.join(",") + "'";
                return JSON.stringify(value);
            }

            console.warn("valueToken", typeof value, "value", JSON.stringify(value));
            return "'" + JSON.stringify(value) + "'";
        }
    }

    //--------------------------------------------------------------------------

    function createConstraint(control, binding) {
        var expression = binding["@constraint"];
        var message = binding["@jr:constraintMsg"];

        console.log("createConstraint:", expression, "message:", message, "binding:", JSON.stringify(binding));

        return constraint.createObject(control, {
                                           "binding": binding,
                                           "expression": expression,
                                           "message": message
                                       });
    }

    Component {
        id: constraint

        QtObject {
            property var binding
            property string expression
            property string message
            property XFormExpression expressionInstance

            //------------------------------------------------------------------

            Component.onCompleted: {
                expressionInstance = expressionsList.addExpression(expression, binding["@nodeset"], "constraint");
            }

            //------------------------------------------------------------------

            function getLabel(field, controlNode) {
                var label = binding["@nodeset"];

                if (controlNode && controlNode.group && controlNode.group.labelControl) {
                    label = controlNode.group.labelControl.value;
                } else if (field) {
                    label = field.label;
                }

                return label;
            }

            //------------------------------------------------------------------

            function getMessage(field, controlNode) {
                return message > ""
                        ? textLookup(message)
                        : qsTr("<b>%1</b> is invalid").arg(getLabel(field, controlNode));
            }

            //------------------------------------------------------------------

            function getError(activeExpression) {
                var nodeset = binding["@nodeset"];
                var field = schema.fieldNodes[nodeset];
                var controlNode = controlNodes[nodeset];

                var error = {
                    "type": "constraint",
                    "binding": binding,
                    "message": getMessage(field, controlNode),
                    "expression": expression,
                    "activeExpression": activeExpression,
                    "nodeset": nodeset,
                    "field": field,
                    "label": getLabel(field, controlNode),
                    "controlNode": controlNode
                };

                return error;
            }

            //------------------------------------------------------------------

            function validateError(currentValue) {
                var nodeset = expressionInstance.thisNodeset;

                if (debug) {
                    console.log("validateError:", nodeset, "currentValue:", currentValue);
                }

                function valueRef(ref) {
                    if (debug) {
                        console.log("validate valueRef:", ref, "currentValue:", currentValue, "nodeset:", nodeset);
                    }

                    if (ref === nodeset && currentValue) {
                        return valueToken(currentValue);
                    }

                    return expressionInstance._valueRef(ref);
                }

                var jsExpression = expressionInstance.translate(expression, nodeset, null, valueRef);

                var result = Boolean(expressionInstance.tryEval(jsExpression, false));

                if (debug) {
                    console.log("validateError:", result, "from:", jsExpression);
                }

                if (!result) {
                    return getError(jsExpression);
                }

                return undefined;
            }

            //------------------------------------------------------------------

            function validate() {
                var result = Boolean(expressionInstance.evaluate(false));

                if (debug) {
                    console.log("validate:", result, "from:", expressionInstance.expression);
                }

                if (!result) {
                    var error = getError(expressionInstance.jsExpression);

                    validationError(error);
                }

                return result;
            }
        }
    }

    //--------------------------------------------------------------------------

    function toFeature(table, data) {
        if (!table || !data) {
            console.error("toFeature:", JSON.stringify(table), "data:", JSON.stringify(data));
            return;
        }

        var editMode = metaValue(data, kMetaEditMode, kEditModeAdd);
        var objectIdField = metaValue(data, kMetaObjectIdField, "objectid");
        var globalIdField = metaValue(data, kMetaGlobalIdField, "globalid");

        var attributes = JSON.parse(JSON.stringify(data));

        if (!attributes) {
            attributes = {};
        }

        var geometry;
        if (table.geometryFieldName) {
            var geometryValue = attributes[table.geometryFieldName];

            function isOrdinate(value) {
                return typeof value == "number" && isFinite(value);
            }

            if (!XFormJS.isNullOrUndefined(geometryValue) && typeof geometryValue === "object" && isOrdinate(geometryValue.x) && isOrdinate(geometryValue.y)) {
                geometry = {
                    "x": geometryValue.x,
                    "y": geometryValue.y,
                    "z": geometryValue.z,
                    "spatialReference": geometryValue.spatialReference
                };
            }

            // delete attributes[table.geometryFieldName];
            attributes[table.geometryFieldName] = undefined;
        }

        // delete attributes[kKeyMetadata];
        attributes[kKeyMetadata] = undefined;

        var keys = Object.keys(attributes);
        keys.forEach(function (key) {
            if (editMode && (key === objectIdField || key === globalIdField)) {
                return;
            }

            if (!table.fieldsRef[key] && Array.isArray(attributes[key])) {
                // delete attributes[key];
                attributes[key] = undefined;
            } else if (Array.isArray(attributes[key])) {
                attributes[key] = attributes[key].join(",");
            } else {
                attributes[key] = featureValue(attributes[key], table.fieldsRef[key]);
            }
        });


        var feature = {
            attributes: attributes
        };

        // Build list of attachment file names

        if (table.hasAttachments) {
            var attachments = [];

            table.fields.forEach(function (field) {
                if (field.attachment) {
                    var attachment = attributes[field.name];

                    if (attachment > "") {
                        var attachmentInfo = {
                            "editMode": 0,
                            "fieldName": field.name,
                            "fileName": attachment
                        };

                        attachments.push(attachmentInfo);
                    }

                    // delete attributes[field.name];
                    attributes[field.name] = undefined;
                }
            });

            feature.attachments = attachments;
        }

        if (table.geometryFieldName > "") {
            if (geometry) {
                if (!geometry.spatialReference) {
                    geometry.spatialReference = {
                        "wkid" : defaultWkid
                    };
                }

                feature.geometry = geometry;
            } else {
                feature.geometry = nullGeometry;
            }
        }

        setMetaValue(feature, kMetaEditMode, editMode);

        return feature;
    }

    //--------------------------------------------------------------------------

    function featureValue(value, field) {
        if (!field) {
            console.log("Skip meta value transform:", value);
            return value;
        }

        if (!field.esriFieldType) {
            console.log("Skip null esriFieldType value:", value);
            return;
        }

        //console.log("featureValue:", field.type, "esriFieldType:", field.esriFieldType, "value:", value, "typeof:", typeof value);

        switch (field.type) {
        case "string":
            value = featureValueString(value, field);
            break;

        case "date":
            value = featureValueDate(value, field);
            break;

        case "dateTime":
            value = featureValueDateTime(value, field);
            break;

        case "time":
            value = featureValueTime(value, field);
            break;
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function featureValueString(value, field) {
        var featureValue = value;

        switch (field.esriFieldType) {
        case "esriFieldTypeGUID":
            if (value > "") {
                featureValue = "{" + value + "}";
            }
            break;

        case "esriFieldTypeInteger":
        case "esriFieldTypeSmallInteger":
        case "esriFieldTypeSingle":
        case "esriFieldTypeDouble":
            featureValue = XFormJS.toNumber(value);
        }

        return featureValue;
    }

    //--------------------------------------------------------------------------

    function featureValueDate(value, field) {
        var featureValue = value;
        var dateValue = new Date(value);

        if (XFormJS.isEmpty(value) || XFormJS.isEmpty(dateValue)) {
            if (debug) {
                console.log("featureValueDate:", field.name, "value:", value, "dateValue:", dateValue, "featureValue => <null>");
            }

            return null;
        }

        switch (field.esriFieldType) {
        case "esriFieldTypeString" :
            switch (field.appearance) {
            case "week-number":
                featureValue = XFormJS.weekNumber(dateValue).toString();
                break;

            case "month-year":
                featureValue = Qt.formatDate(dateValue, "yyyy-MM");
                break;

            case "year":
                featureValue = Qt.formatDate(dateValue, "yyyy");
                break;

            default:
                featureValue = Qt.formatDate(dateValue, Qt.ISODate);
                break;
            }
            break;

        case "esriFieldTypeInteger" :
        case "esriFieldTypeSmallInteger":
        case "esriFieldTypeDouble":
            switch (field.appearance) {
            case "week-number":
                featureValue = XFormJS.weekNumber(dateValue);
                break;

            case "year":
                featureValue = dateValue.getFullYear();
                break;
            }
            break;

        case "esriFieldTypeDate":
            featureValue = dateValue.valueOf();
            break;

        default:
            break;
        }

        if (debug) {
            console.log("featureValueDate:", field.name, "value:", value, "dateValue:", dateValue, "featureValue:", featureValue);
        }

        return featureValue;
    }

    //--------------------------------------------------------------------------

    function featureValueDateTime(value, field) {
        var featureValue = value;
        var dateValue = new Date(value);

        if (XFormJS.isEmpty(value) || XFormJS.isEmpty(dateValue)) {
            if (debug) {
                console.log("featureValueDateTime:", field.name, "value:", value, "dateValue:", dateValue, "featureValue => <null>");
            }

            return null;
        }

        switch (field.esriFieldType) {
        case "esriFieldTypeString" :
            featureValue = Qt.formatDateTime(dateValue, Qt.ISODate);
            break;

        case "esriFieldTypeDate":
            featureValue = dateValue.valueOf();
            break;

        default:
            break;
        }

        if (debug) {
            console.log("featureValueDateTime:", field.name, "value:", value, "dateValue:", dateValue, "featureValue:", featureValue);
        }

        return featureValue;
    }

    //--------------------------------------------------------------------------

    function featureValueTime(value, field) {
        var featureValue = value;
        var dateValue = new Date(value);

        if (XFormJS.isEmpty(value) || XFormJS.isEmpty(dateValue)) {
            if (debug) {
                console.log("featureValueTime:", field.name, "value:", value, "dateValue:", dateValue, "featureValue => <null>");
            }

            return null;
        }

        switch (field.esriFieldType) {
        case "esriFieldTypeString" :
        default:
            featureValue = Qt.formatTime(dateValue, "HH:mm");
            break;
        }

        if (debug) {
            console.log("featureValueTime:", field.name, "value:", value, "dateValue:", dateValue, "featureValue:", featureValue);
        }

        return featureValue;
    }

    //--------------------------------------------------------------------------

    function toFeatureData() {
        var table = schema.schema;
        var data = instance[table.name];

        var addFeatures = {};

        var feature = toFeature(table, data);

        addFeatures[table.tableId] = {
            features: [feature],
            attachments: [feature.attachments]
        };

        // delete feature.attachments;
        feature.attachments = undefined;

        addChildFeatures(addFeatures, table, feature);

        var edits = [];

        var keys = Object.keys(addFeatures);
        keys.forEach(function (key) {
            var adds = [];
            var updates = [];
            var deletes = [];

            addFeatures[key].features.forEach(function (feature) {
                var editMode = metaValue(feature, kMetaEditMode, kEditModeAdd);

                setMetaValue(feature, undefined);

                switch (editMode) {
                case kEditModeUpdate:
                    updates.push(feature);
                    break;

                case kEditModeDelete:
                    deletes.push(feature.globalid);
                    break;

                case kEditModeAdd:
                default:
                    adds.push(feature);
                    break;
                }
            });


            var edit = {
                "id": key,
                "attachments": addFeatures[key].attachments
            };

            if (adds.length) {
                edit.adds = adds;
            }

            if (updates.length) {
                edit.updates = updates;
            }

            if (deletes.length) {
                edit.deletes = deletes;
            }

            edits.push(edit);
        });

        console.log("edits:", JSON.stringify(edits, undefined, 2));

        return edits;
    }

    function addChildFeatures(addFeatures, table, parentFeature) {
        var relationshipKeyValue = AppFramework.createUuidString(0).toUpperCase();
        var childKeyField = "<" + table.tableName;

        table.relatedTables.forEach(function (relatedTable) {

            var parentKeyField = ">" + relatedTable.tableName;
            parentFeature.attributes[parentKeyField] = relationshipKeyValue;

            var esriParameters = relatedTable.esriParameters;
            var allowAdds = XFormJS.toBoolean(esriParameters.allowAdds, true);
            var allowUpdates = XFormJS.toBoolean(esriParameters.allowUpdates, false);
            var allowDeletes = XFormJS.toBoolean(esriParameters.allowDeletes, false);

            var rows = getTableRows(relatedTable.name);
            rows.forEach(function (row) {
                if (isEmpty(row)) {
                    console.log("Skipping empty child row");
                    return;
                }

                var feature = toFeature(relatedTable, row)
                var editMode = metaValue(row, kMetaEditMode, kEditModeAdd);

                if (!allowUpdates && editMode === kEditModeUpdate) {
                    console.log("Skipping edit child row");
                    return;
                }

                feature.attributes[childKeyField] = parentFeature.attributes[parentKeyField];

                if (!addFeatures[relatedTable.tableId]) {
                    addFeatures[relatedTable.tableId] = {
                        features: [],
                        attachments: []
                    };
                }

                addFeatures[relatedTable.tableId].features.push(feature);
                addFeatures[relatedTable.tableId].attachments.push(feature.attachments);

                // delete feature.attachments;
                feature.attachments = undefined;

                addChildFeatures(addFeatures, relatedTable, feature);
            });
        });
    }

    function isEmpty(o) {
        if (o === null) {
            return true;
        }

        var keys = Object.keys(o);
        for (var i = 0; i < keys.length; i++) {
            if (o[keys[i]] !== undefined) {
                return false;
            }
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function validate() {

        var table = schema.schema;
        if (!table) {
            return {
                message: "Null table"
            };
        }

        var data = instance[table.name];

        var error = validateData(table, data);

        if (!error) {
            error = checkCalculateConstraints();
        }

        if (!error) {
            error = checkControlConstraints();
        }

        return error;
    }

    //--------------------------------------------------------------------------

    function validateData(table, data) {

        var error = checkRequired(table, data);

        if (!error) {
            error = checkConstraints(table, data);
        }

        /*
        if (!error) {
            error = checkCalculateConstraints();
        }

        if (!error) {
            error = checkControlConstraints();
        }
        */

        if (!error) {
            for (var tableIndex = 0; tableIndex < table.relatedTables.length; tableIndex++) {
                var relatedTable = table.relatedTables[tableIndex];
                var rows = getTableRows(relatedTable.name);
                if (rows.length > 0) {
                    var relatedData = getTableRow(relatedTable.name); // From current row index
                    error = validateData(relatedTable, relatedData);
                    if (error) {
                        break;
                    }
                } else {
                    error = checkTableRequired(relatedTable);
                    if (error) {
                        break;
                    }
                }
            }
        }

        return error;
    }

    //--------------------------------------------------------------------------

    function checkTableRequired(table) {
        if (!table.required) {
            return;
        }

        var controlNode = controlNodes[table.nodeset];
        if (controlNode) {
            if (controlNode.group) {
                if (!controlNode.group.relevant) {
                    // console.log("checkTableRequired: !relevant ", table.name);
                    return;
                }
            }
        }

        //console.log("Required controlNode:", controlNode, "group:", controlNode.group, "label:", controlNode.group.labelControl);

        var label = table.name;

        if (controlNode && controlNode.group && controlNode.group.labelControl) {
            label = controlNode.group.labelControl.labelText;
        }

        return {
            "type": "required",
            "field": table.name,
            "nodeset": table.nodeset,
            "message": table.requiredMsg > "" ? textLookup(table.requiredMsg) : qsTr("<b>%1</b> is required.").arg(label)
        };
    }

    //--------------------------------------------------------------------------

    function checkRequired(table, data) {
        var controlNode;
        var requiredField;

        // console.log("checkRequired table:", table.name, "data:", JSON.stringify(data))


        for (var i = 0; i < table.fields.length; i++) {
            var field = table.fields[i];

            // console.log("checkRequired field:", field.name, "required:", field.required);

            if (!field.required) {
                continue;
            }

            controlNode = controlNodes[field.nodeset];
            if (controlNode) {
                if (controlNode.group) {
                    if (!controlNode.group.relevant) {
                        // console.log("checkRequired: !relevant ", field.name);
                        continue;
                    }
                }
            }

            if (!data) {
                requiredField = field;
                break;
            }

            var value = data[field.name];

            // console.log("checkRequired field:", field.name, "value:", value);

            if (XFormJS.isEmpty(value)) {
                requiredField = field;
                break;
            }
        }

        if (requiredField) {
            var label = field.label;

            if (controlNode && controlNode.group && controlNode.group.labelControl) {
                label = controlNode.group.labelControl.value;
            }

            if (!label) {
                label = qsTr("Field %1").arg(field.name);
            }

            return {
                "type": "required",
                "field": requiredField,
                "nodeset": requiredField.nodeset,
                "message": field.requiredMsg > "" ? textLookup(field.requiredMsg) : qsTr("<b>%1</b> is required.").arg(label)
            };
        }
    }

    //--------------------------------------------------------------------------

    function checkConstraints(table, data) {
        var constraintError;

        for (var i = 0; i < table.fields.length; i++) {
            var field = table.fields[i];

            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                continue;
            }

            if (controlNode.group) {
                if (!controlNode.group.relevant) {
                    // console.log("checkConstraints: !relevant ", field.name);
                    continue;
                }
            }

            if (!controlNode.control) {
                continue;
            }

            var control = controlNode.control;

            if (!control.constraint) {
                continue;
            }

            var value = data[field.name];
            if (XFormJS.isEmpty(value))
            {
                continue;
            }

            var constraint = control.constraint;

            console.log("Checking constraint for:", table.name, "field:", field.name, "value:", value, "constraint:", constraint);

            var error = constraint.validateError();

            if (error) {
                constraintError = error;
                break;
            }
        }


        return constraintError;
    }

    //--------------------------------------------------------------------------
    // Validate values not bound to a control
    // i.e. calculate

    function checkCalculateConstraints() {
        var constraintError;

        console.log("** checkCalculateContraints **");

        for (var i = 0; i < xform.calculateNodes.count; i++) {
            var calculate = xform.calculateNodes.get(i);

            if (!calculate.constraint) {
                continue;
            }

            constraintError = calculate.constraint.validateError();
            if (constraintError) {
                break;
            }
        }

        return constraintError;
    }

    //--------------------------------------------------------------------------
    // Validate controls not bound to a table field
    // i.e. note with auto generated name

    function checkControlConstraints() {
        console.log("checkControlConstraints");

        var constraintError;

        var nodesets = Object.keys(xform.controlNodes);

        for (var i = 0; i < nodesets.length; i++) {
            var nodeset = nodesets[i];

            var controlNode = xform.controlNodes[nodeset];

            if (!controlNode.control) {
                continue;
            }

            if (controlNode.group) {
                if (!controlNode.group.relevant) {
                    // console.log("checkControlConstraints: !relevant ", field.name);
                    continue;
                }
            }

            var control = controlNode.control;
            var error;

            if (control && control.validateInput) {
                error = control.validateInput();
                if (error) {
                    error.controlNode = controlNode;
                    constraintError = error;
                    break;
                }
            }

            if (!control.constraint || !control.relevant) {
                continue;
            }

            var field = xform.schema.fieldNodes[nodeset];
            if (field) {
                continue;
            }

            var constraint = control.constraint;

            error = constraint.validateError(control.value);
            if (error) {
                error.controlNode = controlNode;
                constraintError = error;
                break;
            }
        }

        return constraintError;
    }

    //--------------------------------------------------------------------------

    function snippet() {
        var table = schema.schema;

        var data = instance[table.name];

        if (!data) {
            data = {};
        }

        if (instanceNameBinding && typeof instanceNameBinding === "object") {
            var calculate = instanceNameBinding["@calculate"];
            if (calculate > "") {
                var expressionInstance = expressionsList.addExpression(calculate, instanceNameBinding["@nodeset"], "calculate");
                return expressionInstance.evaluate().toString();
            }
        }

        var values = JSON.parse(JSON.stringify(data));

        table.fields.forEach(function (field) {
            switch (field.type) {
            case "date":
                if (values[field.name]) {
                    values[field.name] = (new Date(values[field.name])).toLocaleDateString(locale, Locale.ShortFormat);
                }
                break;

            case "dateTime":
                if (values[field.name]) {
                    values[field.name] = Qt.formatDateTime(new Date(values[field.name]));
                }
                break;

            case "time":
                if (values[field.name]) {
                    values[field.name] = Qt.formatTime(new Date(values[field.name]));
                }
                break;
            }
        });

        // Fallback to old snippet expression

        if (snippetExpression > "") {
            return XFormJS.replacePlaceholders(snippetExpression, values);
        }

        var text;
        var keys = Object.keys(values);
        for (var i = 0, j = 0; j < 5 && i < keys.length; i++) {
            var key = keys[i];
            var value = values[key];

            if (value === null || value === undefined || typeof value === "object") {
                continue;
            }

            var keyValue = key + ":" + value.toString();
            if (text > "") {
                text += ", " + keyValue;
            } else {
                text = keyValue;
            }
            j++;
        }

        if (!(text > "")) {
            text = qsTr("<No data values>");
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function updateAutoGeometry(position, wkid) {
        if (!wkid) {
            wkid = defaultWkid;
        }

        var geometry = {
            x: position.coordinate.longitude,
            y: position.coordinate.latitude,
            spatialReference: {
                "wkid" : wkid
            }
        };

        var table = schema.schema;

        if (position.altitudeValid) {
            geometry.z = position.coordinate.altitude;
        }

        var updated = false;

        table.fields.forEach(function (field) {
            if (field.autoField &&
                    field.esriFieldType === "esriFieldTypeGeometry" &&
                    field.esriGeometryType === "esriGeometryPoint") {
                setFieldValue(field, geometry);
                updated = true;
            }
        });

        return updated;
    }

    //--------------------------------------------------------------------------

    function metaValue(data, name, defaultValue) {
        if (!data) {
            var table = schema.schema;
            if (!table) {
                console.warn("metaValue: Schema not ready");
                return defaultValue
            }

            data = getTableRow(table.name);
        }

        var metadata = data[kKeyMetadata] || {};

        if (!name) {
            return metadata;
        }

        if (metadata.hasOwnProperty(name)) {
            return metadata[name];
        } else {
            return defaultValue;
        }
    }

    //--------------------------------------------------------------------------

    function setMetaValue(data, name, value) {
        if (!data) {
            var table = schema.schema;
            data = getTableRow(table.name);
        }

        var metadata = data[kKeyMetadata] || {};

        if (!name) {
            if (value) {
                data[kKeyMetadata] = XFormJS.clone(value);
            } else {
                // delete data[kKeyMetadata];
                data[kKeyMetadata] = undefined;
            }

            return;
        }

        metadata[name] = value;

        data[kKeyMetadata] = metadata;
    }

    //--------------------------------------------------------------------------

    function toPrintObject(table, data) {
        if (!table) {
            table = schema.schema;
        }

        if (!data) {
            data = getTableRow(table.name);
        }

        if (!data) {
            data = {};
        }


        var printFields = [];

        for (var i = 0; i < table.fields.length; i++) {
            var field = table.fields[i];
            if (!field.print) {
                continue;
            }

            var printStyle = parsePrintStyle(field.printStyle);
            var printValue = printFormatValue(data[field.name], field, printStyle);

            if (printStyle.skipBlank && printValue === "") {
                continue;
            }

            var printField = {
                name: field.name,
                type: field.type,
                value: data[field.name],
                printLabel: field.label,
                printValue: printValue,
                printStyle: printStyle
            };

            printFields.push(printField);
        }

        var printObject = {
            title: xform.title,
            printFields: printFields
        }

        return printObject;
    }

    //--------------------------------------------------------------------------

    function parsePrintStyle(styleText) {
        if (!(styleText > "")) {
            return {};
        }

        var style = {};

        styleText.split(";").forEach(function (param) {
            var aKeyValue = param.split(":");
            if (aKeyValue.length < 2) {
                return;
            }

            var key = aKeyValue[0].trim();
            var value = aKeyValue[1].trim();

            if (key > "" && value > "") {
                style[key] = value;
            }
        });

        return style;
    }

    //--------------------------------------------------------------------------

    function printFormatValue(value, field, style) {
        if (XFormJS.isEmpty(value)) {
            return "";
        }

        switch (field.type) {
        case "date":
            value = Qt.formatDate(new Date(value), Qt.DefaultLocaleLongDate);
            break;

        case "dateTime":
            value = Qt.formatDateTime(new Date(value), Qt.DefaultLocaleLongDate);
            break;

        case "time":
            value = Qt.formatTime(new Date(value), Qt.DefaultLocaleLongDate);
            break;
        }

        return value;
    }

    //--------------------------------------------------------------------------
}
