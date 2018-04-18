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
    id: calculator

    property alias alu: keypad.alu
    property alias display: display
    property alias keypad: keypad
    property var locale: Qt.locale()

    //--------------------------------------------------------------------------

    implicitWidth: 360
    implicitHeight: 480
    color: "#d0d4da"

    ColumnLayout {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 8 * AppFramework.displayScaleFactor

        CalculatorDisplay {
            id: display

            Layout.fillWidth: true
            Layout.preferredHeight: 80 * AppFramework.displayScaleFactor

            alu: keypad.alu
            locale: calculator.locale
        }

        CalculatorKeypad {
            id: keypad

            Layout.fillWidth: true
            Layout.fillHeight: true

            focus: true
            locale: calculator.locale
        }
    }
}
