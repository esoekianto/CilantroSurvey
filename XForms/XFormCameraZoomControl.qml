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
import QtQuick.Layouts 1.3
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0

Item {
    id : zoomControl

    property int currentZoom: 1
    property int minimumZoom: 1
    property int maximumZoom: 1
    property alias sliderValue: cameraZoomSlider.value

    signal zoomTo(real value)

    RowLayout {
        anchors.fill: parent
        spacing: 10 * AppFramework.displayScaleFactor

        // spacer --------------------------------------------------------------

        Item {
            Layout.fillWidth: true
        }

        // zoom out ------------------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            Text {
                id: minus
                text: "-"
                anchors.centerIn: parent
                color: "white"
                font {
                    bold: true
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (cameraZoomSlider.value > 1) {
                        var currentValue = Math.round(cameraZoomSlider.value);
                        currentValue -= 1.0;
                        cameraZoomSlider.value = currentValue;
                    }
                }
            }
        }

        // slider --------------------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 100 * AppFramework.displayScaleFactor
            Layout.maximumWidth: 260 * AppFramework.displayScaleFactor
            Slider {
                id: cameraZoomSlider
                width: parent.width
                height: parent.height * .7
                anchors.verticalCenter: parent.verticalCenter
                minimumValue: minimumZoom
                maximumValue: maximumZoom
                stepSize: 0.0
                onValueChanged: {
                    zoomTo(value);
                    //currentZoom = Math.round(value);
                }
                style: SliderStyle {
                    handle: Rectangle {
                                anchors.centerIn: parent
                                color: control.pressed ? "white" : "lightgray"
                                border.color: "gray"
                                border.width: 1 * AppFramework.displayScaleFactor
                                implicitWidth: 20 * AppFramework.displayScaleFactor
                                implicitHeight: 20 * AppFramework.displayScaleFactor
                                radius: 10 * AppFramework.displayScaleFactor
                            }
                }
            }
        }

        // zoomIn --------------------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: height
            Text {
                id: plus
                text: "+"
                anchors.centerIn: parent
                color: "white"
                font {
                    bold: true
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (cameraZoomSlider.value < camera.maximumZoom) {
                        var currentValue = Math.round(cameraZoomSlider.value);
                        currentValue += 1.0;
                        cameraZoomSlider.value = currentValue;
                    }
                }
            }
        }

        // spacer --------------------------------------------------------------

        Item {
            Layout.fillWidth: true
        }
    }

    // Fuctions ////////////////////////////////////////////////////////////////

    function updateZoom(zoomValue) {
        cameraZoomSlider.value = zoomValue;
    }

    // END /////////////////////////////////////////////////////////////////////
}
