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

import QtQuick 2.7
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtMultimedia 5.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

GroupBox {
    id: repeatControl

    property var formElement
    property var binding
    property XFormData formData
    property var label
    property var labelControl
    property alias contentItems: itemsColumn
    property int rowCount: 0
    property int currentRow: -1
    property bool newRow: false

    property string nodeset
    property string tableName: nodeset.split('/').pop();
    property var repeatCountRef
    property int repeatCount: -1
    property var repeatCountBinding
    property bool canAddDelete: !repeatCountRef

    property real buttonSize: 35 * AppFramework.displayScaleFactor
    property string appearance


    property var esriParameters: ({})
    property bool allowAdds: true
    property bool allowUpdates: true
    property bool allowDeletes: true

    property int currentEditMode: formData.kEditModeAdd

    readonly property bool newFormData: xform.formData.editMode == xform.formData.kEditModeAdd
    readonly property bool newCurrentData: currentEditMode == xform.formData.kEditModeAdd

    readonly property bool canAdd: newFormData || allowAdds
    readonly property bool canUpdate: newCurrentData || allowUpdates
    readonly property bool canDelete: newCurrentData || allowDeletes

    property bool relevant: parent.relevant

    property bool isMinimal: XFormJS.contains(appearance, "minimal")


    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    title: textValue(label) + (language ? "" : "")
    flat: true

    visible: canAddDelete || repeatCount > 0

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("repeatControl:", nodeset, "tableName:", tableName, "label:", label, "appearance:", appearance);

        if (formData && binding && binding["@relevant"]) {
            relevant = formData.relevantBinding(binding);
        }

        if (binding) {
            esriParameters = XFormJS.parseParameters(binding["@esri:parameters"]);
        }

        allowAdds = XFormJS.toBoolean(esriParameters.allowAdds, true);
        allowUpdates = XFormJS.toBoolean(esriParameters.allowUpdates, false);
        allowDeletes = false;//XFormJS.toBoolean(esriParameters.allowDeletes, false);

        console.log("allow adds:", allowAdds, "updates:", allowUpdates, "deletes:", allowDeletes);

        repeatCountRef = formElement["@jr:count"];
        if (repeatCountRef > "") {
            console.log("binding repeatCount to:", repeatCountRef);
                        //repeatCount = formData.numberBinding(repeatCountRef);
            repeatCountBinding = formData.numberBinding(repeatCountRef, "repeatCount");
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onStatusChanged: {
            if (xform.status === xform.statusReady) {
                if (!isMinimal && rowCount < 1) {
                    console.log("Adding initial repeat:", tableName);

                    //addRowButton.clicked();
                    addRow();
                    formData.setTableRowIndex(tableName, currentRow);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    onRepeatCountBindingChanged: {
        console.log("onRepeatCountBindingChanged:", repeatCountBinding);

        var rc;
        if (typeof repeatCountBinding === "number" && isFinite(repeatCountBinding) && repeatCountBinding >= 0) {
            rc = repeatCountBinding;
        } else {
            rc = 0;
        }

        if (rc < 1) {
            currentRow = -1;
        }

        repeatCount = rc;
    }

    onRepeatCountChanged: {
        console.log("onRepeatCountChanged:", repeatCount, "currentRow:", currentRow);

        formData.setTableRows(tableName, repeatCountBinding);

        if (repeatCount >= 0) {
            rowCount = repeatCount;
            if ((currentRow < 0 && rowCount > 0) || currentRow >= rowCount) {
                currentRow = 0;
            }
        } else {
            currentRow = -1;
        }
    }

    onCurrentRowChanged: {
        console.log("onCurrentRowChanged:", currentRow);
        formData.setTableRowIndex(tableName, currentRow);
    }

    Connections {
        target: formData

        onTableRowIndexChanged: {
            console.log("onTableRowIndexChanged:", tableName, "name:", JSON.stringify(name), "rowIndex:", rowIndex);

            if (name > "" && name !== tableName) {
                console.log("ignoring row change:", name, "!==", tableName, "#", rowIndex);
                return;
            }

            var table = xform.schema.tableNodes[tableName];

            if (rowIndex >= 0) {
                currentRow = rowIndex;
            } else {
                var rows = formData.getTableRows(tableName);
                console.log("rows:", JSON.stringify(rows, undefined, 2), "instance:", JSON.stringify(formData.instance, undefined, 2));


                rowCount = rows.length;
                currentRow  = rowCount > 0 ? 0 : -1;

                console.log("rowCount:", rowCount, "currentRow:", currentRow);
            }

            if (newRow) {
                console.log("New repeat:", tableName, "currentRow:", currentRow);

                xform.setValues(table, undefined, 2);
                xform.preloadValues(table);
                xform.setDefaultValues(table);
                //xform.setValues(table, undefined, 2);
                newRow = false;
            } else {
                var values = XFormJS.clone(formData.getTableRow(tableName, undefined, true));

                console.log("Edit repeat:", tableName, "currentRow:", currentRow, "values:", JSON.stringify(values));

                if (!(XFormJS.isNullOrUndefined(values) && isMinimal)) {
                    xform.setValues(table, values, 2);
                }
            }

            formData.expressionsList.enabled = true;
            formData.expressionsList.updateExpressions();

            var data = formData.getTableRow(tableName, undefined, isMinimal);

            currentEditMode = formData.metaValue(data || {}, formData.kMetaEditMode, formData.kEditModeAdd);

            console.log("currentEditMode:", currentEditMode);
        }
    }

    //--------------------------------------------------------------------------
    
    Column {
        width: parent.width
        spacing: 5 * AppFramework.displayScaleFactor

        RowLayout {
            visible: !canAddDelete
            width: parent.width
            spacing: 5 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/next.png"
                enabled: currentRow > 0 && rowCount > 0
                visible: enabled
                rotation: 180

                onClicked: {
                    forceActiveFocus();
                    gotoPreviousRow();
                }
            }

            Text {
                visible: rowCount > 0
                text: qsTr("%1 of %2").arg(currentRow + 1).arg(rowCount)
                color: xform.style.groupLabelColor
                font {
                    pointSize: xform.style.groupLabelPointSize * 0.75
                    family: xform.style.groupLabelFontFamily
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/next.png"
                enabled: currentRow < (rowCount - 1)
                visible: enabled

                onClicked: {
                    forceActiveFocus();
                    gotoNextRow();
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Column {
            id: itemsColumn

            readonly property alias relevant: repeatControl.relevant

            spacing: 5 * AppFramework.displayScaleFactor
            width: parent.width
            visible: rowCount > 0
            enabled: canUpdate
        }

        GroupBox {
            visible: canAddDelete
            width: parent.width

            RowLayout {
                width: parent.width
                spacing: 5 * AppFramework.displayScaleFactor

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/trash.png"
                    enabled: rowCount > 0 && canDelete
                    visible: enabled
                    color: "#b22222"

                    onClicked: {
                        forceActiveFocus();
                        confirmDeleteCurrentRow();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/next.png"
                    rotation: 180
                    enabled: rowCount > 0 && currentRow > 0
                    visible: enabled

                    onClicked: {
                        forceActiveFocus();
                        gotoPreviousRow();
                    }
                }

                Text {
                    visible: rowCount > 0
                    text: qsTr("%1 of %2").arg(currentRow + 1).arg(rowCount)
                    color: xform.style.groupLabelColor
                    font {
                        pointSize: xform.style.groupLabelPointSize * 0.75
                        family: xform.style.groupLabelFontFamily
                    }
                }

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/next.png"
                    enabled: rowCount > 0 && currentRow < (rowCount - 1)
                    visible: enabled

                    onClicked: {
                        forceActiveFocus();
                        gotoNextRow();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                XFormImageButton {
                    //id: addRowButton

                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/add.png"
                    enabled: canAdd
                    visible: enabled

                    onClicked: {
                        ensureItemVisible(repeatControl.parent.parent); // @TODO : Need to check parent chain
                        forceActiveFocus();
                        addRow();
                    }
                }
            }
        }
    }

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            fontFamily: xform.style.fontFamily
        }
    }

    //--------------------------------------------------------------------------

    function gotoPreviousRow() {
        if (validateCurrentRow()) {
            setCurrentRow(currentRow - 1);
        }
    }

    //--------------------------------------------------------------------------

    function gotoNextRow() {
        if (validateCurrentRow()) {
            setCurrentRow(currentRow + 1);
        }
    }

    //--------------------------------------------------------------------------

    function addRow() {
        console.log("adding row rowCount:", rowCount, "currentRow:", currentRow);
        if (rowCount > 0) {
            if (!validateCurrentRow()) {
                return;
            }
        }

        newRow = true;
        rowCount++;
        formData.getTableRow(tableName, rowCount - 1);
        setCurrentRow(rowCount - 1);
    }

    //--------------------------------------------------------------------------

    function validateCurrentRow() {
        var table = formData.schema.tableNodes[tableName];
        var data = formData.getTableRow(tableName);

        var error = formData.validateData(table, data);
        if (error) {
            xform.validationError(error);
            return false;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function setCurrentRow(rowIndex) {
        currentRow = rowIndex;
    }

    //--------------------------------------------------------------------------

    function confirmDeleteCurrentRow() {
        var label = labelControl ? labelControl.labelText.replace(/(<([^>]+)>)/ig, "") : "";

        var panel = confirmPanel.createObject(app, {
                                                  iconColor: "#a9d04d",
                                                  title: qsTr("Confirm Delete"),
                                                  text: label,
                                                  question: qsTr("Are you sure you want to delete %1 of %2?").arg(currentRow + 1).arg(rowCount)
                                              });

        panel.show(deleteCurrentRow, undefined);
    }

    function deleteCurrentRow() {

        console.log("row delete rowCount:", rowCount, "currentRow:", currentRow);

        if (!isMinimal && rowCount == 1) {
            console.log("Deleting last row in non-minimal repeat");
            isMinimal = true;
        }

        if (!formData.deleteTableRow(tableName, currentRow)) {
            console.log("deleteCurrentRow failed:", currentRow);

            if (currentRow === 0 && rowCount === 1 && !isMinimal) {
                console.log("deleteing initial row");
                rowCount = 0;
            }

            return;
        }

        rowCount--;

        if (rowCount === 0) {
            currentRow = -1;
        }

        console.log("row deleted rowCount:", rowCount, "currentRow:", currentRow);
    }

    //--------------------------------------------------------------------------
}
