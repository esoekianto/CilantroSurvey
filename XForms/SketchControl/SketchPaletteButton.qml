/* Copyright 2017 Esri
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

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: control

    //--------------------------------------------------------------------------

    property color color
    property real lineWidth
    property real textScale
    property Component contentItem: colorSwatch
    property bool selected: false
    property bool nonSelectTypeButton: false
    property url imageSource
    property bool showArrow

    //--------------------------------------------------------------------------

    signal clicked()
    signal pressAndHold()

    //--------------------------------------------------------------------------

    Loader {
        anchors.fill: parent

        sourceComponent:
            imageSource > "" ? imageSwatch
                             : textScale > 0 ? textSwatch
                                             : lineWidth > 0 ? lineSwatch
                                                             : colorSwatch
    }

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            control.clicked();
        }

        onPressAndHold: {
            control.pressAndHold();
        }
    }

    Component {
        id: colorSwatch

        Item {
            anchors {
                fill: parent
            }

            Rectangle {
                anchors {
                    fill: parent
                    margins: (selected ? 0 : 5) * AppFramework.displayScaleFactor
                }

                color: control.color
                radius: width / 2
                border {
                    width: (selected ? 3 : 1) * AppFramework.displayScaleFactor
                    color: "lightgrey"
                }
            }
        }
    }

    Component {
        id: lineSwatch

        Item {
            Rectangle {
                id: lineRect

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    bottom: parent.bottom
                    bottomMargin: 5 * AppFramework.displayScaleFactor
                    topMargin: (showArrow ? 8 : 5)  * AppFramework.displayScaleFactor
                }

                color: selected ? control.color : "lightgrey"
                width: lineWidth * AppFramework.displayScaleFactor
            }

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    //margins: - 5 * AppFramework.displayScaleFactor
                }

                visible: showArrow
                text: "^"
                horizontalAlignment: Qt.AlignHCenter
                font {
                    bold: lineWidth > 3
                    pixelSize: parent.height
                }
                scale: 1 + lineWidth / 12
                color: lineRect.color
            }
        }
    }

    Component {
        id: imageSwatch

        Item {
            Image {
                id: image

                anchors.fill: parent
                source: imageSource
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            ColorOverlay {
                source: image
                anchors.fill: image
                color: nonSelectTypeButton
                       ? control.color
                       : selected ? "black" : "grey"
            }

            Glow {
                visible: selected && !nonSelectTypeButton
                source: image
                anchors.fill: image
                color: "lightgrey"
                radius: 2 * AppFramework.displayScaleFactor
            }
        }
    }

    Component {
        id: textSwatch

        Item {
            readonly property bool _selected: selected || textScale === selectedTextScale

            Text {
                id: text

                anchors.centerIn: parent
                text: "A"
                scale: textScale
                color: selected ? control.color : "grey"
                horizontalAlignment: Text.AlignHCenter
                font {
                    pixelSize: parent.height * 0.5
                    bold: _selected
                }

            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 3 * AppFramework.displayScaleFactor
                }

                visible: _selected
                color: _selected ? control.color : "grey"
                width: 3 * AppFramework.displayScaleFactor
                height: width
                radius: width / 2
            }
        }
    }
}
