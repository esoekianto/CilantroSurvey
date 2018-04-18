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
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls.Private 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

RowLayout {
    property var formElement
    property var binding
    property XFormData formData
    property bool readOnly: binding["@readonly"] === "true()"
    property var appearance: formElement ? formElement["@appearance"] : null
    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property bool rightToLeft: xform.languageDirection === Qt.RightToLeft

    readonly property bool relevant: parent.relevant


    anchors {
        left: parent.left
        right: parent.right
    }

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onRightToLeftChanged: {
        slider.value = maximumValue - slider.value;
    }

    Slider {
        id: slider

        Layout.fillWidth: true

        minimumValue: 0
        maximumValue: 10
        stepSize: 1
        tickmarksEnabled: true
        value: rightToLeft ? maximumValue : minimumValue

        style: SliderStyle {
            handle: Item {
                implicitWidth:  implicitHeight
                implicitHeight: TextSingleton.implicitHeight * 1.4

                Rectangle {
                    id: handle
                    anchors.fill: parent

                    radius: width/2
                    gradient: Gradient {
                        GradientStop { color: control.pressed ? "#e0e0e0" : "#fff" ; position: 1 }
                        GradientStop { color: "#eee" ; position: 0 }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: width/2
                        border.color: "#99ffffff"
                        color: control.activeFocus ? "#224f7fbf" : "transparent"

                        Text {
                            anchors.centerIn: parent

                            text: rightToLeft ? control.maximumValue - control.value : control.value
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: "black"
                        }
                    }
                    border {
                        color: control.activeFocus ? "#47b" : "#777"
                        width: 2
                    }
                }
            }

            groove: Rectangle {
                id: grooveRect

                implicitWidth: 200
                implicitHeight: TextSingleton.implicitHeight
                radius: TextSingleton.implicitHeight / 2

                anchors.verticalCenter: parent.verticalCenter


                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: grooveRect.width
                        height: grooveRect.height

                        Rectangle {
                            anchors.fill: parent
                            radius: grooveRect.radius
                        }
                    }
                }

                Rectangle {
                    width: parent.height
                    height: parent.width
                    anchors.centerIn: parent
                    rotation: 90

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: rightToLeft ? "green": "red" }
                        GradientStop { position: 0.5; color: "yellow" }
                        GradientStop { position: 1.0; color: rightToLeft ? "red" : "green" }
                    }
                }

                Rectangle {
                    anchors.fill: parent

                    color: "transparent"
                    radius: parent.radius
                    border {
                        color: "#80020202"
                        width: 1
                    }
                }
            }
        }

        onValueChanged: {
            setValue(rightToLeft ? maximumValue - value : value, true);
        }
    }
    
    //--------------------------------------------------------------------------

    function setValue(value, byUser) {
        if (!byUser) {
            var _value = XFormJS.isEmpty(value) ? 0 : value;
            slider.value = rightToLeft ? maximumValue - _value : _value;
        }

        formData.setValue(binding, value);
    }

    //--------------------------------------------------------------------------
}
