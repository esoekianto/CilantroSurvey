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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Speech 1.0

import "XForm.js" as XFormJS

StackView {
    id: xform
    
    property url source
    property alias sourceInfo: sourceInfo
    property var json
    
    property bool reviewMode: false // New survey=false Existing survey=true
    
    property alias formData: formData
    property alias schema: schema
    property alias itemsets: itemsets
    
    property XFormPositionSourceManager positionSourceManager

    property alias spacing: controlsColumn.spacing
    
    property string defaultLanguage
    property string language: defaultLanguage
    property var languages: []
    property int languageDirection: languageText.textDirection
    property alias languageName: languageText.text
    property var locale: Qt.locale()
    
    readonly property string kLanguageDefault: "default"
    readonly property string kLanguageDefaultText: qsTr("Default")

    property string title
    property string instanceName
    property var instance
    property var instances
    property var submission: ({})
    property string version
    
    property bool initializing: false

    property int status: statusNull
    
    readonly property int statusNull: 0
    readonly property int statusLoading: 1
    readonly property int statusReady: 2
    readonly property int statusError: 3
    
    property StackView popoverStackView: xform
    
    readonly property alias name: sourceInfo.baseName
    
    property bool debug: false
    
    property Item focusItem
    
    property var controlNodes
    property alias calculateNodes: calculatesModel

    property XFormStyle style: XFormStyle {}
    property XFormMapSettings mapSettings: XFormMapSettings {}

    property alias attachmentsFolder: attachmentsFolder
    property int captureResolution: 640 // Medium
    property bool allowCaptureResolutionOverride: true

    readonly property alias canPrint: schema.canPrint

    property string layoutStyle
    property alias pageNavigator: pageNavigator
    property alias textToSpeech: textToSpeech
    property bool hasTTS: false
    property bool hasSaveIncomplete: false

    property bool extensionsEnabled: true

    property bool isRapidSubmit: false
    property bool rapidSubmitCancelled: false

    //--------------------------------------------------------------------------

    signal validationError(var error);
    signal closeAction();
    signal saveAction();

    signal controlFocusChanged(Item control, bool active, var binding);

    signal rapidSubmit()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        refresh();
    }

    //--------------------------------------------------------------------------

    onControlFocusChanged: {
        //console.log("onControlFocusChanged:", active, JSON.stringify(binding), control);

        if (active) {
            return;
        }

        if (xform.hasSaveIncomplete && !XFormJS.toBoolean(binding["@saveIncomplete"])) {
            return;
        }

        console.log("Focus change saveIncomplete:", JSON.stringify(binding), control);

        saveAction();
    }

    //--------------------------------------------------------------------------
    
    initialItem: ColumnLayout {
        property alias scrollView: xformView.scrollView

        XFormPageNavigator {
            id: pageNavigator

            Layout.fillWidth: true

            visible: false

            onPageActivated: {
                scrollView.ensureVisible(currentPage);
            }
        }

        Rectangle {
            id: xformView

            property alias scrollView: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            color: style.backgroundColor

            function closeAction() {
                xform.closeAction();
            }

            Image {
                anchors.fill: parent

                visible: style.backgroundImage > ""
                source: style.backgroundImage > "" ? sourceInfo.folder.fileUrl(style.backgroundImage) : ""
                fillMode: style.backgroundImageFillMode
            }

            ScrollView {
                id: scrollView

                anchors.fill: parent

                flickableItem.flickableDirection: Flickable.VerticalFlick

                //verticalScrollBarPolicy: Qt.ScrollBarAlwaysOn

                Column {
                    id: controlsColumn

                    readonly property bool relevant: true

                    width: xformView.width - 18 * AppFramework.displayScaleFactor

                    spacing: 5 * AppFramework.displayScaleFactor

                    //--------------------------------------------------------------
                    // Used to determine if language is right to left base on the language name text

                    TextInput {
                        id: languageText

                        property bool rightToLeft: isRightToLeft(0, length)
                        property int textDirection: rightToLeft ? Qt.RightToLeft : Qt.LeftToRight

                        text: language
                        readOnly: true
                        visible: false
                    }

                    //--------------------------------------------------------------
                }

                function ensureVisible(item) {
                    var mappedItem = item.mapToItem(contentItem, 0, 0);

                    if (debug) {
                        console.log("ensureVisible:", contentItem);
                        console.log("contentItem @", contentItem.width, contentItem.height);
                        console.log("flickableItem @", flickableItem, flickableItem.contentX, flickableItem.contentY, "w:", flickableItem.contentWidth, "h:", flickableItem.contentHeight);
                        console.log("mappedItem:", JSON.stringify(mappedItem, undefined, 2));
                    }

                    if (mappedItem.y < flickableItem.contentY || (mappedItem.y + item.height) >= (flickableItem.contentY + flickableItem.height)) {
                        flickableItem.contentY = mappedItem.y;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: sourceInfo
        url: source

        onPathChanged: {
            var folderName = sourceInfo.baseName + "-media";
            if (folder.fileExists(folderName)) {
                mediaFolder.path = folder.filePath(folderName);
            } else {
                mediaFolder.path = folder.filePath("media");
            }

            extensionsFolder.path = folder.filePath("extensions");
        }
    }

    FileFolder {
        id: mediaFolder
    }

    FileFolder {
        id: extensionsFolder
    }

    FileFolder {
        id: attachmentsFolder

        path: "~/ArcGIS/My Survey Attachments"

        Component.onCompleted: {
            makeFolder();
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: xform.positionSourceManager

        onNewPosition: {
            release();

            formData.updateAutoGeometry(position, wkid);
        }
    }

    //--------------------------------------------------------------------------

    XFormSchema {
        id: schema
    }
    
    XFormData {
        id: formData
        
        schema: schema
        defaultWkid: positionSourceConnection.wkid
        locale: xform.locale
    }

    XFormItemsets {
        id: itemsets

        dataFolder {
            path: mediaFolder.path
        }
    }

    XFormDataLists {
        id: dataLists

        dataFolder: mediaFolder
    }
    
    //--------------------------------------------------------------------------
    
    function refresh() {
        status = statusLoading;
        
        var xml = sourceInfo.folder.readTextFile(AppFramework.resolvedPath(source));

        json = AppFramework.xmlToJson(xml);
        //        console.log("Refreshing XForm", JSON.stringify(json, undefined, 2));
        
        if (debug) {
            var fn = AppFramework.resolvedPath(source).replace(".xml", ".json");
            sourceInfo.folder.writeJsonFile(fn, json);
        }


        refreshInfo();
        
        initializeLanguages();
        
        if (debug) {
            console.log("defaultLanguage", defaultLanguage);
        }
        
        title = json.head ? json.head.title : "";

        if (json.head && json.head.model && json.head.model.submission) {
            submission = json.head.model.submission;

            console.log("submission:", JSON.stringify(submission, undefined, 2));
        } else {
            submission = {};
        }

        instances = XFormJS.asArray(json.head.model.instance);
        
        if (debug) {
            console.log(instances.length, "instances:", JSON.stringify(instances, undefined, 2));
        }

        instance = instances[0];
        
        var elements = instance["#nodes"];
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].charAt(0) !== '#') {
                instanceName = elements[i];
                break;
            }
        }
        
        console.log("instanceName:", instanceName);
        
        instance = instances[0]; //json.head.model.instance[instanceName];

        version = (((instance || {} )[instanceName] || {})["@version"]) || "";

        console.log("version:", version);

        var instanceNameNodeset = "/" + instanceName + "/meta/instanceName";
        formData.instanceNameBinding = findBinding(instanceNameNodeset);

        layoutStyle = json.body["@class"] || "";

        console.log("layoutStyle:", layoutStyle);

        createControls(controlsColumn, json.body);
        addPaddingControl(controlsColumn);
        
        console.log("Media folder:", mediaFolder.exists, mediaFolder.path);
        console.log("Extensions folder:", extensionsFolder.exists, extensionsFolder.path);

        schema.update(json.head.model);

        bindCalculates();

        formData.expressionsList.enabled = true;

        if (reviewMode) {
            setDefaultValues(undefined, true);
        } else {
            preloadValues();
            setDefaultValues();
            updateCurrentPosition();
        }
        
        console.log("Updating expressions");
        formData.expressionsList.updateExpressions();

        status = statusReady;
    }


    function refreshInfo() {
        var formInfo = sourceInfo.folder.readJsonFile(sourceInfo.baseName + ".info");

        refreshDisplayInfo(formInfo.displayInfo);
        refreshImagesInfo(formInfo.imagesInfo);
    }

    function refreshDisplayInfo(displayInfo) {
        if (!displayInfo) {
            displayInfo = {};
        }

        console.log("refreshDisplayInfo", JSON.stringify(displayInfo, undefined, 2));

        if (displayInfo.snippetExpression > "") {
            formData.snippetExpression = displayInfo.snippetExpression;
        }

        refreshStyleInfo(displayInfo.style);
        mapSettings.refresh(sourceInfo.folder.path, displayInfo.map);
    }

    function refreshStyleInfo(styleInfo) {
        if (!styleInfo) {
            return;
        }

        if (styleInfo.textColor > "") {
            style.textColor = styleInfo.textColor;
        }

        if (styleInfo.backgroundColor > "") {
            style.backgroundColor = styleInfo.backgroundColor;
        }

        if (styleInfo.backgroundImage > "") {
            style.backgroundImage = styleInfo.backgroundImage;
        }

        if (styleInfo.toolbarBackgroundColor > "") {
            style.titleBackgroundColor = styleInfo.toolbarBackgroundColor;
        }

        if (styleInfo.toolbarTextColor > "") {
            style.titleTextColor = styleInfo.toolbarTextColor;
        }

        if (styleInfo.inputTextColor > "") {
            style.inputTextColor = styleInfo.inputTextColor;
        }

        if (styleInfo.inputBackgroundColor > "") {
            style.inputBackgroundColor = styleInfo.inputBackgroundColor;
        }
    }

    function refreshImagesInfo(imagesInfo) {
        if (typeof imagesInfo !== "object") {
            imagesInfo = {};
        }

        console.log("refreshImagesInfo", JSON.stringify(imagesInfo, undefined, 2));

        if (imagesInfo.hasOwnProperty("captureResolution")) {
            captureResolution = Number(imagesInfo.captureResolution);
        }

        if (imagesInfo.hasOwnProperty("allowCaptureResolutionOverride")) {
            allowCaptureResolutionOverride = Boolean(imagesInfo.allowCaptureResolutionOverride);
        }
    }

    function isNumber(value) {
        return isFinite(Number(value));
    }

    function isBool(value) {
        return typeof value === "boolean";
    }
    
    //--------------------------------------------------------------------------
    
    function bindCalculates(table) {
        if (!table) {
            table = schema.schema;
        }

        console.log("Binding calculates for:", table.name, table.nodeset);
        
        table.fields.forEach(function (field) {
            if (!(field.calculate > "")) {
                return;
            }
            
            var controlNode = controlNodes[field.nodeset];
            
            if (!controlNode) {
                console.log("Adding calculate element:", field.name);
                var calculateElement = calculateComponent.createObject(calculatesModel,
                                                                       {
                                                                           formData: formData,
                                                                           field: field
                                                                       });
                calculatesModel.append(calculateElement);
                return;
            }
            
            var control = controlNode.control;
            
            if (!control) {
                console.error("No control associated with calculate node", JSON.stringify(field, undefined, 2));
                return;
            }
            
            //console.log("Binding calculate:", field.name, "=", field.calculate, control);

            control.calculatedValue = formData.calculateBinding(field.binding);
        });

        table.relatedTables.forEach(function (relatedTable) {
            bindCalculates(relatedTable);
        });

    }

    ListModel {
        id: calculatesModel
    }

    Component {
        id: calculateComponent

        XFormCalculate {
        }
    }

    //--------------------------------------------------------------------------

    function finalize(table) {
        if (!table) {
            table = schema.schema;
        }

        if (!table) {
            return;
        }

        console.log("Finalizing values");

        table.fields.forEach(function (field) {
            var value;

            switch (field.preload) {
            case "timestamp":
                switch (field.preloadParams) {
                case "end":
                    value = (new Date()).valueOf();
                    break;
                }
                break;
            }

            var controlNode = controlNodes[field.nodeset];

            if (controlNode) {
                var control = controlNode.control;

                if (control && control.storeValue) {
                    value = control.storeValue();
                }
            }

            if (value) {
                formData.setValue(field.binding, value);
            }
        });
    }

    //--------------------------------------------------------------------------
    // https://opendatakit.org/help/form-design/examples/#Property_values
    
    function preloadValues(table) {
        if (!table) {
            table = schema.schema;
        }

        function uri(scheme, value) {
            return value > "" ? scheme + ":" + value : undefined;
        }
        
        table.fields.forEach(function (field) {
            var value;
            
            switch (field.preload) {
            case "date":
                switch (field.preloadParams) {
                case "today":
                    value = (new Date()).valueOf();
                    break;
                }
                break;
                
            case "timestamp":
                switch (field.preloadParams) {
                case "start":
                    value = (new Date()).valueOf();
                    break;
                    
                case "end":
                    value = (new Date()).valueOf();
                    break;
                }
                break;
                
            case "property":
                value = XFormJS.systemProperty(app, field.preloadParams);
                break;

            case "uid":
                value = AppFramework.createUuidString(2);
                break;
            }
            
            if (!XFormJS.isEmpty(value)) {
                formData.setValue(field.binding, value);
            }
        });
    }
    
    //--------------------------------------------------------------------------

    function setPosition(coordinate) {
        positionSourceManager.setPostion(coordinate);
    }

    //--------------------------------------------------------------------------

    function updateCurrentPosition() {
        if (!positionSourceConnection.valid) {
            console.warn("positionSource not valid");
            return;
        }

        positionSourceConnection.activate();
    }

    //--------------------------------------------------------------------------
    
    function setDefaultValues(table, defaultValuesOnly) {
        if (!table) {
            table = schema.schema;
        }
        
        table.fields.forEach(function (field) {
            var defaultValue = field.defaultValue;
            
            if (XFormJS.isEmpty(defaultValue)) {
                return;
            }
            
            var controlNode = controlNodes[field.nodeset];
            
            if (!controlNode) {
                if (defaultValuesOnly) {
                    return;
                }

                formData.setValue(field.binding, defaultValue);
                return;
            }
            
            var control = controlNode.control;
            
            if (!control) {
                console.error("No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (control.setDefaultValue) {
                control.setDefaultValue(defaultValue);
                return;
            }

            if (defaultValuesOnly) {
                return;
            }

            if (!control.setValue) {
                console.error("setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }
            
            // console.log("settingDefaultValue", defaultValue, "=>", JSON.stringify(field, undefined, 2));

            control.setValue(defaultValue);
        });
    }

    //--------------------------------------------------------------------------

    function initializeValues(values) {
        initializing = true;

        formData.instance = JSON.parse(JSON.stringify(values));

        var rootTable = xform.schema.schema;
        var rootValues = rowData[rootTable.name];

        setValues(undefined, rootValues, 2);
        triggerExpressions();
        formData.tableRowIndexChanged("", -1);

        initializing = false;
    }

    //--------------------------------------------------------------------------
    
    function setValues(table, values, mode) { // mode: 1=Don't skip empty values (paste), 2=only set if current value is empty
        if (!table) {
            table = schema.schema;
        }
        
        var metaData;
        if (values) {
            metaData = formData.metaValue(values, undefined);
        } else {
            var data = formData.getTableRow(table.name);
            metaData = formData.metaValue(data, undefined);
        }

        console.log("setValues:", table.name, "values:", JSON.stringify(values), "metaData:", JSON.stringify(metaData), "mode:", mode);

        table.fields.forEach(function (field) {
            var value = formData.valueByField(field, values);

            if (mode !== 2 && XFormJS.isEmpty(value)) {
                return;
            }

            if (mode === 1) {
                var currentValue = formData.valueByField(field);

                if (!XFormJS.isEmpty(currentValue)) {
                    return;
                }

                if (field.type === "binary") {
                    console.log("Skipping setValue:", field.name, "type:", field.type, "mode:", mode, "value:", currentValue);
                    return;
                }
            }
            
            var controlNode = controlNodes[field.nodeset];
            
            if (!controlNode) {
                formData.setValue(field.binding, value);
                return;
            }
            
            var control = controlNode.control;
            
            if (!control) {
                console.error("No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }
            
            if (!control.setValue) {
                console.error("setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }
            
            control.setValue(value, undefined, metaData);
        });
    }
    
    //--------------------------------------------------------------------------
    
    function pasteValues(values) {
        setValues(undefined, values, 1);
    }
    
    //--------------------------------------------------------------------------

    function resetValues(table) {
        if (!table) {
            table = schema.schema;
        }

        console.log("resetValues:", table.name);

        table.fields.forEach(function (field) {
            var controlNode = controlNodes[field.nodeset];

            if (!controlNode) {
                formData.setValue(field.binding, undefined);
                return;
            }

            var control = controlNode.control;

            if (!control) {
                console.error("No control associated with node", JSON.stringify(field, undefined, 2));
                return;
            }

            if (!control.setValue) {
                console.error("setValue missing for controlNode", JSON.stringify(field, undefined, 2));
                return;
            }

            control.setValue(undefined);
        });
    }

    //--------------------------------------------------------------------------

    function triggerExpressions(table, recursive) {
        if (!table) {
            table = schema.schema;
        }

        console.log("Triggering expressions for:", table.name, "nodeset:", table.nodeset);

        table.fields.forEach(function (field) {
            if (!(field.calculate > "")) {
                //console.log("No calculate for:", field.name);
                return;
            }

            if (field.binding["@esri:fieldType"] !== "null") {
                //console.log("Not a null field:", field.name, "binding:", JSON.stringify(field.binding));
                return;
            }

            //console.log("Triggering:", field.name, field.binding, field.calculate);
            formData.expressionsList.triggerExpression(field.binding, "calculate");
        });

        if (recursive) {
            table.relatedTables.forEach(function (relatedTable) {
                triggerExpressions(relatedTable, recursive);
            });
        }
    }

    //--------------------------------------------------------------------------
    
    function createControls(parentItem, parentNode, skipNodes) {
        if (!parentNode) {
            return;
        }
        
        var nodeNames = parentNode["#nodes"];
        
        for (var i = 0; i < nodeNames.length; i++) {
            var name = nodeNames[i];
            if (name.charAt(0) === '#') {
                console.log("Skip", name);
                continue;
            }
            
            var nodeName = XFormJS.nodeName(name);
            var nodeIndex = XFormJS.nodeIndex(name);
            
            if (skipNodes) {
                if (skipNodes.indexOf(nodeName) >= 0) {
                    continue;
                }
            }
            
            //console.log(nodeNames[i], "nodeName", nodeName, "nodeIndex", nodeIndex);
            var node;
            
            if (nodeIndex >= 0) {
                node = parentNode[nodeName][nodeIndex];
            } else {
                node = parentNode[nodeName];
            }
            
            var ref = node["@ref"];
            
            //console.log(i, "ref", ref);
            
            var binding = findBinding(ref);
            
            createControl(parentItem, nodeName, node, binding);
        }
    }
    
    //--------------------------------------------------------------------------
    
    function createControl(parentItem, type, formElement, binding) {
        if (binding && XFormJS.toBoolean(binding["@saveIncomplete"])) {
            hasSaveIncomplete = true;
        }

        switch (type) {
        case "group":
            createGroup(parentItem, formElement, binding);
            break;
            
        case "repeat":
            binding = findBinding(formElement["@nodeset"]);
            createRepeat(parentItem, formElement, binding);
            break;
            
        case "input":
            createInput(parentItem, formElement, binding);
            break;
            
        case "select1":
            createSelect1(parentItem, formElement, binding);
            break;
            
        case "select":
            createSelect(parentItem, formElement, binding);
            break;
            
        case "upload":
            createUpload(parentItem, formElement, binding);
            break;
            
        default:
            console.log("Unhandled control type:", type);
            control.createObject(parentItem, {"text": type });
            break;
        }
    }
    
    //--------------------------------------------------------------------------
    
    function addControlNode(binding, group, control, formElement) {
        if (!binding) {
            return;
        }
        
        if (!control) {
            return;
        }
        
        var nodeset = binding["@nodeset"];
        
        var controlNode = {
            group: group,
            control: control,
            formElement: formElement
        };
        
        console.log("addControlNode", nodeset, control);
        
        if (!controlNodes) {
            controlNodes = {};
        }
        
        controlNodes[nodeset] = controlNode;
    }
    
    //--------------------------------------------------------------------------

    function onSaveIncomplete() {
        console.log("onSaveIncomplete");
    }

    //--------------------------------------------------------------------------
    
    function createGroup(parentItem, formElement, binding) {
        var appearance = formElement["@appearance"];

        var required = binding && binding["@required"] === "true()"

        var fieldList = XFormJS.contains(appearance, "field-list");
        var isPage = fieldList && XFormJS.contains(layoutStyle, "pages");

        var group = collapsibleGroupBox.createObject(parentItem, {
                                                         isPage: isPage,
                                                         binding: binding,
                                                         formData: formData
                                                     });
        
        if (formElement.label) {
            group.labelControl = groupLabelControl.createObject(group.headerItems, {
                                                                    "label": formElement.label,
                                                                    "collapsible": !isPage,
                                                                    "collapsed": !isPage && XFormJS.contains(appearance, "compact"),
                                                                    "required": required
                                                                });
        }
        
        if (formElement.hint) {
            group.hintControl = createHint(group.contentItems, formElement, binding);
        }
        
        if (isPage) {
            pageNavigator.addPage(group);
        }

        createControls(group.contentItems, formElement, ["label"]);
    }
    
    //--------------------------------------------------------------------------
    
    function createRepeat(parentItem, formElement, binding) {
        var nodeset = formElement["@nodeset"];
        var appearance = formElement["@appearance"];

        schema.repeatNodesets.push(nodeset);

        var fieldList = XFormJS.contains(appearance, "field-list");
        var isPage = fieldList && XFormJS.contains(layoutStyle, "pages");
        var groupControl = parentItem.parent.parent.parent; // Hack to get to parent group control

        if (!isPage && XFormJS.contains(appearance, "compact")) {
            groupControl.collapse();
        }

        var repeat = repeatControl.createObject(parentItem, {
                                                    formElement: formElement,
                                                    nodeset: nodeset,
                                                    binding: binding,
                                                    formData: formData,
                                                    labelControl: parentItem.parent.parent.labelControl,
                                                    appearance: appearance
                                                });
        

        if (formElement.label) {
            groupLabelControl.createObject(repeat.contentItems, {
                                               "label": formElement.label
                                           });
        }
        
        if (formElement.hint) {
            createHint(repeat.contentItems, formElement, binding);
        }
        
        if (isPage) {
            groupControl.isPage = true;
            groupControl.collapse(false);
            var labelControl = groupControl.labelControl;
            if (labelControl) {
                labelControl.collapsible = false;
            }

            pageNavigator.addPage(groupControl);
        }

        addControlNode(binding, groupControl, repeat, formElement);
        createControls(repeat.contentItems, formElement, ["label"]);
    }
    
    //--------------------------------------------------------------------------
    
    function createHint(parentItem, formElement, binding) {
        var control = hintControl.createObject(parentItem, {
                                                   "hint": formElement.hint
                                               });

        return control;
    }
    
    //--------------------------------------------------------------------------

    function createControlGroup(parentItem, formElement, binding) {
        var group = groupBox.createObject(parentItem, {
                                              "flat": false,
                                              binding: binding,
                                              formData: formData
                                          });

        if (formElement.label) {
            group.labelControl = labelControl.createObject(group.contentItems, {
                                                               "label": formElement.label,
                                                               "required": binding && binding["@required"] === "true()"
                                                           });

        }

        if (formElement.hint) {
            group.hintControl = createHint(group.contentItems, formElement, binding);

            if (group.labelControl) {
                group.labelControl.ttsText = Qt.binding(function() {
                    return group.hintControl.hintText;
                });
            }
        }

        return group;
    }

    //--------------------------------------------------------------------------
    
    function createInput(parentItem, formElement, binding) {

        if (formElement["@query"] > "") { // select_one_external ?
            return createSelect1(parentItem, formElement, binding);
        }

        var group = createControlGroup(parentItem, formElement, binding);

        if (!binding) {
            console.warn("No binding for:", JSON.stringify(formElement));
            return;
        }
        
        var type = binding["@type"];
        var appearance = formElement["@appearance"];
        var control;
        
        switch (type) {
        case "date":
            switch (appearance) {
            case "month-year":
            case "year":
                control = monthYearControl.createObject(group.contentItems, {
                                                            formElement: formElement,
                                                            binding: binding,
                                                            formData: formData
                                                        });
                break;

            default:
                control = dateControl.createObject(group.contentItems, {
                                                       formElement: formElement,
                                                       binding: binding,
                                                       formData: formData
                                                   });
                break;
            }

            break

        case "dateTime":
            control = dateTimeControl.createObject(group.contentItems, {
                                                       formElement: formElement,
                                                       binding: binding,
                                                       formData: formData
                                                   });
            
            break

        case "time":
            control = timeControl.createObject(group.contentItems, {
                                                   formElement: formElement,
                                                   binding: binding,
                                                   formData: formData
                                               });

            break

        case "geopoint":
            control = geopointControl.createObject(group.contentItems, {
                                                       formElement: formElement,
                                                       binding: binding,
                                                       formData: formData
                                                   });
            break;
            
        case "geotrace":
            control = geopolyControl.createObject(group.contentItems, {
                                                      formElement: formElement,
                                                      binding: binding,
                                                      formData: formData
                                                  });
            break;

        case "geoshape":
            control = geopolyControl.createObject(group.contentItems, {
                                                      formElement: formElement,
                                                      binding: binding,
                                                      formData: formData,
                                                      polygon: true
                                                  });
            break;

        case "string":
            switch (appearance) {
            case "multiline":
                control = multiLineControl.createObject(group.contentItems, {
                                                            binding: binding,
                                                            formData: formData
                                                        });
                break;

            default:
                if (binding["@readonly"] === "true()") {
                    group.flat = true;
                    control = noteControl.createObject(group.contentItems, {
                                                           binding: binding,
                                                           formData: formData
                                                       });
                } else {
                    control = inputControl.createObject(group.contentItems, {
                                                            formElement: formElement,
                                                            binding: binding,
                                                            formData: formData
                                                        });
                }
                break;
            }
            break;
            
        case "int":
            switch (appearance) {
            case "distress":
                control = sliderControl.createObject(group.contentItems, {
                                                         formElement: formElement,
                                                         binding: binding,
                                                         formData: formData
                                                     });
                break;

            default:
                control = inputControl.createObject(group.contentItems, {
                                                        formElement: formElement,
                                                        binding: binding,
                                                        formData: formData
                                                    });
                break;
            }
            break;

        default:
            control = inputControl.createObject(group.contentItems, {
                                                    formElement: formElement,
                                                    binding: binding,
                                                    formData: formData
                                                });
            break;
        }
        
        addControlNode(binding, group, control, formElement);
    }
    
    //--------------------------------------------------------------------------

    function createSelect1(parentItem, formElement, binding) {
        var group = createControlGroup(parentItem, formElement, binding);

        var items = XFormJS.asArray(formElement.item);
        var appearance = formElement["@appearance"];
        var control;
        var itemset = null;

        if (formElement.itemset) {
            itemset = controlItemset.createObject(group, {
                                                      formData: formData,
                                                      itemset: formElement.itemset
                                                  });
        } else {
            var query = formElement["@query"];

            if (query > "") {
                var queryItemset = {
                    "external": true,
                    "@nodeset": query,
                    "value": {
                        "@ref": "name"
                    },
                    "label": {
                        "@ref": "jr:itext(label)"
                    }
                }

                itemset = controlItemset.createObject(group, {
                                                          formData: formData,
                                                          itemset: queryItemset
                                                      });
            }
        }

        var controlProperties = {
            binding: binding,
            formData: formData,
            items: items,
            itemset: itemset,
            appearance: appearance
        };

        switch (appearance) {
        case "autocomplete":
            control = select1ControlAuto.createObject(group.contentItems, controlProperties);
            break;
            
            /*
        case "minimal":
            control = comboBoxControl.createObject(group.contentItems, {
                                                       binding: binding,
                                                       formData: formData,
                                                       items: items,
                                                       itemset: itemset,
                                                       editable: false
                                                   });
            break;
*/
        default:
            control = select1Control.createObject(group.contentItems, controlProperties);
            break;
        }
        
        addControlNode(binding, group, control, formElement);
    }
    
    //--------------------------------------------------------------------------
    
    function createSelect(parentItem, formElement, binding) {
        var group = createControlGroup(parentItem, formElement, binding);

        var items = XFormJS.asArray(formElement.item);
        var appearance = formElement["@appearance"];
        
        var controlProperties = {
            binding: binding,
            formData: formData,
            items: items,
            appearance: appearance
        };

        if (appearance === "minimal" || !(appearance > "")) {
            controlProperties.columns = 1;
        }

        var control = selectControl.createObject(group.contentItems, controlProperties);

        addControlNode(binding, group, control, formElement);
    }
    
    //--------------------------------------------------------------------------
    
    function createUpload(parentItem, formElement, binding) {
        var group = createControlGroup(parentItem, formElement, binding);

        var mediatype = formElement["@mediatype"] || "*/*";
        var appearance = formElement["@appearance"];

        var type = mediatype.split('/')[0];

        console.log("mediatype:", mediatype, "type:", type, "appearance:", appearance);

        var control;

        switch (type) {
        case "image" :
            switch (appearance) {
            case "signature":
                control = signatureControl.createObject(group.contentItems, {
                                                            formElement: formElement,
                                                            binding: binding,
                                                            mediatype: mediatype,
                                                            formData: formData
                                                        });
                break;

            default:
                control = imageControl.createObject(group.contentItems, {
                                                        formElement: formElement,
                                                        binding: binding,
                                                        mediatype: mediatype,
                                                        formData: formData
                                                    });
                break;
            }
            break;

        case "audio" :
            control = audioControl.createObject(group.contentItems, {
                                                    formElement: formElement,
                                                    binding: binding,
                                                    mediatype: mediatype,
                                                    formData: formData
                                                });
            break;

        }

        if (control) {
            addControlNode(binding, group, control, formElement);
        }
    }
    
    //--------------------------------------------------------------------------

    function addPaddingControl(parentItem) {
        paddingControl.createObject(parentItem, {
                                    });
    }

    Component {
        id: paddingControl

        XFormPaddingControl {
        }
    }

    //--------------------------------------------------------------------------
    
    function findObject(ref) {
        var body = json.body;
        
        for (var propertyName in body) {
            if (body.hasOwnProperty(propertyName)) {
                
                var propertyValue = body[propertyName];
                
                if (propertyValue["@ref"] === ref) {
                    propertyValue["#tagName"] = propertyName;
                    
                    return propertyValue;
                } else if (propertyValue.length > 0) {
                    for (var i = 0; i < propertyValue.length; i++) {
                        if (propertyValue[i]["@ref"] === ref) {
                            propertyValue[i]["#tagName"] = propertyName;
                            
                            return propertyValue[i];
                        }
                    }
                }
            }
        }
        
        return null;
    }
    
    function findBinding(ref) {
        var bindArray = XFormJS.asArray(json.head.model.bind);
        
        for (var i = 0; i < bindArray.length; i++) {
            var bind = bindArray[i];
            
            if (bind["@nodeset"] === ref) {
                return bind;
            }
        }
        
        for (i = 0; i < bindArray.length; i++) {
            bind = bindArray[i];
            
            var nodeset = bind["@nodeset"];
            var j = nodeset.lastIndexOf("/");
            if (j >= 0) {
                nodeset = nodeset.substr(j + 1);
            }
            
            if (nodeset === ref) {
                return bind;
            }
        }
        
        return null;
    }

    function textLookup(object) {
        if (typeof object === 'string') {
            if (object.substr(0, 9) === 'jr:itext(') {
                return textValue({
                                     "@ref": object
                                 });
            } else {
                return object;
            }
        } else {
            return textValue(object);
        }
    }
    
    function textValue(object, defaultText, form, language) {
        if (!object) {
            return defaultText ? defaultText : "";
        }
        
        if (typeof object === 'string') {
            return object;
        }
        
        var ref = object["@ref"];
        if (ref) {
            var translation = findTranslation(textId(ref), language);
            if (translation) {
                var value = translation.value;
                
                if (typeof value === "string") {
                    return value;
                }
                
                var values = XFormJS.asArray(value);
                if (values.length > 0) {
                    for (var i = 0; i < values.length; i++) {
                        var v = values[i];
                        var vForm = v["@form"];
                        
                        // Skip media forms if no specifc form specified
                        
                        if (!form) {
                            switch (vForm) {
                            case "image":
                            case "audio":
                            case "video":
                                continue;
                            }
                        }
                        
                        if (!form || vForm === form) {
                            if (typeof v === "string") {
                                return v;
                            } else {
                                return v["#text"];
                            }
                        }
                    }
                    
                    for (i = 0; i < values.length; i++) {
                        v = values[i];
                        if (typeof v === "string") {
                            return v;
                        }
                    }
                    
                } else {
                    console.log("Translation value", JSON.stringify(value));
                    return value;
                }
            } else {
                console.log("No text for ", ref);
            }
        }
        
        if (object["#text"]) {
            return object["#text"];
        }
        
        // console.log("DefaultText", defaultText);
        
        return defaultText ? defaultText : "";
    }
    
    //--------------------------------------------------------------------------

    function mediaUrl(text) {
        if (text > "") {
            var urlInfo = AppFramework.urlInfo(text);
            if (urlInfo.scheme === "jr") {
                var fileName = urlInfo.fileName;

                if (fileName === "-") {
                    return fileName;
                } else if (fileName > "") {
                    if (mediaFolder.fileExists(fileName)) {
                        return mediaFolder.fileUrl(fileName);
                    }
                } else {
                    if (urlInfo.hasFragment && urlInfo.fragment === "tts") {
                        hasTTS = true;
                        return "tts://" + urlInfo.query;
                    }
                }
            }
        }

        return "";
    }
    
    function mediaValue(object, type) {
        var value = textValue(object, "", type);
        var url = mediaUrl(value);
        if (url === "-") {
            value = textValue(object, "", type, defaultLanguage);
            url = mediaUrl(value);
        }
        
        //console.log("mediaValue:", url, "value:", value);
        return url;
    }
    
    //--------------------------------------------------------------------------

    function findTranslation(id, language) {
        
        // console.log("findTransation", id);
        
        var translationSet = findTranslationSet(language);
        if (!translationSet) {
            return null;
        }
        
        var texts = XFormJS.asArray(translationSet.text);
        
        for (var t = 0; t < texts.length; t++) {
            var text = texts[t];
            
            if (text["@id"] === id) {
                return text;
            }
        }
        
        console.log("No translation for", id)
        
        return null;
    }
    
    function findTranslationSet(language) {
        var itext = json.head.model.itext;
        if (!itext) {
            return;
        }
        
        if (!language) {
            language = xform.language;
        }
        
        var translations = XFormJS.asArray(itext.translation);
        
        for (var i = 0; i < translations.length; i++) {
            var translation = translations[i];
            
            if (language > "") {
                if (translation["@lang"] !== language) {
                    continue;
                }
            }
            
            return translation;
        }
        
        console.log("No translation set found", language);
        
        return null;
    }
    
    //--------------------------------------------------------------------------

    function initializeLanguages() {
        if (!json.head || !json.head.model) {
            return;
        }

        var itext = json.head.model.itext;
        if (!itext) {
            return;
        }
        
        var translations = XFormJS.asArray(itext.translation);
        
        var list = [];
        for (var i = 0; i < translations.length; i++) {
            var translation = translations[i];
            
            var lang = translation["@lang"];
            list.push(lang);
            
            if (typeof translation["@default"] === "string") {
                defaultLanguage = lang;
            }
        }


        if (list.length > 0 && !(defaultLanguage > "")) {
            var appLocale = Qt.locale();

            // Match locale name

            for (i = 0; i < list.length; i++) {
                if (list[i].name > "") {
                    if (appLocale.name === Qt.locale(list[i]).name) {
                        defaultLanguage = list[i];
                        break;
                    }
                }
            }

            // Match language code

            if (XFormJS.isEmpty(defaultLanguage)) {
                var appLocaleInfo = AppFramework.localeInfo(appLocale.name);

                for (i = 0; i < list.length; i++) {
                    if (list[i].name > "") {
                        var locale = Qt.locale(list[i].name);
                        if (locale.name !== "C") {
                            var localeInfo = AppFramework.localeInfo(locale.name);
                            if (appLocaleInfo.languageCode === localeInfo.languageCode) {
                                defaultLanguage = list[i];
                                break;
                            }
                        }
                    }
                }
            }

            // Default to 1st language

            if (!(defaultLanguage > "")) {
                defaultLanguage = list[0];
            }
        }
        
        languages = list;

        console.log("defaultLanguage:", defaultLanguage, "languages:", JSON.stringify(languages, undefined, 2));
    }
    
    //--------------------------------------------------------------------------

    function enumerateLanguages(callback) {
        if (!Array.isArray(languages)) {
            return;
        }

        if (languages.length <= 1) {
            return;
        }

        for (var i = 0; i < languages.length; i++) {

            var language = languages[i];
            var languageText;
            var locale;

            if (language === xform.kLanguageDefault) {
                languageText = xform.kLanguageDefaultText;
            } else {
                locale = Qt.locale(language);

                if (locale.name === "C") {
                    languageText = language;
                    locale = Qt.locale();
                } else {
                    languageText = locale.nativeLanguageName > "" ? locale.nativeLanguageName : language;
                }
            }

            callback(language, languageText, locale);
        }
    }

    //--------------------------------------------------------------------------

    onLanguageChanged: {
        if (language == kLanguageDefault) {
            locale = Qt.locale();
            languageText.text = kLanguageDefaultText;
            languageDirection = locale.textDirection;
        } else {
            var loc = Qt.locale(language);

            if (loc.name === "C") {
                locale = Qt.locale();
                languageText.text = language;
                languageDirection = languageText.textDirection;
            } else {
                locale = loc;
                languageText.text = locale.nativeLanguageName > "" ? locale.nativeLanguageName : language;
                languageDirection = locale.textDirection;
            }
        }

        console.log("languageChanged:", language,
                    "languageName:", languageName,
                    "locale:", locale ? locale.name : "Undefined",
                                        "languageDirection:", languageDirection, languageDirection === Qt.RightToLeft ? "RTL": "LTR");

        if (hasTTS) {
            textToSpeech.say(language == kLanguageDefault
                             ? locale.nativeLanguageName
                             : languageText.text);
        }
    }

    //--------------------------------------------------------------------------

    function textId(ref) {
        var tokens = ref.match(/jr:itext\('(.*)'\)/);
        if (tokens && tokens.length > 1) {
            return tokens[1];
        } else {
            return ref;
        }

        /*
        var l = ref.indexOf("'");
        if (l < 0) {
            return ref;
        }

        var r = ref.lastIndexOf("'");
        return ref.substr(l + 1, r - l - 1);
        */
    }
    
    //--------------------------------------------------------------------------
    
    function ensureItemVisible(item) {
        if (!xform.currentItem.scrollView) {
            console.warn("ensureVisible: No scrollView for:", item);
            return;
        }
        
        xform.currentItem.scrollView.ensureVisible(item);
    }
    
    function setControlFocus(nodeset) {
        //console.log("setControlFocus", nodeset);
        
        var controlNode = controlNodes[nodeset];

        if (!controlNode) {
            console.error("setControlFocus: No control node for:", nodeset);
            return;
        }

        setControlNodeFocus(controlNode);
    }

    function setControlNodeFocus(controlNode) {
        ensureItemVisible(controlNode.group);

        var control = controlNode.control;

        if (control.forceActiveFocus) {
            control.forceActiveFocus();
        }
    }

    function nextControl(control, forward) {
        var item = control.nextItemInFocusChain(forward);
        if (!item) {
            return false;
        }

        xform.ensureItemVisible(item);

        if (item.forceActiveFocus) {
            item.forceActiveFocus();
        } else if (item.focus) {
            item.focus = true;
        }

        return true;
    }
    
    //--------------------------------------------------------------------------
    
    Component {
        id: groupBox

        XFormGroupControl {
        }
    }

    Component {
        id: collapsibleGroupBox

        XFormCollapsibleGroupControl {
        }
    }

    Component {
        id: groupLabelControl

        XFormGroupLabel {
        }
    }

    Component {
        id: labelControl
        
        XFormLabelControl {
        }
    }
    
    Component {
        id: hintControl
        
        XFormHintControl {
        }
    }
    
    Component {
        id: inputControl
        
        XFormInputControl {
            onFocusChanged: {
                if (focus) {
                    focusItem = this;
                }
            }
            onRapidSubmit: {
                xform.rapidSubmit();
            }
        }
    }
    
    Component {
        id: multiLineControl

        XFormMultiLineControl {
            onFocusChanged: {
                if (focus) {
                    focusItem = this;
                }
            }
        }
    }

    Component {
        id: dateControl
        
        XFormDateControl {
        }
    }
    
    Component {
        id: monthYearControl

        XFormMonthYearControl {
        }
    }

    Component {
        id: dateTimeControl

        XFormDateTimeControl {
        }
    }

    Component {
        id: timeControl

        XFormTimeControl {
        }
    }

    Component {
        id: geopointControl
        
        XFormGeopointControl {
            autoActivatePositionSource: !reviewMode
        }
    }
    
    Component {
        id: geopolyControl

        XFormGeopolyControl {
        }
    }

    /*
    Component {
        id: comboBoxControl
        
        XFormComboBoxControl {
        }
    }
    */
    
    Component {
        id: valuesPreview
        
        XFormMediaPreview {
        }
    }
    
    Component {
        id: selectControl

        XFormSelectControl {
        }
    }

    Component {
        id: select1Control

        XFormSelect1Control {
        }
    }

    Component {
        id: select1ControlAuto

        XFormSelect1ControlAuto {
        }
    }

    Component {
        id: imageControl
        
        XFormImageControl {
        }
    }

    Component {
        id: signatureControl

        XFormSignatureControl {
        }
    }
    
    Component {
        id: audioControl

        XFormAudioControl {
        }
    }

    Component {
        id: repeatControl
        
        XFormRepeatControl {
        }
    }
    
    Component {
        id: noteControl
        
        XFormNoteControl {
        }
    }

    Component {
        id: sliderControl

        XFormSliderControl {
        }
    }

    Component {
        id: controlItemset

        XFormItemset {
        }
    }
    
    Component {
        id: control
        
        Text {
            width: parent.width
        }
    }
    
    //--------------------------------------------------------------------------

    TextToSpeech {
        id: textToSpeech

        locale: xform.locale.name
    }

    //--------------------------------------------------------------------------
}
