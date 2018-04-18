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
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS
import "Calculator"


RowLayout {
    id: inputLayout

    property var formElement
    property var binding
    property XFormData formData

    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    readonly property bool relevant: parent.relevant

    property bool valid: true
    property string emptyText
    property var appearance: (formElement ? formElement["@appearance"] : "") || ""

    readonly property bool isBarcode: binding["@type"] === "barcode"
    readonly property bool isReadOnly: XFormJS.toBoolean(binding["@readonly"])
    readonly property bool showSpinners: appearance.indexOf("spinner") >= 0 && !isReadOnly
    property real spinnerScale: 2
    property real spinnerMargin: 15 * AppFramework.displayScaleFactor

    property int barcodeButtonSize: 40 * AppFramework.displayScaleFactor

    property Loader keypadLoader


    anchors {
        left: parent.left
        right: parent.right
    }

    layoutDirection: xform.languageDirection

    signal cleared();

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!isReadOnly) {
            if (appearance.indexOf("numbers") >= 0) {
                keypadLoader = numbersKeypad.createObject(parent);
            } else if (appearance.indexOf("calculator") >= 0) {
                keypadLoader = calculatorKeypad.createObject(parent);
            }
        }
    }


    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined, 3);
            valid = true;
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding && changeReason !== 1) {
            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    onCleared: {
        setValue(undefined, 1);
        valid = true;
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredHeight: textField.height
        Layout.preferredWidth: Layout.preferredHeight * spinnerScale
        Layout.rightMargin: spinnerMargin

        sourceComponent: spinnerButtonComponent
        active: showSpinners
        visible: showSpinners

        onLoaded: {
            item.step = -1;
        }
    }

    //--------------------------------------------------------------------------
    //XFormTextField {
    TextField {
        id: textField

        Layout.fillWidth: true

        readOnly: isReadOnly
        visible: !isBarcode || (isBarcode && appearance !== "minimal")

        style: TextFieldStyle {
            renderType: Text.QtRendering
            textColor: valid && textField.acceptableInput
                       ? changeReason === 3 ? xform.style.inputAltTextColor : xform.style.inputTextColor
            : xform.style.inputErrorTextColor
            font {
                bold: xform.style.inputBold
                pointSize: xform.style.inputPointSize
                family: xform.style.inputFontFamily
            }
        }

        Component.onCompleted: {
            var fieldLength = 255;

            switch (binding["@type"]) {
            case "int":
                if (Qt.platform.os === "ios") {
                    inputMethodHints = Qt.ImhPreferNumbers;
                } else {
                    inputMethodHints = Qt.ImhDigitsOnly;
                }
                validator = intValidatorComponent.createObject(this);
                fieldLength = 9;
                break;

            case "decimal":
                if (Qt.platform.os === "ios") {
                    inputMethodHints = Qt.ImhPreferNumbers;
                } else {
                    inputMethodHints = Qt.ImhFormattedNumbersOnly;
                }
                validator = doubleValidatorComponent.createObject(this);
                break;

            case "date":
                inputMethodHints = Qt.ImhDate;
                break;

            case "time":
                inputMethodHints = Qt.ImhTime;
                validator = timeValidatorComponent.createObject(this);
                placeholderText = "hh:mm:ss";
                break;

            case "dateTime":
                inputMethodHints = Qt.ImhDate | Qt.ImhTime;
                break;

            case "barcode":
                break;
            }

            var esriProperty = binding["@esri:fieldLength"];
            if (esriProperty > "") {
                var n = Number(esriProperty);
                if (isFinite(n)) {
                    fieldLength = n;
                }
            }

            if (fieldLength > 0) {
                maximumLength = fieldLength;
            }

            var mask = formElement["@esri:inputMask"];
            if (mask > "") {
                textField.inputMask = mask;
            }

            if (binding["@constraint"]) {
                constraint = formData.createConstraint(this, binding);
            }

            if (binding["@calculate"]) {

            }

            if (showSpinners) {
                horizontalAlignment = TextInput.AlignHCenter;
            }
        }

        onInputMaskChanged: {
            emptyText = text;
            //console.log("emptyText:", JSON.stringify(emptyText));
        }

        onEditingFinished: {
            var value;
            var validate = false;

            if (text > "") {
                validate = true;

                switch (binding["@type"]) {
                case "int":
                    value = Number(text);
                    break;

                case "decimal":
                    value = Number(text);
                    break;

                case "date":
                case "dateTime":
                    break;

                default:
                    value = text;
                    break;
                }
            }

            formData.setValue(binding, value);

            if (validate && constraint && relevant) {
                valid = constraint.validate();
            }
        }

        onLengthChanged: {
            if (length === 0) {
                formData.setValue(binding, undefined);
            } else if (!readOnly){
                clearButtonLoader.active = true;
            }
        }

        onActiveFocusChanged: {
            if (activeFocus && keypadLoader) {
                keypadLoader.showKeypad = true;
            }

            xform.controlFocusChanged(this, activeFocus, binding);
        }

        Keys.onPressed: {
            if (!readOnly) {
                changeReason = 1;
            }
        }

        Loader {
            id: clearButtonLoader

            property real clearButtonMargin: clearButtonLoader.width + clearButtonLoader.anchors.margins * 1.5
            property int textDirection: textField.length > 0 ? textField.isRightToLeft(0, textField.length) ? Qt.RightToLeft : Qt.LeftToRight : layoutDirection
            property real endMargin: textField.__contentHeight / 3

            onTextDirectionChanged: {
                anchors.left = undefined;
                anchors.right = undefined;

                if (textDirection == Qt.RightToLeft) {
                    anchors.left = parent.left;
                } else {
                    anchors.right = parent.right;
                }
            }

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: 5
            }

            visible: parent.text > "" && !parent.readOnly
            width: height
            active: false

            sourceComponent: ImageButton {
                source: "images/clear.png"
                glowColor: "transparent"
                hoverColor: "transparent"
                pressedColor: "transparent"

                onClicked: {
                    cleared();
                }
            }

            onVisibleChanged: {
                if (parent.__panel) {
                    parent.__panel.rightMargin = Qt.binding(function() { return visible && textDirection == Qt.LeftToRight ? clearButtonMargin : endMargin; });
                    parent.__panel.leftMargin = Qt.binding(function() { return visible && textDirection == Qt.RightToLeft ? clearButtonMargin : endMargin; });
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: intValidatorComponent

        /*
        IntValidator {
        }
        */

        RegExpValidator {
            regExp: /^[-]?\d+$/
        }
    }

    Component {
        id: doubleValidatorComponent

        /*
        DoubleValidator {
            notation: DoubleValidator.StandardNotation
            decimals: 10
        }
        */

        RegExpValidator {
            regExp: /^[-]?((\.\d+)|(\d+(\.\d+)?))$/
        }
    }

    Component {
        id: timeValidatorComponent

        RegExpValidator {
            regExp: /^[0-9][0-9]:[0-5][0-9]:[0-5][0-9]$/
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredHeight: textField.height
        Layout.preferredWidth: Layout.preferredHeight * spinnerScale
        Layout.leftMargin: spinnerMargin

        sourceComponent: spinnerButtonComponent
        active: showSpinners
        visible: showSpinners
    }

    Component {
        id: spinnerButtonComponent

        Rectangle {
            id: spinnerButton

            property double step: 1
            property bool playSound: false
            property url soundSource: "audio/" + (step < 0 ? "click-down.mp3" : "click-up.mp3")
            property int repeatCount: 0

            signal clicked
            signal repeat

            color: mouseArea.pressed ? border.color : xform.style.keyColor
            border {
                width: 1
                color: xform.style.keyBorderColor
            }
            radius: height / 2 //* 0.16

            onClicked: {
                //textField.forceActiveFocus();
                spinValue(playSound);
            }

            onRepeat: {
                repeatCount++;
                spinValue(playSound && repeatCount == 1);
            }

            function spinValue(sound) {
                if (sound) {
                    if (audio.playbackState === Audio.PlayingState) {
                        audio.stop();
                    }

                    audio.play();
                }

                var textValue = textField.text;
                var stepValue = step;
                var precision;
                var dotIndex = textValue.indexOf(".");
                if (dotIndex >= 0) {
                    precision = textValue.length - dotIndex - 1;
                    if (precision > 0) {
                        stepValue = Math.pow(10, -precision) * step;
                    }
                }

                var value = Number(textValue) + stepValue;
                setValue(value, 1);

                if (precision > 0) {
                    textField.text = value.toFixed(precision);
                }
            }

            Text {
                anchors {
                    centerIn: parent
                    verticalCenterOffset: -paintedHeight * 0.05
                }

                text: step > 0 ? "+" : "-"
                color: xform.style.keyTextColor
                styleColor: xform.style.keyStyleColor
                style: Text.Raised

                font {
                    bold: true
                    pixelSize: parent.height * 0.8
                    family: xform.style.keyFontFamily
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                onClicked: {
                    spinnerButton.clicked();
                }

                onPressAndHold: {
                    repeatCount = 0;
                    repeatTimer.start();
                }

                onReleased: {
                    repeatTimer.stop();
                }

                onExited: {
                    repeatTimer.stop();
                }

                onCanceled: {
                    repeatTimer.stop();
                }
            }

            Audio {
                id: audio

                autoLoad: false
                source: spinnerButton.soundSource
            }

            Timer {
                id: repeatTimer

                running: false
                interval: 100
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    spinnerButton.repeat();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculateButtonComponent

        ImageButton {
            source: "images/refresh_update.png"

            onClicked: {
                formData.expressionsList.triggerExpression(binding, "calculate");
                setValue(calculatedValue, 3);
            }
        }
    }

    Loader {
        id: calculateButtonLoader

        Layout.preferredWidth: textField.height
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: calculateButtonComponent
        active: false
        visible: !isReadOnly && changeReason === 1 && active
    }

    //--------------------------------------------------------------------------

    Component {
        id: barcodeButtonComponent

        ImageButton {
            source: "images/barcode-scan.png"

            onClicked: {
                scanBarcode();
            }
        }
    }

    Loader {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: barcodeButtonSize
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: barcodeButtonComponent
        active: isBarcode && QtMultimedia.availableCameras.length > 0
        visible: active
    }

    Component {
        id: scanBarcodePage

        XFormBarcodeScan {
            onCodeScanned: {
                setValue(code, 1);
            }
        }
    }

    function scanBarcode() {
        if (QtMultimedia.availableCameras.length <= 0) {
            console.log("No available cameras to scan barcode");
            return;
        }

        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: scanBarcodePage,
                                        properties: {
                                            formElement: formElement,
                                        }
                                    });
    }

    //--------------------------------------------------------------------------

    Component {
        id: numbersKeypad

        Loader {
            property bool showKeypad: true

            width: parent.width
            height: visible ? (textField.height + AppFramework.displayScaleFactor * 5) * 4 * 1.2  : 0 //150 * AppFramework.displayScaleFactor * xform.style.scale : 0
            active: textField.activeFocus && showKeypad
            visible: active


            onActiveChanged: {
                if (active) {
                    Qt.inputMethod.hide();
                }
            }

            onLoaded: {
                xform.ensureItemVisible(inputLayout.parent.parent);
            }

            sourceComponent: Item {
                MouseArea {
                    anchors.fill: parent

                    enabled: false

                    onClicked: {
                        keypadLoader.showKeypad = false;
                    }
                }

                RowLayout {
                    anchors.fill: parent

                    XFormNumericKeypad {
                        Layout.fillWidth: true
                        Layout.maximumWidth: textField.height * spinnerScale * 5
                        Layout.alignment: Qt.AlignHCenter

                        property bool decimalInput: !(binding["@type"] === "int")

                        showPoint: decimalInput
                        locale: xform.locale

                        Component.onCompleted: {
                            if (textField.inputMask > "") {
                                showSign = false;
                                showPoint = false;
                            }
                        }

                        onKeyPressed: {
                            var textValue = textField.text;
                            var updateTextField = true;

                            if (textField.inputMask > "") {
                                textValue = textValue.replace(/[^\d]/g, '').trim();
                            }

                            switch (key) {
                            case Qt.Key_plusminus:
                                if (textValue.substring(0, 1) === "-") {
                                    textValue = textValue.substring(1);
                                } else {
                                    textValue = "-" + textValue;
                                }
                                break;

                            case Qt.Key_Enter:
                                updateTextField = false;
                                keypadLoader.showKeypad = false;
                                break;

                            case Qt.Key_Delete:
                                if (textField.length > 0) {
                                    textValue = textValue.slice(0, -1);
                                }
                                break;

                            case Qt.Key_Return:
                                updateTextField = false;
                                textField.editingFinished();
                                break;

                            case Qt.Key_Period:
                                if (textValue.indexOf(".") < 0) {
                                    textValue += ".";
                                }
                                break;

                            default:
                                textValue += text;
                                break;
                            }

                            if (updateTextField) {
                                textField.text = textValue;
                                if (textField.inputMask > "") {
                                    textField.cursorPosition = textField.text.trim().length;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculatorKeypad

        Loader {
            property bool showKeypad: true

            width: parent.width
            height: visible ? (textField.height + AppFramework.displayScaleFactor * 5) * 5 * 1.4 : 0
            active: textField.activeFocus && showKeypad
            visible: active


            onActiveChanged: {
                if (active) {
                    Qt.inputMethod.hide();
                }
            }

            onLoaded: {
                xform.ensureItemVisible(inputLayout.parent.parent);
            }

            sourceComponent: Item {
                RowLayout {
                    anchors.fill: parent

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: textField.height * spinnerScale * 6
                        Layout.alignment: Qt.AlignHCenter

                        RowLayout {
                            Layout.fillWidth: true

                            visible: isFinite(calculator.alu.memory) || calculator.alu.currentExpression > ""

                            Text {
                                visible: isFinite(calculator.alu.memory)
                                color: xform.style.hintColor
                                font.pointSize: 10
                                text: "M %1".arg(calculator.alu.memory)
                            }

                            Text {
                                Layout.fillWidth: true

                                color: xform.style.hintColor
                                font.pointSize: 10
                                text: calculator.alu.currentExpression
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                            }
                        }

                        Calculator {
                            id: calculator

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            display.visible: false
                            color: "transparent"
                            locale: xform.locale

                            alu.onInputChanged: {
                                textField.text = alu.input;
                                if (textField.inputMask > "") {
                                    textField.cursorPosition = textField.text.trim().length;
                                }
                            }

                            //                        keypad {
                            //                            equalsKey {
                            //                                operation: alu.kOperationEnter
                            //                                color: "#007aff"
                            //                            }
                            //                        }
                        }
                    }
                }

                Connections {
                    target: textField

                    onEditingFinished: {
                        calculator.alu.setInput(textField.text);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function validateInput() {
        if (!relevant) {
            console.log("Validation not relevant:", JSON.stringify(binding));
            return;
        }

        if (textField.acceptableInput) {
            return;
        }

        if (!(textField.inputMask > ""))
        {
            return;
        }

        var nodeset = binding["@nodeset"];
        var required = binding["@required"] === "true()";

        if (!required && textField.text == emptyText) {
            // console.log("emptyMasked:", JSON.stringify(textField.text), "==", JSON.stringify(emptyText));
            return;
        }

        var field = schema.fieldNodes[nodeset];
        var controlNode = controlNodes[nodeset];

        var label = binding["@nodeset"];

        if (controlNode && controlNode.group && controlNode.group.labelControl) {
            label = controlNode.group.labelControl.value;
        } else if (field) {
            label = field.label;
        }

        var error = {
            "binding": binding,
            "message": qsTr("<b>%1</b> input is invalid").arg(label),
            "expression": textField.inputMask,
            "activeExpression": textField.text,
            "nodeset": nodeset,
            "field": field,
            "controlNode": controlNode
        };

        return error;
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

        var isEmpty = XFormJS.isEmpty(value);
        textField.text = isEmpty ? "" : value.toString();
        if (isEmpty) {
            textField.cursorPosition = 0;
        }

        formData.setValue(binding, XFormJS.toBindingType(value, binding));
    }

    //--------------------------------------------------------------------------

}
