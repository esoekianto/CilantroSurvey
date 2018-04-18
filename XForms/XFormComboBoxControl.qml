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
import QtQuick.Controls.Styles 1.2

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

ComboBox {
    id: comboBox

    property var binding
    property XFormData formData
    property var items
    property XFormItemset itemset
    property bool required: binding["@required"] === "true()"
    property var constraint
    readonly property bool relevant: parent.relevant

    anchors {
        left: parent.left
        right: parent.right
    }

    textRole: "text"

    model: itemsModel.model

    XFormItemsModel {
        id: itemsModel

        items: comboBox.items
        itemset: comboBox.itemset
        blankItem: !required

        onFilterChanged: {
            setValue(undefined);
        }
    }

    Component.onCompleted: {
        if (binding["@constraint"]) {
            constraint = formData.createConstraint(this, binding);
        }

        //        refreshModel();

        currentIndex = -1;
    }

    onActivated: {
        formData.setValue(binding, model.get(index).nameValue.value);
    }

    style: ComboBoxStyle {
        renderType:  Text.QtRendering
        textColor: xform.style.selectTextColor
        font {
            pointSize: xform.style.selectPointSize
            bold: xform.style.selectBold
            family: xform.style.selectFontFamily
        }
        selectedTextColor: xform.style.selectHighlightTextColor
        selectionColor: xform.style.selectHighlightColor
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {
        comboBox.currentIndex = -1;

        for (var i = 0; i < comboBox.model.count; i++) {
            var item = comboBox.model.get(i);
            if (item.nameValue.value == value) {
                comboBox.currentIndex = i;
                formData.setValue(binding, item.nameValue.value);
                break;
            }
        }

        if (comboBox.currentIndex < 0) {
            formData.setValue(binding, undefined);
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onLanguageChanged: {
            var index = comboBox.currentIndex;
            comboBox.currentIndex = -1;
            itemsModel.refreshText();
            comboBox.currentIndex = index;
        }
    }

    //--------------------------------------------------------------------------
}
