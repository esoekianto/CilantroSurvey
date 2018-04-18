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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

ColumnLayout {
    id: control

    property var formElement
    property var binding
    property XFormData formData
    property bool readOnly: binding["@readonly"] === "true()"
    property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool relevant: parent.relevant
    property bool initialized: false
    property var calculatedValue
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    anchors {
        left: parent.left
        right: parent.right
    }

    spacing: 5 * AppFramework.displayScaleFactor

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
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: xform.languageDirection

        XFormTextField {
            id: timeField

            Layout.fillWidth: true

            readOnly: true
            text: initialized ? XFormJS.formatTime(timePicker.selectedDate, appearance, xform.locale) : ""
            placeholderText: qsTr("Time")
            actionEnabled: true
            actionIfReadOnly: true
            actionImage: timePicker.visible ? "images/arrow-up.png" : "images/arrow-down.png"
            actionVisible: !control.readOnly
            altTextColor: changeReason === 3
            horizontalAlignment: layoutDirection == Qt.RightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

            onAction: {
                if (timePicker.visible) {
                    timePicker.forceActiveFocus();
                } else {
                    timeField.forceActiveFocus();
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: timePicker.visible
                onClicked: timePicker.forceActiveFocus();
            }
        }

        Loader {
            Layout.preferredWidth: timeField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth
            visible: !readOnly && timeField.length > 0

            sourceComponent: ImageButton {
                source: "images/clear.png"
                glowColor: "transparent"
                hoverColor: "transparent"
                pressedColor: "transparent"

                onClicked: {
                    forceActiveFocus();
                    setValue(undefined, 1);
                }
            }
        }

        Loader {
            Layout.preferredWidth: timeField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth

            active: typeof (calculatedValue) != "undefined" && !readOnly
            visible: changeReason === 1 && typeof (calculatedValue) != "undefined"

            sourceComponent: ImageButton {
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
    }

    //--------------------------------------------------------------------------

    XFormTimePicker {
        id: timePicker

        Layout.fillWidth: true

        visible: timeField.activeFocus && !readOnly
        enabled: !readOnly
        maxColumnWidth: control.width / 3 * 0.8

        onVisibleChanged: {
            if (visible) {
                xform.ensureItemVisible(this);
            }
        }

        onSelectedDateChanged: {
            //console.log("onSelectedDateChanged:", selectedDate, isValid);
            initialized = isValid;
            formData.setValue(binding, selectedDate.valueOf());
            xform.controlFocusChanged(control, activeFocus, binding);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

        if (XFormJS.isEmpty(value)) {
            initialized = false;
            timePicker.clear();
            formData.setValue(binding, undefined);
        }
        else {
            initialized = true;
            var dateValue = XFormJS.toDate(value);
            dateValue.setSeconds(0);
            dateValue.setMilliseconds(0);
            timePicker.selectedDate = dateValue;
            formData.setValue(binding, timePicker.selectedDate.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
