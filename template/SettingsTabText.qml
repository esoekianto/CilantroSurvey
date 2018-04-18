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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../XForms"
import "../Controls"

Tab {
    title: qsTr("Text")

    //--------------------------------------------------------------------------

    Item {
        Component.onDestruction: {
            app.textScaleFactor = textScaleSlider.value;
            settings.setValue("textScaleFactor", app.textScaleFactor, 1);
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 8 * AppFramework.displayScaleFactor

            AppText {
                Layout.fillWidth: true

                text: qsTr("The text scale setting allows you to adjust the ways surveys are displayed to best suit your device's display characteristics.")
                color: app.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("Scale %1%").arg(textScaleSlider.value * 100)
                color: app.textColor
            }

            Slider {
                id: textScaleSlider

                Layout.fillWidth: true

                minimumValue: 1
                maximumValue: 2
                value: app.textScaleFactor
                stepSize: 0.05
                updateValueWhileDragging: true

                style: SliderStyle {
                    id: sliderStyle

                    property real grooveHeight: 8 * AppFramework.displayScaleFactor

                    handle: Item {
                        implicitWidth:  implicitHeight
                        implicitHeight: sliderStyle.grooveHeight * 4

                        Rectangle {
                            anchors.fill: parent

                            radius: width/2
                            gradient: Gradient {
                                GradientStop { color: control.pressed ? "#e0e0e0" : "#fff" ; position: 1 }
                                GradientStop { color: "#eee" ; position: 0 }
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
                        implicitHeight: sliderStyle.grooveHeight
                        radius: sliderStyle.grooveHeight / 2

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

                            color: "darkgrey"
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
            }

            RowLayout {
                Layout.fillWidth: true

                AppText {
                    id: refText

                    Layout.fillWidth: true

                    text: "A"
                    font.pointSize: 15
                    color: app.textColor
                    horizontalAlignment: Text.AlignLeft
                }

                AppText {
                    Layout.fillWidth: true

                    text: refText.text
                    font.pointSize: refText.font.pointSize * textScaleSlider.maximumValue
                    color: refText.color
                    horizontalAlignment: Text.AlignRight
                }
            }

            ScrollView {
                id: scrollView

                Layout.fillWidth: true
                Layout.fillHeight: true

                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
                flickableItem.flickableDirection: Flickable.VerticalFlick

                GroupRectangle {
                    width: scrollView.width
                    height: textPreview.height + textPreview.anchors.margins * 4

                    ColumnLayout {
                        id: textPreview

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 5 * AppFramework.displayScaleFactor
                        }

                        spacing: 8 * AppFramework.displayScaleFactor

                        Text {
                            Layout.fillWidth: true

                            text: qsTr("Group Label Text")
                            color: xformStyle.groupLabelColor
                            font {
                                pointSize: xformStyle.groupLabelPointSize
                                bold: xformStyle.groupLabelBold
                                family: xformStyle.groupLabelFontFamily
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            Layout.fillWidth: true

                            text: qsTr("Label Text")
                            color: xformStyle.labelColor
                            font {
                                pointSize: xformStyle.labelPointSize
                                bold: xformStyle.labelBold
                                family: xformStyle.labelFontFamily
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            Layout.fillWidth: true

                            text: qsTr("Hint Text")
                            color: xformStyle.hintColor
                            font {
                                pointSize: xformStyle.hintPointSize
                                bold: xformStyle.hintBold
                                family: xformStyle.hintFontFamily
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        TextField {
                            Layout.fillWidth: true

                            text: qsTr("Input Text")

                            style: TextFieldStyle {
                                renderType: Text.QtRendering
                                textColor: xformStyle.inputTextColor
                                font {
                                    bold: xformStyle.inputBold
                                    pointSize: xformStyle.inputPointSize
                                    family: xformStyle.inputFontFamily
                                }
                            }
                        }

                        XFormStyle {
                            id: xformStyle
                            visible: false

                            textScaleFactor: textScaleSlider.value
                            fontFamily: app.fontFamily
                        }
                    }
                }
            }
        }
    }
}
