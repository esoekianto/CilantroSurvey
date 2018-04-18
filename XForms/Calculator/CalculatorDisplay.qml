/* Copyright 2016 Esri
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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Rectangle {
    id: image

    property CalculatorALU alu
    property color textColor: "#343434"
    property var locale

    color: "#c2c8ad"
    radius: 4 * AppFramework.displayScaleFactor
    border {
        width: 1
        color: "#999"
    }

    GridLayout {
        anchors {
            fill: parent
            margins: 4 * AppFramework.displayScaleFactor
        }

        columns: 2
        rows: 2

        Text {
            Layout.fillWidth: true
            Layout.columnSpan: 2

            font {
                pixelSize: parent.height * 0.6
                bold: true
            }

            text: alu.input
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            color: textColor
            smooth: true
        }

        Text {
            Layout.fillWidth: true

            text: isFinite(alu.memory) ? "M %1".arg(alu.memory.toString()) : ""

            font {
                pointSize: 10
            }

            horizontalAlignment: Text.AlignLeft
        }

        Text {
            Layout.fillWidth: true

            text: alu.currentExpression

            font {
                pointSize: 10
            }

            horizontalAlignment: Text.AlignRight
        }
    }
}
