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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Rectangle {
    property var binding
    property XFormData formData

    property var constraint
    property var calculatedValue
    readonly property bool relevant: parent.relevant

    width: parent.width
    height: textArea.height
    color: xform.style.inputBackgroundColor

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant) {
            setValue(calculatedValue);
        }
    }

    //--------------------------------------------------------------------------

    TextArea {
        id: textArea

        property int maximumLength: 255
        property string previousText: text

        width: parent.width
        height: xform.style.multilineTextHeight

        readOnly: binding["@readonly"] === "true()"
        wrapMode: TextEdit.WordWrap
        textColor: xform.style.inputTextColor
        backgroundVisible: false

        font {
            pointSize: xform.style.inputPointSize
            bold: xform.style.inputBold
            family: xform.style.inputFontFamily
        }


        Component.onCompleted: {
            if (binding["@constraint"]) {
                constraint = formData.createConstraint(this, binding);
            }

            var fieldLength = 255;

            var esriProperty = binding["@esri:fieldLength"];
            if (esriProperty > "") {
                var n = Number(esriProperty);
                if (isFinite(n)) {
                    fieldLength = n;
                }
            }

            if (fieldLength > 0) {
                maximumLength = fieldLength;
            }
        }


        onActiveFocusChanged: {
            if (!activeFocus) {
                var value;
                var validate = false;

                if (text > "") {
                    validate = true;
                    value = text;
                }

                formData.setValue(binding, value);

                if (validate && constraint && relevant) {
                    constraint.validate();
                }
            }

            xform.controlFocusChanged(this, activeFocus, binding);
        }

        onLengthChanged: {
            if (length === 0) {
                formData.setValue(binding, undefined);
            }
        }

        onTextChanged: {
            if (text.length > maximumLength) {
                var cursor = cursorPosition;
                text = previousText;
                if (cursor > text.length) {
                    cursorPosition = text.length;
                } else {
                    cursorPosition = cursor - 1;
                }
            }
            previousText = text
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {
        textArea.text = XFormJS.isNullOrUndefined(value) ? "" : value.toString();
        formData.setValue(binding, value);
    }

    //--------------------------------------------------------------------------
}
