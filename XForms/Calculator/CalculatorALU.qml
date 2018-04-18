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

import QtQuick 2.5

QtObject {
    property real result: 0
    property real memory: Number.NaN
    readonly property bool hasMemory: isFinite(memory)
    property string input: "0"
    property int inputMax: 20

    property string lastOperation
    property string currentOperation
    property real currentValue: 0
    property string currentExpression: currentOperation > "" ? "%1 %2 %3".arg(currentValue.toString()).arg(currentOperation).arg(input) : ""

    //--------------------------------------------------------------------------

    readonly property string kOperationBackspace: "⌫"
    readonly property string kOperationBack: "\u2190"
    readonly property string kOperationErase: "\u2192"
    readonly property string kOperationEnter: "↵"
    readonly property string kOperationClear: "C"
    readonly property string kOperationAllClear: "AC"
    readonly property string kOperationPoint: "."
    readonly property string kOperationEquals: "="

    readonly property string kOperationAdd : "+"
    readonly property string kOperationSubtract : "-"
    readonly property string kOperationDivide : "\u00f7"
    readonly property string kOperationMultiply : "\u00d7"
    readonly property string kOperationSquareRoot : "\u221a"
    readonly property string kOperationSign : "\u00b1"
    readonly property string kOperationInverse: "1/x"
    readonly property string kOperationSquare: "x²"
    readonly property string kOperationPercent : "%"

    readonly property string kOperationMemoryClear: "MC"
    readonly property string kOperationMemoryAdd: "M+"
    readonly property string kOperationMemorySubtract: "M-"
    readonly property string kOperationMemoryRecall: "MR"


    //--------------------------------------------------------------------------

    function setInput(text) {
        result = Number(text);
        if (!isFinite(result)) {
            result = 0;
        }

        input = result.toString();
    }

    //--------------------------------------------------------------------------

    function clear() {
        currentValue = 0;
        memory = Number.NaN;
        lastOperation = "";
        result = 0;
        input = "";
    }

    //--------------------------------------------------------------------------

    function disabled(op) {
        if (op === kOperationPoint && result.toString().indexOf('.') >= 0) {
            return true;
        } else if (op === kOperationSquareRoot && result < 0) {
            return true;
        } else {
            return false;
        }
    }

    //--------------------------------------------------------------------------

    function doOperation(op) {
        if (disabled(op)) {
            return;
        }

        if (op.length === 1 && ((op >= "0" && op <= "9") || op === kOperationPoint) ) {
            if (input.length >= inputMax) {
                return;
            }

            if (lastOperation.length == 1 && ((lastOperation >= "0" && lastOperation <= "9") || lastOperation == kOperationPoint) ) {
                input = input + op;
            } else {
                input = op;
            }

            lastOperation = op;

            result = Number(input);

            return;
        }

        lastOperation = op;

        switch (currentOperation) {
        case kOperationAdd:
            result += currentValue;
            break;

        case kOperationSubtract:
            result = currentValue - result;
            break;

        case kOperationMultiply:
            result *= currentValue;
            break;

        case kOperationDivide:
            result = currentValue / result;
            break;

        case kOperationEquals:
        case kOperationEnter:
            break;
        }

        if (op === kOperationAdd || op === kOperationSubtract || op === kOperationMultiply || op === kOperationDivide) {
            currentOperation = op;
            currentValue = result;
            return;
        }

        currentValue = 0;
        currentOperation = "";

        switch (op) {
        case kOperationInverse:
            result = 1 / result;
            break;

        case kOperationSquare:
            result *= result;
            break;

        case "Abs":
            result = Math.abs(result);
            break;

        case "Int":
            result = Math.floor(result);
            break;

        case kOperationSign:
            result = -result;
            break;

        case kOperationPercent:
            result /= 100;
            break;

        case kOperationSquareRoot:
            result = Math.sqrt(result);
            break;

        case kOperationMemoryClear:
            memory = Number.NaN;
            break;

        case kOperationMemoryAdd:
            if (isFinite(memory)) {
                memory += result;
            } else {
                memory = result;
            }

            break;

        case kOperationMemoryRecall:
            if (isFinite(memory)) {
                result = memory;
            }
            break;

        case kOperationMemorySubtract:
            if (isFinite(memory)) {
                memory -= result;
            } else {
                memory = -result;
            }
            break;

        case kOperationBack:
        case kOperationBackspace:
        case kOperationErase:
            input = input.slice(0, -1);
            if (input.length == 0) {
                input = "0";
            }
            result = Number(input);
            break;

        case kOperationClear:
            result = 0;
            break;

        case kOperationAllClear:
            clear();
            break;
        }

        input = result.toString();
    }
}
