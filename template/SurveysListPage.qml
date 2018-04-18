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
import QtQuick.LocalStorage 2.0
import QtQuick.Dialogs 1.2
import QtLocation 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../XForms"
import "../Controls"
import "../Models"
import "SurveyHelper.js" as Helper
import "../XForms/XForm.js" as XFormJS


Page {
    id: page

    property XFormsDatabase xformsDatabase: app.surveysModel
    property string surveyPath
    property alias surveyInfo: surveyInfo
    property string surveyTitle: surveyInfo.title
    property var surveyInfoPage
    property int statusFilter: -1
    property int statusFilter2: statusFilter

    //property alias listActionButton: listActionButton
    property Component listAction

    property bool showDelete: true

    property bool closeOnEmpty: true
    property string emptyMessage: qsTr("There are no surveys of this type")

    property alias schema: schema
    property alias mapSettings: mapSettings

    property bool refreshEnabled: false

    property color actionColor: "black"
    property alias tabView: tabView

    property Map map

    //--------------------------------------------------------------------------

    signal refresh()

    //--------------------------------------------------------------------------

    contentMargins: 0

    title: surveyTitle

    actionButton {
        visible: tabView.currentIndex === 1

        menu: Menu {
            id: pageMenu
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("SurveysListPage:", surveyPath);

        var xml = surveyInfo.folder.readTextFile(AppFramework.resolvedPath(surveyPath));
        var json = AppFramework.xmlToJson(xml);

        traverseControls(json.body, json.head.model, function(nodeName, node, binding) {
            //console.log("traversing:", nodeName, "binding:", JSON.stringify(binding));

            if (nodeName === "repeat") {
                schema.repeatNodesets.push(node["@nodeset"]);
            }
        });

        schema.update(json.head.model);
        mapSettings.refresh(surveyInfo.folder.path, surveyInfo.info.displayInfo ? surveyInfo.info.displayInfo.map : null);

        refreshList();
    }

    //--------------------------------------------------------------------------

    Stack.onStatusChanged: {
        if (Stack.status == Stack.Active) {
            refreshTimer.start();
        }
    }

    //--------------------------------------------------------------------------

    FilteredListModel {
        id: filteredSurveysModel

        readonly property string kPropertyDate: "updated"
        readonly property string kPropertyName: "snippet"

        sourceModel: xformsDatabase
        filterProperties: [kPropertyName]
        filterFunction: filterSurvey
        appendFunction: appendSurvey

        function filterSurvey(item, pattern) {
            if (defaultFilterFunction(item, pattern)) {
                return true;
            }

            if (dataSearch(item.data, pattern)) {
                return true;
            }
        }

        function appendSurvey(item, sourceIndex) {
            append({
                       sourceIndex: sourceIndex,
                       rowid: item.rowid,
                       updated: item.updated,
                       snippet: item.snippet,
                       status: item.status,
                       favorite: item.favorite
                   });
        }

        function getSurvey(index) {
            return sourceModel.get(get(index).sourceIndex);
        }

        function dataSearch(data, pattern) {
            if (!data) {
                return;
            }

            switch (typeof data) {
            case "string":
                return data.search(pattern) >= 0;

            case "object":
                break;

            case "number":
            case "boolean":
                return false;

            default:
                return data.toString().search(pattern) >= 0;
            }

            if (data instanceof Date) {
                return data.toString().search(pattern) >= 0;
            }

            if (Array.isArray(data)) {
                for (var i = 0; i < data.length; i++) {
                    if (dataSearch(data[i], pattern)) {
                        return true;
                    }
                }
            }

            var keys = Object.keys(data);
            for (i = 0; i < keys.length; i++) {
                if (dataSearch(data[keys[i]], pattern)) {
                    return true;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: refreshTimer

        interval: 10
        running: false
        repeat: false

        onTriggered: {
            refreshList();
        }
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo

        path: surveyPath
    }

    XFormSchema {
        id: schema

        debug: true
    }

    XFormMapSettings {
        id: mapSettings
    }

    //--------------------------------------------------------------------------

    contentItem: Item {

        Item {

            anchors.fill: parent

            AppTabView {
                id: tabView

                anchors {
                    fill: parent
                }

                frameVisible: false
                //tabsVisible: schema.schema.geometryField && !schema.schema.geometryField.autoField
                showTabs: schema.schema.geometryField && !schema.schema.geometryField.autoField
                tabsTextColor: actionColor
                tabsSelectedTextColor: "white"
                tabsBackgroundColor: "transparent"
                tabPosition: Qt.BottomEdge
                rightCorner: listAction

                Tab {
                    title: qsTr("List")

                    Item {
                        Text {
                            anchors.fill: parent
                            visible: !xformsDatabase.count

                            font {
                                pointSize: 24
                                family: app.fontFamily
                            }
                            color: textColor
                            text: emptyMessage
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        ColumnLayout {
                            anchors.fill: parent

                            visible: xformsDatabase.count > 0
                            spacing: 4 * AppFramework.displayScaleFactor

                            RowLayout {
                                id: toolsLayout

                                Layout.fillWidth: true
                                Layout.topMargin: 4 * AppFramework.displayScaleFactor
                                Layout.leftMargin: 4 * AppFramework.displayScaleFactor
                                Layout.rightMargin: Layout.leftMargin

                                visible: xformsDatabase.count > 1
                                spacing: 5 * AppFramework.displayScaleFactor

                                StyledImageButton {
                                    Layout.preferredHeight: searchField.height
                                    Layout.preferredWidth: Layout.preferredHeight

                                    checkable: true
                                    visible: xformsDatabase.hasDateValues
                                    checked: filteredSurveysModel.sourceModel.sortProperty === filteredSurveysModel.kPropertyDate
                                    checkedColor: page.headerBarColor

                                    source: "images/sort-time-" + filteredSurveysModel.sourceModel.sortOrder + ".png"

                                    onClicked: {
                                        if (checked) {
                                            filteredSurveysModel.sourceModel.toggleSortOrder();
                                        } else {
                                            filteredSurveysModel.sourceModel.sortProperty = filteredSurveysModel.kPropertyDate;
                                            filteredSurveysModel.sourceModel.sortOrder = filteredSurveysModel.kSortOrderDesc;
                                        }
                                        filteredSurveysModel.visualModel.sort();
                                    }
                                }

                                StyledImageButton {
                                    Layout.preferredHeight: searchField.height
                                    Layout.preferredWidth: Layout.preferredHeight

                                    checkable: true
                                    checked: filteredSurveysModel.sourceModel.sortProperty === filteredSurveysModel.kPropertyName
                                    checkedColor: page.headerBarColor

                                    source: "images/sort-text-" + filteredSurveysModel.sourceModel.sortOrder + ".png"

                                    onClicked: {
                                        if (checked) {
                                            filteredSurveysModel.sourceModel.toggleSortOrder();
                                        } else {
                                            filteredSurveysModel.sourceModel.sortProperty = filteredSurveysModel.kPropertyName;
                                            filteredSurveysModel.sourceModel.sortOrder = filteredSurveysModel.kSortOrderAsc;
                                        }
                                        filteredSurveysModel.visualModel.sort();
                                    }
                                }

                                SearchField {
                                    id: searchField

                                    Layout.fillWidth: true

                                    onEditingFinished: {
                                        filteredSurveysModel.filterText = text;
                                    }
                                }
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                SurveysListView {
                                    id: surveysListView
                                    showDelete: page.showDelete
                                    actionColor: page.actionColor

                                    onClicked: {
                                        surveyClicked(survey);
                                    }

                                    onPressAndHold: {
    //                                    if (tabView.tabsVisible) {
    //                                        tabView.currentIndex = 1;
    //                                    }
                                    }

                                    onDeleted: {
                                        if (xformsDatabase.count <= 0) {
                                            closePage();
                                        }
                                    }

                                    refreshHeader {
                                        enabled: refreshEnabled
                                        onRefresh: page.refresh();
                                    }
                                }
                            }
                        }
                    }
                }

                Tab {
                    title: qsTr("Map")
                    enabled: schema.schema.geometryField && !schema.schema.geometryField.autoField

                    SurveysMapView {
                        schema: page.schema
                        mapSettings: page.mapSettings

                        onClicked: {
                            surveyClicked(survey);
                        }

                        Component.onCompleted: {
                            page.map = map;
                            map.addMapTypeMenuItems(pageMenu);
                        }
                    }
                }
            }
        }

//        ConfirmButton {
//            id: listActionButton

//            anchors {
//                left: parent.left
//                right: parent.right
//                bottom: parent.bottom
//                margins: 5 * AppFramework.displayScaleFactor
//            }

//            text: ""
//            visible: text > ""
//        }

        ConfirmPanel {
            id: confirmPanel

            function showSurvey(survey, clone) {

                function edit() {
                    editSurvey(survey);
                }

                function editClone() {
                    editSurvey(survey, true);
                }

                if (clone) {
                    show(edit, editClone);
                } else {
                    show(edit);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function refreshList() {
        xformsDatabase.statusFilter = statusFilter;
        xformsDatabase.statusFilter2 = statusFilter2;
        xformsDatabase.refresh(surveyPath);

        if (xformsDatabase.count <= 0 && closeOnEmpty) {
            page.closePage();
        } else {
            xformsDatabase.sort();
            filteredSurveysModel.update();
        }
    }

    //--------------------------------------------------------------------------

    function surveyClicked(survey) {
        switch (survey.status) {
        case xformsDatabase.statusComplete:
            editComplete(survey);
            break;

        case xformsDatabase.statusSubmitted:
            editSubmitted(survey);
            break;

        case xformsDatabase.statusSubmitError:
            editSubmitError(survey);
            break;

        default:
            editSurvey(survey);
            break;
        }
    }

    //--------------------------------------------------------------------------

    function editSurvey(survey, clone) {
        var name = survey.name;
        var path = survey.path;
        var rowid = survey.rowid;
        var data = survey.data;

        var surveyPath = Helper.resolveSurveyPath(path, surveysFolder);

        if (!surveyPath) {
            confirmPanel.clear();
            confirmPanel.icon = "images/critical.png";
            confirmPanel.title = qsTr("Survey Load Error");
            confirmPanel.text = qsTr("Unable to load survey <b>%1</b>").arg(name);
            confirmPanel.button1Text = qsTr("Ok");
            confirmPanel.button2Text = "";

            confirmPanel.show();

            return;
        }


        function stripMetaData(o) {
            if (!o) {
                return;
            }

            var keys = Object.keys(o);
            for (var i = 0; i < keys.length; i++) {
                var key = keys[i];
                if (key === "__meta__") { // kKeyMetadata
                    var metaData = o[key];
                    var metaKey = metaData["globalIdField"]; // kMetaGlobalIdField
                    if (metaKey) {
                        console.log("Remove data value:", metaKey, "=", o[metaKey]);
                        o[metaKey] = undefined;
                    }

                    metaKey = metaData["objectIdField"]; // kMetaObjectIdField
                    if (metaKey) {
                        console.log("Remove data value:", metaKey, "=", o[metaKey]);
                        o[metaKey] = undefined;
                    }

                    o[key] = undefined;
                    break;
                }

                var value = o[key];
                if (typeof value === "object") {
                    stripMetaData(value);
                }
            }
        }

        function clearFields(table, tableData) {
            console.log("Clearing:", table.name);

            for (var i = 0; i < table.fields.length; i++) {
                var field = table.fields[i];

                switch (field.type) {
                case "binary":
                    console.log("Clearing field:", field.name, "type:", field.type);
                    tableData[field.name] = undefined;
                    break;
                }
            }

            table.relatedTables.forEach(function (relatedTable) {
                var rows = tableData[table.name];
                if (Array.isArray(rows)) {
                    console.log("Clearing relatedTable:", relatedTable.name, "#rows:", rows.length);
                    rows.forEach(function (rowData) {
                        clearFields(relatedTable, rowData);
                    });
                }
            });
        }

        if (clone) {
            rowid = -1;
            console.log("Removing meta and instance unique data from copy");
            stripMetaData(data);
            clearFields(schema.schema, data[schema.schema.name]);
        }

        console.log("editSurvey:", surveyPath, "rowid:", rowid, "name:", name, "path:", path, "data:", JSON.stringify(data, undefined, 2));

        page.Stack.view.push({
                                 item: surveyView,
                                 properties: {
                                     surveyPath: surveyPath,
                                     surveyInfoPage: surveyInfoPage,
                                     rowid: rowid,
                                     rowData: data,
                                     isCurrentFavorite: survey.favorite > 0
                                 }
                             });
    }

    //--------------------------------------------------------------------------

    function editComplete(survey) {
        confirmPanel.clear();
        confirmPanel.icon = "images/warning.png";
        confirmPanel.title = qsTr("Completed Survey");
        confirmPanel.text = qsTr("This survey has already been completed.");
        confirmPanel.question = qsTr("Do you want to continue and edit this survey?");

        confirmPanel.showSurvey(survey);
    }

    //--------------------------------------------------------------------------

    function editSubmitted(survey) {
        confirmPanel.clear();
        confirmPanel.icon = "images/question.png";
        confirmPanel.title = qsTr("Sent Survey");
        confirmPanel.text = qsTr("This survey has already been sent.");
        confirmPanel.question = qsTr("What would you like to do?");
        confirmPanel.button1Text = qsTr("<b>Edit</b> and resend survey");
        confirmPanel.button2Text = qsTr("<b>Copy</b> the sent data to a new survey");
        confirmPanel.verticalLayout = true;

        confirmPanel.showSurvey(survey, true);
    }

    //--------------------------------------------------------------------------

    function editSubmitError(survey) {
        var error = JSON.parse(survey.statusText);

        if (Array.isArray(error)) {
            error = error[0];
        }

        console.log("error:", JSON.stringify(error, undefined, 2));

        var detailedText = "";

        if (error.details) {
            error.details.forEach(function (detail) {
                if (detailedText > "") {
                    detailedText += "\r\n";
                }

                detailedText += detail;
            });
        }

        var message = "";

        if (error.message) {
            message = error.message;
        } else if (error.description) {
            message = error.description;
        }

        //var informativeText = "Code " + error.code.toString() + "\r\n" + message;

        var informativeText = message

        if (Array.isArray(error.adds)) {
            error.adds.forEach(function(add) {
                if (add.result.error){
                    informativeText += "\r\nAdd error code %1 - %2".arg(add.result.error.code).arg(add.result.error.description);
                }
            });
        }

        if (Array.isArray(error.updates)) {
            error.updates.forEach(function(update) {
                if (update.result.error) {
                    informativeText += "\r\nUpdate error code %1 - %2".arg(update.result.error.code).arg(update.result.error.description);
                }
            });
        }

        confirmPanel.clear();
        confirmPanel.icon = "images/cloud-error.png";
        confirmPanel.title = qsTr("Send Error");
        confirmPanel.text = qsTr("This survey was not able to be sent due to the following error:");
        confirmPanel.informativeText = informativeText;
        //        confirmPanel.detailedText = detailedText;
        confirmPanel.question = qsTr("Do you want to edit this survey?");

        confirmPanel.showSurvey(survey);
    }

    //--------------------------------------------------------------------------

    function traverseControls(parentNode, model, callback, skipNodes) {
        if (!parentNode) {
            return;
        }

        function findBinding(ref) {
            var bindArray = XFormJS.asArray(model.bind);

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

            callback(nodeName, node, binding);

            switch (nodeName) {
            case "group":
            case "repeat":
                traverseControls(node, model, callback, ["label"]);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------
}
