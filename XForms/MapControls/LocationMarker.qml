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
import QtQuick.Controls 1.4
import QtPositioning 5.3
import QtLocation 5.3

import ArcGIS.AppFramework 1.0

MapQuickItem {
    id: locationMarker

    property bool selected
    property color textColor: "blue"
    property real maximumTextWidth: 150 * AppFramework.displayScaleFactor
    property url locationPinImage: "images/location-pin.png"
    property url selectedPinImage: "images/selected-location-pin.png"
    property color locationPinTextColor: "white"
    property color selectedPinTextColor: "black"

    signal clicked()

    anchorPoint.x: pinImage.width/2
    anchorPoint.y: pinImage.height
    coordinate: locationData.coordinate

    visible: coordinate.isValid

    sourceItem: Image {
        id: pinImage

        width: 40 * AppFramework.displayScaleFactor
        height: width

        source: selected ? selectedPinImage : locationPinImage
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter

        MouseArea {
            anchors.centerIn: parent

            width: parent.paintedWidth
            height: parent.paintedHeight

            onClicked: {
                locationMarker.clicked();
            }
        }

        Item {
            anchors {
                centerIn: parent
            }

            width: parent.width / 2
            height: width

            /*
            Rectangle {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                radius: width / 2
                color: "#fafafa"
                border {
                    width: 1
                    color: "#80808080"
                }
            }
            */

            Text {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "%1".arg(index + 1)
                color: selected ? selectedPinTextColor : locationPinTextColor
                fontSizeMode: Text.HorizontalFit
                minimumPointSize: 10
                font {
                    pointSize: 13
                    bold: selected
                }
            }
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: 3 * AppFramework.displayScaleFactor
            }

            visible: selected

            width: maximumTextWidth
            text: locationData.address.text
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font {
                pointSize: 13
                bold: selected
            }
            color: textColor
            style: Text.Outline
            styleColor: "white"
        }
    }
}
