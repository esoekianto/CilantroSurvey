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
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

Rectangle {
    id: control

    property var formElement
    property var binding
    property XFormData formData
    property bool readOnly: binding["@readonly"] === "true()"
    property var appearance: formElement ? formElement["@appearance"] : null;
    property bool monthYear: appearance !== "year"
    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    readonly property bool relevant: parent.relevant

    property date dateValue: new Date()
    property int dateMonth
    property int dateYear
    readonly property int monthRepeatInterval: 100
    readonly property int yearRepeatInterval: 50


    property int barHeight: Math.round(TextSingleton.implicitHeight * 1.1) + padding * 2
    property int barTextSize: TextSingleton.implicitHeight
    property var locale: Qt.locale()
    property int padding: 2 // * AppFramework.displayScaleFactor
    property color gridColor: "#ccc"

    anchors {
        left: parent.left
        right: parent.right
    }

    border {
        color: xform.style.inputBorderColor
        width: 1
    }

    height: valueLayout.height + padding * 2
    radius: 4 * AppFramework.displayScaleFactor
    color: xform.style.inputBackgroundColor

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

    onDateValueChanged: {
        dateMonth = dateValue.getMonth();
        dateYear = dateValue.getFullYear();
        formData.setValue(binding, dateValue.valueOf());
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: valueLayout

        property int sectionHeight: barHeight * Math.max(1, xform.style.textScaleFactor * 0.8)
        property int textHeight: sectionHeight * 0.8
        property int buttonWidth: sectionHeight * 1.35

        anchors {
            left: parent.left
            right: parent.right
            margins: padding
            verticalCenter: parent.verticalCenter
        }

        enabled: !readOnly
        spacing: padding * 3

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 0//padding * 3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: valueLayout.sectionHeight

                visible: monthYear

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: valueLayout.buttonWidth

                    source: "images/arrow-left.png"
                    repeatInterval: monthRepeatInterval

                    onClicked: updateMonth(-1)
                    onRepeat: updateMonth(-1)
                }

                Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    text: control.locale.standaloneMonthName(dateMonth)
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: changeReason === 3 ? "darkblue" : "#444"
                    font {
                        pixelSize: valueLayout.textHeight
                        family: xform.style.inputFontFamily
                    }
                }

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: valueLayout.buttonWidth

                    source: "images/arrow-right.png"
                    repeatInterval: monthRepeatInterval

                    onClicked: updateMonth(1)
                    onRepeat: updateMonth(1)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1

                visible: monthYear
                color: gridColor
            }

            //--------------------------------------------------------------------------

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: valueLayout.sectionHeight

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: valueLayout.buttonWidth

                    source: "images/arrow-left.png"
                    repeatInterval: yearRepeatInterval

                    onClicked: updateYear(-1)
                    onRepeat: updateYear(-1)
                }

                Label {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    text: dateYear
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: changeReason === 3 ? "darkblue" : "#444"
                    font {
                        pixelSize: valueLayout.textHeight
                        family: xform.style.inputFontFamily
                    }
                }

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: valueLayout.buttonWidth

                    source: "images/arrow-right.png"
                    repeatInterval: yearRepeatInterval

                    onClicked: updateYear(1)
                    onRepeat: updateYear(1)
                }
            }
        }

        Loader {
            Layout.preferredHeight: barHeight
            Layout.preferredWidth: Layout.preferredHeight

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

    function updateMonth(offset) {
        var date = new Date(dateValue.valueOf());
        date.setMonth((date.getMonth() + offset) % 12);
        clearDate(date);
        dateValue = date;
        changeReason = 1;
    }

    //--------------------------------------------------------------------------

    function updateYear(offset) {
        var date = new Date(dateValue.valueOf());
        date.setFullYear(date.getFullYear() + offset);
        clearDate(date);
        dateValue = date;
        changeReason = 1;
    }

    //--------------------------------------------------------------------------

    function clearDate(date) {
        if (!monthYear) {
            date.setMonth(0);
        }
        date.setDate(1);
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
        date.setMilliseconds(0);
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

        var date;

        if (typeof value === "undefined") {
            date = new Date();
            clearDate(date);
            dateValue = date;
            formData.setValue(binding, undefined);
        } else {
            date = XFormJS.toDate(value);
            clearDate(date);
            dateValue = date;
            formData.setValue(binding, dateValue.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
