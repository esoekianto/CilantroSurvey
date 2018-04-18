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

import "XForm.js" as XFormJS


Text {
    property var binding
    property XFormData formData
    property var constraint
    property var calculatedValue
    property var value: calculatedValue
    
    anchors {
        left: parent.left
        right: parent.right
    }

    visible: text > ""
    text: XFormJS.isEmpty(value) ? "" : value
    color: xform.style.valueColor
    font {
        pointSize: xform.style.valuePointSize
        bold: xform.style.valueBold
        family: xform.style.valueFontFamily
    }
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere

    Component.onCompleted: {
        if (!binding) {
            return;
        }
        
        var calculate = binding["@calculate"];
        if (calculate > "") {
            calculatedValue = formData.calculateBinding(binding);
        }

        if (binding["@constraint"]) {
            constraint = formData.createConstraint(this, binding);
        }
    }

    //--------------------------------------------------------------------------

    onLinkActivated: {
        Qt.openUrlExternally(link);
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (!binding) {
            return;
        }

        var nodeset = binding["@nodeset"];
        var field = schema.fieldNodes[nodeset];
        if (field) {
            setValue(calculatedValue);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {
        text = XFormJS.isEmpty(value) ? "" : value.toString();
        formData.setValue(binding, value);
    }

    //--------------------------------------------------------------------------
}
