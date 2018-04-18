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
    property bool initialized: false
    property var appearance: formElement ? formElement["@appearance"] : null
    property var constraint
    property var calculatedValue

    property var dateTimeValue: null
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    readonly property bool relevant: parent.relevant

    anchors {
        left: parent.left
        right: parent.right
    }

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (binding["@constraint"]) {
            constraint = formData.createConstraint(this, binding);
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
            //console.log("onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            setValue(calculatedValue, 3);
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: xform.languageDirection

        XFormTextField {
            id: dateField

            Layout.fillWidth: true

            readOnly: true
            text: ""
            placeholderText: qsTr("Date")
            actionEnabled: true
            actionIfReadOnly: true
            actionImage: calendar.visible ? "images/arrow-up.png" : "images/arrow-down.png"
            actionVisible: !control.readOnly
            altTextColor: changeReason === 3
            horizontalAlignment: layoutDirection == Qt.RightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

            onAction: {
                if (calendar.visible) {
                    calendar.forceActiveFocus();
                }
                else {
                    dateField.forceActiveFocus();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && dateTimeValue && !control.readOnly) {
                    formData.setValue(binding, dateTimeValue.valueOf());
                    changeReason = 1;
                    setControlText();
                }
                xform.controlFocusChanged(control, activeFocus, binding);
            }

            MouseArea {
                anchors.fill: parent
                enabled: calendar.visible
                onClicked: calendar.forceActiveFocus();
            }
        }

        XFormTextField {
            id: timeField

            Layout.preferredWidth: parent.width/3

            readOnly: true
            text: ""
            placeholderText: qsTr("Time")
            actionEnabled: true
            actionIfReadOnly: true
            actionImage: timePicker.visible ? "images/arrow-up.png" : "images/arrow-down.png"
            actionVisible: true
            altTextColor: changeReason === 3
            horizontalAlignment: layoutDirection == Qt.RightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

            onAction: {
                if (timePicker.visible) {
                    timePicker.forceActiveFocus();
                }
                else {
                    timeField.forceActiveFocus();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && dateTimeValue) {
                    formData.setValue(binding, dateTimeValue.valueOf());
                    changeReason = 1;
                    setControlText();
                }

                xform.controlFocusChanged(control, activeFocus, binding);
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
            visible: !readOnly && dateTimeValue != null

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

    XFormCalendar {
        id: calendar

        Layout.fillWidth: true

        visible: dateField.activeFocus && !readOnly
        weekNumbersVisible: false
        enabled: !readOnly

        onClicked: {
            forceActiveFocus();
        }

        onVisibleChanged: {
            if (visible) {
                xform.ensureItemVisible(this);
                if (!dateTimeValue) {
                    initialized = true;
                    dateTimeValue = new Date();
                }
                else {
                    selectedDate = dateTimeValue;
                }
            }
        }

        onSelectedDateChanged: {
            if (!dateTimeValue || (dateTimeValue && selectedDate.valueOf() !== dateTimeValue.valueOf())) {
                var date = dateTimeValue ? new Date(dateTimeValue.valueOf()) : new Date();

                date.setFullYear(selectedDate.getFullYear());
                date.setMonth(selectedDate.getMonth());
                date.setDate(selectedDate.getDate());
                clearSeconds(date);

                dateTimeValue = date;
                formData.setValue(binding, date.valueOf());
                xform.controlFocusChanged(control, activeFocus, binding);
            }
        }
    }

    XFormTimePicker {
        id: timePicker

        Layout.fillWidth: true

        visible: timeField.activeFocus && !readOnly
        enabled: !readOnly

        onVisibleChanged: {
            if (visible) {
                xform.ensureItemVisible(this);
                if (!dateTimeValue) {
                    initialized = true;
                    dateTimeValue = new Date();
                }
                else {
                    selectedDate = dateTimeValue;
                }
            }
        }

        onSelectedDateChanged: {
            if (!dateTimeValue || (dateTimeValue && selectedDate.valueOf() !== dateTimeValue.valueOf())) {
                var date = dateTimeValue ? new Date(dateTimeValue.valueOf()) : new Date();

                date.setHours(selectedDate.getHours());
                date.setMinutes(selectedDate.getMinutes());
                clearSeconds(date);

                timeField.text = XFormJS.formatTime(date, appearance, xform.locale);

                dateTimeValue = date;
                formData.setValue(binding, date.valueOf());
                xform.controlFocusChanged(control, activeFocus, binding);
            }
        }
    }

    //--------------------------------------------------------------------------

    function clearSeconds(date) {
        date.setSeconds(0);
        date.setMilliseconds(0);
        return date;
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {

        if (reason) {
            changeReason = reason;
        }
        else {
            changeReason = 2;
        }

        if (XFormJS.isEmpty(value)) {
            resetControl();
            formData.setValue(binding, undefined);
        }
        else {
            dateTimeValue = clearSeconds(XFormJS.toDate(value));
            setControlText();
            formData.setValue(binding, dateTimeValue.valueOf());
        }
    }

    //--------------------------------------------------------------------------

    function resetControl(){
        calendar.selectedDate = new Date();
        timePicker.selectedDate = new Date();
        dateTimeValue = null;
        initialized = false;
        setControlText();
    }

    //--------------------------------------------------------------------------

    function setControlText() {
        dateField.text = dateTimeValue ? XFormJS.formatDate(dateTimeValue, appearance, xform.locale) : "";
        timeField.text = dateTimeValue ? XFormJS.formatTime(dateTimeValue, appearance, xform.locale) : "";
    }

    //--------------------------------------------------------------------------
}
