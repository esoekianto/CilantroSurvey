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

GridLayout {
    property CalculatorALU alu: CalculatorALU {}

    property real cellWidth: width / columns
    property real cellHeight: Math.min(height / rows, cellWidth)

    property color mathOperationColor: "#ff9200"
    property color mathOperationTextColor: "white"
    property color numberColor: "#928880"
    property color numberTextColor: "white"
    property color memoryOperationColor: "darkgrey"
    property color memoryOperationTextColor: "white"
    property color actionColor: "#aab1bb"
    property color doneColor: "#007aff"

    property alias equalsKey: equalsKey

    property var locale: Qt.locale()

    //--------------------------------------------------------------------------

    implicitWidth: 300
    implicitHeight: 300

    columnSpacing: 5 * AppFramework.displayScaleFactor
    rowSpacing: columnSpacing

    columns: 5
    rows: 5

    //--------------------------------------------------------------------------

    Keys.onPressed: {
        alu.doOperation(event.text);
    }

    CalculatorKey { operation: alu.kOperationMemoryClear; color: memoryOperationColor; textColor: memoryOperationTextColor; enabled: alu.hasMemory }
    CalculatorKey { operation: alu.kOperationMemoryAdd; color: memoryOperationColor; textColor: memoryOperationTextColor }
    CalculatorKey { operation: alu.kOperationMemorySubtract; color: memoryOperationColor; textColor: memoryOperationTextColor }
    CalculatorKey { operation: alu.kOperationMemoryRecall; color: memoryOperationColor; textColor: memoryOperationTextColor; enabled: alu.hasMemory }

    CalculatorKey {
        color: "red"
        textColor: "white"
        operation: alu.kOperationAllClear
    }

    CalculatorKey { operation: "7"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "8"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "9"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: alu.kOperationDivide; color: mathOperationColor; textColor: mathOperationTextColor }
    CalculatorKey { operation: alu.kOperationBack; color: actionColor }

    CalculatorKey { operation: "4"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "5"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "6"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: alu.kOperationMultiply; color: mathOperationColor; textColor: mathOperationTextColor }
    CalculatorKey { operation: alu.kOperationSquare; color: mathOperationColor; textColor: mathOperationTextColor }

    CalculatorKey { operation: "1"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "2"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "3"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: alu.kOperationSubtract; color: mathOperationColor; textColor: mathOperationTextColor }
    CalculatorKey { operation: alu.kOperationSquareRoot; color: mathOperationColor; textColor: mathOperationTextColor }

    CalculatorKey { operation: alu.kOperationSign; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: "0"; color: numberColor; textColor: numberTextColor }
    CalculatorKey { operation: alu.kOperationPoint; color: numberColor; textColor: numberTextColor } //; text: locale.decimalPoint }
    CalculatorKey { operation: alu.kOperationAdd; color: mathOperationColor; textColor: mathOperationTextColor }
    CalculatorKey {
        id: equalsKey

        operation: alu.kOperationEquals
        color: mathOperationColor
        textColor: mathOperationTextColor
    }
}
