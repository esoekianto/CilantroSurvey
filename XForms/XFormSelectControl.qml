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
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Column {
    id: selectControl

    property var label
    property var binding
    property XFormData formData
    property var items
    property var constraint
    property bool relevant: parent.relevant
    property alias columns: selectPanel.columns
    property alias controlsGrid: selectPanel.controlsGrid
    property string valuesLabel
    readonly property bool isReadOnly: XFormJS.toBoolean(binding["@readonly"])

    property string appearance

    readonly property bool minimal: appearance === "minimal"
    readonly property real padding: 4 * AppFramework.displayScaleFactor

    property alias checkControls: selectPanel.controls
    property alias selectField: selectFieldLoader.item

    property string valueSeparator: ","

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    Component.onCompleted: {
        if (binding["@constraint"]) {
            constraint = formData.createConstraint(this, binding);
        }

        addControls();
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: selectFieldLoader

        anchors {
            left: parent.left
            right: parent.right
        }

        sourceComponent: selectFieldComponent
        active: minimal
        enabled: !isReadOnly
    }

    Component {
        id: selectFieldComponent

        XFormSelectField {
            visible: minimal
            text: valuesLabel
        }
    }

    XFormSelectPanel {
        id: selectPanel

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: minimal ? padding * 3 : 0
        }

        enabled: !isReadOnly
        visible: !minimal || (selectField && selectField.dropdownVisible)
        padding: selectControl.padding
        radius : minimal ? selectField.radius : 0
        color: minimal ? selectField.color : "transparent"
        border {
            width: minimal ? selectField.border.width : 0
            color: minimal ? selectField.border.color : "transparent"
        }
    }

    Component {
        id: checkControl

        XFormCheckControl {
            checkBox {
                onCheckedChanged: {
                    checkValue(checkBox.checked, value);
                }
            }
        }
    }

    Connections {
        target: xform

        onLanguageChanged: {
            if (selectControl.minimal) {
                var values = formData.value(selectControl.binding);
                selectControl.valuesLabel = selectControl.createLabel(values);
            }
        }
    }

    //--------------------------------------------------------------------------

    function addControls() {
        if (!Array.isArray(items)) {
            return;
        }

        for (var i = 0; i < items.length; i++) {
            var item = items[i];

            checkControl.createObject(controlsGrid,
                                      {
                                          width: controlsGrid.columnWidth,
                                          binding: binding,
                                          formData: formData,
                                          label: item.label,
                                          value: item.value,
                                          appearance: appearance
                                      });
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {
        var values = valueToArray(value);

        // console.log("SelectControl setValue:", checkControls.length, "value:", JSON.stringify(value), "values:", JSON.stringify(values));

        for (var i = 0; i < checkControls.length; i++) {
            checkControls[i].setValue(values);
        }

        valuesLabel = createLabel(values);
    }

    //--------------------------------------------------------------------------

    function checkValue(checked, value) {
        var checkedValues = valueToArray(formData.value(binding));

        var valueIndex = checkedValues.indexOf(value);
        if (checked) {
            if (valueIndex < 0) {
                checkedValues.push(value);
            }
        } else {
            if (valueIndex >= 0) {
                // delete checkedValues[valueIndex];
                checkedValues[valueIndex] = undefined;
            }
        }

        var newValues = checkedValues.filter(function(element) {
            return !XFormJS.isNullOrUndefined(element) && element > "";
        });

        if (newValues.length == 0) {
            newValues = undefined;
        }

        valuesLabel = createLabel(newValues);

        //console.log("newValues:", JSON.stringify(newValues));

        formData.setValue(binding, newValues);
    }

    //--------------------------------------------------------------------------

    function valueToArray(values) {
        if (XFormJS.isNullOrUndefined(values)) {
            return [];
        }

        if (Array.isArray(values)) {
            return values;
        }

        return values.toString().split(valueSeparator).filter(function(value) {
            return !XFormJS.isNullOrUndefined(value) && value > "";
        });
    }

    //--------------------------------------------------------------------------

    function createLabel(values) {
        var label = "";

        if (!values) {
            return label;
        }

        for (var i = 0; i < checkControls.length; i++) {
            if (values.indexOf(checkControls[i].value) >= 0) {
                if (label > "") {
                    label += ",";
                }

                label += textValue(checkControls[i].label);
            }
        }

        return label;
    }

    //--------------------------------------------------------------------------
}
