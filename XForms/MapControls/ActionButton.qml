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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

//------------------------------------------------------------------------------

AbstractButton {
    id: control

    property real radius: (hasIcon && checkable) ? padding / 2 : height / 2

    property color backgroundColor: "white"
    property color hoveredColor: "darkgrey"
    property color pressedColor: "lightgrey"
    property color borderColor: "transparent"
    property alias textColor: textControl.color
    property color iconColor: textColor

    property alias iconSource: iconImage.source
    property size iconSize: Qt.size(30 * AppFramework.displayScaleFactor, 30 * AppFramework.displayScaleFactor)
    readonly property bool hasIcon: iconSource > ""

    property alias horizontalAlignment: textControl.horizontalAlignment
    property alias verticalAlignment: textControl.verticalAlignment

    property string toolTip

    //--------------------------------------------------------------------------

    ToolTip.text: control.toolTip
    ToolTip.delay: (hovered && !down) ? 1500 : 250
    ToolTip.timeout: (hovered && !down) ? 5000 : -1
    ToolTip.visible: ToolTip.text > "" && (down || hovered)

    //--------------------------------------------------------------------------

    padding: 4 * AppFramework.displayScaleFactor
    leftPadding: (hasIcon && checkable) ? padding : (12 * AppFramework.displayScaleFactor)
    rightPadding: leftPadding

    font {
        pointSize: 13
        bold: checkable && checked
    }

    background: Rectangle {
        radius: control.radius
        color: pressed ? pressedColor : backgroundColor
        border {
            width: 1
            color: hovered ? hoveredColor : borderColor
        }
    }

    contentItem: RowLayout {
        id: layout

        spacing: 4 * AppFramework.displayScaleFactor
        opacity: enabled ? 1 : 0.5

        Item {
            Layout.preferredWidth: iconSize.width
            Layout.preferredHeight: iconSize.height
            Layout.margins: 2 * AppFramework.displayScaleFactor

            visible: hasIcon

            Image {
                id: iconImage

                anchors.fill: parent

                fillMode: Image.PreserveAspectFit
                verticalAlignment: Image.AlignVCenter
                visible: false
            }

            ColorOverlay {
                anchors.fill: iconImage

                source: iconImage
                color: textColor
            }
        }

        Item {
            Layout.preferredWidth: iconSize.width / 2
            Layout.preferredHeight: iconSize.height

            visible: checkable

            Image {
                id: checkImage

                anchors.fill: parent

                fillMode: Image.PreserveAspectFit

                source: "images/check.png"
                verticalAlignment: Image.AlignVCenter
                visible: false
            }

            ColorOverlay {
                anchors.fill: checkImage

                source: checkImage
                color: textColor
                visible: checked
            }
        }

        Text {
            id: textControl

            Layout.fillWidth: true
            Layout.preferredHeight: iconSize.height

            text: control.text
            font: control.font
            horizontalAlignment: (hasIcon || checkable) ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
