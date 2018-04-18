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
        layoutDirection: xform.languageDirection

        XFormTextField {
            id: dateField

            Layout.fillWidth: true

            readOnly: true
            text: initialized ? XFormJS.formatDate(calendar.selectedDate, appearance, xform.locale) : ""
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
                } else {
                    dateField.forceActiveFocus();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && !control.readOnly) {
                    initialized = true;
                    formData.setValue(binding, clearTime(calendar.selectedDate).valueOf());
                    changeReason = 1;
                }

                xform.controlFocusChanged(control, activeFocus, binding);
            }

            MouseArea {
                anchors.fill: parent
                enabled: calendar.visible
                onClicked: calendar.forceActiveFocus();
            }
        }

        Loader {
            Layout.preferredWidth: dateField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth

            visible: !readOnly && dateField.length > 0

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
            Layout.preferredWidth: dateField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth

            active: typeof (calculatedValue) != "undefined" && !readOnly
            visible: !readOnly && changeReason === 1 && typeof (calculatedValue) != "undefined"

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
        weekNumbersVisible: appearance === "week-number" //true
        enabled: !readOnly

        onVisibleChanged: {
            if (visible) {
                xform.ensureItemVisible(this);
            }
        }

        onClicked: {
            forceActiveFocus();
            //xform.nextControl(this, true);
        }

        onDoubleClicked: {
            forceActiveFocus();
            xform.nextControl(this, true);
        }
    }

    //--------------------------------------------------------------------------

    function clearTime(date) {
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
        date.setMilliseconds(0);

        return date;
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
            formData.setValue(binding, undefined);
        } else {
            initialized = true;
            var date = clearTime(XFormJS.toDate(value));
            calendar.selectedDate = date;
            formData.setValue(binding, calendar.selectedDate.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
