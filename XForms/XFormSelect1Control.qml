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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtMultimedia 5.0
import QtQuick.Controls.Private 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS


RowLayout {
    id: select1Control

    property var binding
    property XFormData formData
    property alias selectField: selectFieldLoader.item
    property alias radioGroup: radioGroup
    property alias value: radioGroup.value
    property alias valueLabel: radioGroup.text
    property alias valueValid: radioGroup.valid

    property bool required: binding["@required"] === "true()"
    readonly property bool isReadOnly: XFormJS.toBoolean(binding["@readonly"])
    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property bool relevant: parent.relevant
    //property alias columns: dropdownPanel.columns

    property var items
    property XFormItemset itemset
    property string appearance

    readonly property bool minimal: appearance == "minimal"
    readonly property real padding: 4 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    visible: parent.visible
    //spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (binding["@constraint"]) {
            constraint = formData.createConstraint(this, binding);
        }
    }

    onValueChanged: {
        //console.log("select1: onValueChanged:", changeReason)
        changeReason = 1;
        formData.setValue(binding, value);

        if (minimal && selectField) {
            selectField.dropdownVisible = false;
        }
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding && changeReason !== 1) {
            // console.log("select1: onCalculatedValueChanged:", calculatedValue);
            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    XFormRadioGroup {
        id: radioGroup

        required: select1Control.required
    }

    //--------------------------------------------------------------------------

    XFormItemsModel {
        items: select1Control.items
        itemset: select1Control.itemset

        onFilterChanged: {
            // console.log("Filterset changed for:", JSON.stringify(binding));
            select1Control.items = itemset.filteredItems;
            if (!xform.initializing) {
                setValue(undefined);
            }
        }
    }

    //--------------------------------------------------------------------------

    Column {
        Layout.fillWidth: true

        Loader {
            id: selectFieldLoader

            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: selectFieldComponent
            active: minimal
        }

        Loader {
            id: selectViewLoader

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: select1Control.padding * 3
            }

            sourceComponent: selectViewComponent
            active: selectField && minimal
            enabled: !isReadOnly
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

            sourceComponent: selectPanelComponent
            active: !minimal
            enabled: !isReadOnly
        }
    }

    Loader {
        id: calculateButtonLoader

        Layout.alignment: Qt.AlignTop
        //        Layout.preferredWidth: 32 * AppFramework.displayScaleFactor
        //        Layout.preferredHeight: 32 * AppFramework.displayScaleFactor

        sourceComponent: calculateButtonComponent
        active: false
        visible: !isReadOnly && changeReason === 1 && active
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectFieldComponent

        XFormSelectField {
            visible: minimal
            text: valueLabel
            valid: valueValid
            count: items ? items.length > 0 : 0
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectViewComponent

        XFormSelectListView {
            model: items
            radioGroup: select1Control.radioGroup

            visible: selectField.dropdownVisible
            padding: select1Control.padding
            color: selectField.color
            radius: selectField.radius
            border {
                width: selectField.border.width
                color: selectField.border.color
            }

            onVisibleChanged: {
                if (visible) {
                    xform.ensureItemVisible(this);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: selectPanelComponent

        XFormSelectPanel {
            id: selectPanel

            property var selectItems: select1Control.items

            Loader {
                id: likertBarLoader

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    leftMargin: (parent.width / columns) /2
                    rightMargin: (parent.width / columns) /2
                }

                z: parent.z - 1

                sourceComponent: likertBarComponent
                active: appearance === "likert"
                visible: active
            }

            Component {
                id: likertBarComponent

                Rectangle {
                    property int indicatorSize: Math.round(TextSingleton.implicitHeight)

                    height: 3 * AppFramework.displayScaleFactor
                    color: "#80020202"
                    radius: height / 2
                    y: indicatorSize / 2 - radius
                }
            }

            onSelectItemsChanged: {
                addControls();
            }

            function addControls() {
                controls = null;

                if (!Array.isArray(items)) {
                    return;
                }

                if (appearance === "likert") {
                    columns = Math.max(selectItems.length, 1);
                } else if (appearance === "minimal" || !(appearance > "")) {
                    columns = 1;
                }

                for (var i = 0; i < selectItems.length; i++) {
                    var item = selectItems[i];

                    radioControl.createObject(controlsGrid,
                                              {
                                                  width: controlsGrid.columnWidth,
                                                  binding: select1Control.binding,
                                                  radioGroup: select1Control.radioGroup,
                                                  label: item.label,
                                                  value: item.value,
                                                  appearance: select1Control.appearance
                                              });
                }
            }
        }
    }

    Component {
        id: radioControl

        XFormRadioControl {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculateButtonComponent

        ImageButton {
            implicitWidth: 32 * AppFramework.displayScaleFactor * xform.style.scale
            implicitHeight: 32 * AppFramework.displayScaleFactor * xform.style.scale

            source: "images/refresh_update.png"

            glowColor: "transparent"
            hoverColor: "transparent"
            pressedColor: "transparent"

            onClicked: {
                formData.expressionsList.triggerExpression(binding, "calculate");
                setValue(calculatedValue, 3);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        radioGroup.value = value;
        radioGroup.valid = true;

        if (XFormJS.isNullOrUndefined(value)) {
            radioGroup.label = undefined;
        } else {
            var matched = false;

            for (var i = 0; items && i < items.length; i++) {
                var item = items[i];
                if (item.value == value) {
                    radioGroup.label = item.label;
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                radioGroup.label = '<font color="grey">%1</font>'.arg(value);
                radioGroup.valid = false;
            }
        }

        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

    }

    //--------------------------------------------------------------------------
}

