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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtMultimedia 5.0
import QtQuick.Controls.Private 1.0

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS


Column {
    id: select1Control

    property var binding
    property XFormData formData
    property alias selectField: selectFieldLoader.item
    property alias radioGroup: radioGroup
    property alias value: radioGroup.value
    property alias valueLabel: radioGroup.text
    property bool fnedit: false;

    property bool required: binding["@required"] === "true()"
    readonly property bool isReadOnly: XFormJS.toBoolean(binding["@readonly"])
    property var constraint
    readonly property bool relevant: parent.relevant
    //property alias columns: dropdownPanel.columns

    property var items
    property var originalitems: []
    property XFormItemset itemset
    property string appearance


    readonly property bool autocomplete: appearance === "autocomplete"
    readonly property bool anyMatchFilter: true
    readonly property real padding: 4 * AppFramework.displayScaleFactor


    anchors {
        left: parent.left
        right: parent.right
    }

    visible: parent.visible
    //spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("All Items" + JSON.stringify(items));
        //console.log("Itemset: " + JSON.stringify(select1Control.itemset));
        if (binding["@constraint"]) {
            constraint = formData.createConstraint(this, binding);
        }

        if (select1Control.itemset) {
            console.log("HERE1 ITEMSET");
            originalitems = [];
        } else {
            console.log("HERE1 NO ITEMSET");
            originalitems = items;
        }
    }

    onValueChanged: {
        fnedit = true;
        formData.setValue(binding, value);

        if (autocomplete && selectField) {
            selectField.dropdownVisible = false;
        }
        if (value !== "") {
            for (var i=0; i<items.length; i++) {
                if (items[i].value === value && selectField) {
                    selectField.text = xform.textLookup(items[i].label);
                }
            }
        } else {
            selectField.text = "";
        }
        fnedit = false;
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
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
            originalitems = select1Control.itemset.filteredItems;
            items = refilter("");
            fnedit = false;
            console.log("FILTERCHANGED " + JSON.stringify(originalitems));
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
        active: autocomplete
        enabled: !isReadOnly
    }

    Loader {
        id: selectViewLoader

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: select1Control.padding * 3
        }

        sourceComponent: selectViewComponent
        active: selectField && autocomplete
        enabled: !isReadOnly
    }

    Component {
        id: selectFieldComponent

        XFormSelectFieldAuto {
            id: actualSelect
            visible: autocomplete
            text: valueLabel
            count: items ? items.length > 0 : 0
            originalCount: originalitems ? originalitems.length > 0 : 0

            onCountChanged: {
                console.log("count:", count, JSON.stringify(binding), JSON.stringify(items, undefined, 2))
            }

            onCleared: {
                setValue(undefined);//"");
            }
        }
    }

    Connections {
        target: selectField ? selectField.textField : null

        onTextChanged: {

            if (!fnedit) {
                selectField.dropdownVisible = true;
            } else {
                fnedit = false;
            }

            if (selectField.text.length < 1) {
                selectField.dropdownVisible = false;
            }

            items = refilter(selectField.text);

            //auto-select when 1 choice is left
            /*if (items.length === 1) {
                radioGroup.value = items[0].value;
                selectField.text = xform.textLookup(items[0].label);
            }*/
        }
    }

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
                if (visible && this !== undefined) {
                    xform.ensureItemVisible(this);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        anchors {
            left: parent.left
            right: parent.right
        }

        sourceComponent: selectPanelComponent
        active: !autocomplete
        enabled: !isReadOnly
    }

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
                } else if (appearance === "autocomplete" || !(appearance > "")) {
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

    function setValue(value) {
        //console.log('setvalue', value);

        items = originalitems;
        if (select1Control.itemset) {
            if (select1Control.itemset.filteredItems.length > 0) {
                items = select1Control.itemset.filteredItems;
            }
        }
        radioGroup.value = value;
        radioGroup.valid = true;

        if (XFormJS.isNullOrUndefined(value)) {
            radioGroup.label = undefined;
            if (selectField) {
                selectField.text = "";
            }
            //reset for repeats & item clears
            if (select1Control.constraint !== undefined) {
                items = select1Control.itemset.filteredItems;
            } else {
                items = select1Control.items;
            }
        } else {
            items = refilter(value);

//            if (items.length === 1) {
//                radioGroup.label = item.label;
//                selectField.text = item.label;
//                radioGroup.valid = false;
//            }
        }
    }


    function refilter(filterval) {

        var refilteredList = [];

        //console.log("Original items: " + JSON.stringify(originalitems));

        var itemLabel ="";
        var labelText = "";

        var itemsToFilter = originalitems;
        if (select1Control.itemset) {
            if (select1Control.itemset.filteredItems.length > 0) {
//              console.log('filtered list');
//              console.log(select1Control.itemset.filteredItems.length);
                itemsToFilter = select1Control.itemset.filteredItems;
            }
        }
//        } else {
////            console.log('not cascade');
////            console.log(originalitems.length);
//            itemsToFilter = originalitems;
//        }

        if (typeof itemsToFilter !== 'undefined') {
            for (var i = 0; i < itemsToFilter.length; i++) {
                itemLabel = itemsToFilter[i]["label"];
                labelText = (xform.textLookup(itemLabel)).toLowerCase();
//                console.log(labelText);

                var matchIndex = labelText.indexOf((filterval).toLowerCase());
                if (matchIndex == 0 || (anyMatchFilter && matchIndex > 0)) {
                    refilteredList.push(itemsToFilter[i]);
                }
            }
        }
//        console.log("Filtered items: " + JSON.stringify(refilteredList));

        return refilteredList;
    }

    //--------------------------------------------------------------------------
}
