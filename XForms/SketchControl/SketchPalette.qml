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
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

Loader {
    id: palette

    //--------------------------------------------------------------------------

    readonly property var kDefaultColors: [
        "black",
        "red",
        "orange",
        "green",
        "#00b2ff",
        "white"
    ]

    property var lineWidths: [
        1,
        3,
        5,
        10,
    ]

    property var textScales: [
        1,
        1.5,
        2,
        2.5
    ]

    //--------------------------------------------------------------------------

    readonly property color kBackgroundColor: "darkgrey"
    readonly property color kBorderColor: "lightgrey"
    readonly property color kSeparatorColor: "#40808080"

    //--------------------------------------------------------------------------

    property Settings settings
    property color selectedColor: "red"
    readonly property real selecteWidth: _selectedWidth
    property real _selectedWidth: 5
    readonly property real selectedTextScale: _selectedTextScale
    property real _selectedTextScale: 1.5
    readonly property bool textMode: _selectedTextScale > 0 && _textMode
    property bool _textMode: false
    readonly property bool lineMode: _selectedWidth > 0 && !_arrowMode
    property bool _smartMode: false
    property real buttonSize : 35 * AppFramework.displayScaleFactor
    readonly property bool smartMode: _smartMode
    property bool arrowMode: _arrowMode && !_smartMode && manualMode
    property bool _arrowMode: false

    property bool manualMode: true
    property bool showSmart: true

    //--------------------------------------------------------------------------

    readonly property string kKeyPrefix: "Sketch/"
    readonly property string kKeyPenColor: kKeyPrefix + "penColor"
    readonly property string kKeyPenWidth: kKeyPrefix + "penWidth"
    readonly property string kKeyTextScale: kKeyPrefix + "textScale"
    readonly property string kKeySmartMode: kKeyPrefix + "smartMode"
    readonly property string kKeyTextMode: kKeyPrefix + "textMode"
    readonly property string kKeyArrowMode: kKeyPrefix + "arrowMode"
    readonly property string kKeyManualMode: kKeyPrefix + "manualMode"
    readonly property string kKeyColor: kKeyPrefix + "color%1"

    //--------------------------------------------------------------------------

    property bool rotationAvailable: false
    signal rotate(int rotation)

    //--------------------------------------------------------------------------

    anchors.fill: parent
    active: false
    visible: active

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        for (var i = 0; i < kDefaultColors.length; i++) {
            colors.append({
                              color: kDefaultColors[i]
                          });
        }

        readSettings();
    }

    //--------------------------------------------------------------------------

    on_SmartModeChanged: {
        if (_smartMode) {
            _arrowMode = false;
        } else {
            if (manualMode) {
                _arrowMode = true;
            } else {
                _arrowMode = false;
            }
        }
    }

    //--------------------------------------------------------------------------

    sourceComponent: Item {
        id: drawer

        Component.onDestruction: {
            saveSettings();
        }

        MouseArea {
            anchors.fill: parent
            
            onClicked: {
                hide();
            }
            
            onWheel: {
            }
        }
        
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 5 * AppFramework.displayScaleFactor
            }
            
            Rectangle {
                anchors {
                    fill: layout
                    margins: -5 * AppFramework.displayScaleFactor
                }
                
                color: kBackgroundColor
                border {
                    color: kBorderColor
                    width: 1 * AppFramework.displayScaleFactor
                }
                radius: 5 * AppFramework.displayScaleFactor
            }
            
            GridLayout {
                id: layout
                
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                rowSpacing: 5 * AppFramework.displayScaleFactor

                Item {
                    Layout.preferredHeight: buttonSize
                    Layout.preferredWidth: buttonSize
                    Layout.row: 1
                    Layout.column: 0
                    SketchPaletteButton {
                        anchors.fill: parent
                        imageSource: "../images/rotate_left.png"
                        nonSelectTypeButton: true
                        color: rotationAvailable ? "white" : "grey"
                        enabled: rotationAvailable

                        onClicked: {
                            rotate(-90);
                        }
                    }
                }
                Item {
                    Layout.preferredHeight: buttonSize
                    Layout.preferredWidth: buttonSize
                    Layout.row: 1
                    Layout.column: 1
                    SketchPaletteButton {
                        anchors.fill: parent
                        nonSelectTypeButton: true
                        imageSource: "../images/rotate_right.png"
                        enabled: rotationAvailable
                        color: rotationAvailable ? "white" : "grey"

                        onClicked: {
                            rotate(90);
                        }
                    }
                }
                Item {
                    Layout.row: 1
                    Layout.column: 2
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
                Rectangle {
                    Layout.row: 1
                    Layout.column: 4
                    Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    color: kSeparatorColor
                }
                Item {
                    Layout.preferredHeight: buttonSize
                    Layout.preferredWidth: buttonSize

                    Layout.row: 1
                    Layout.column: 5

                    SketchPaletteButton {
                        anchors.fill: parent

                        visible: showSmart
                        imageSource: "images/smart.png"
                        selected: _smartMode
                        color: selectedColor

                        onClicked: {
                            _smartMode = !_smartMode;
                        }

                        onPressAndHold: {
                            manualMode = !manualMode;
                            _smartMode = false;
                        }
                    }
                }

                Rectangle {
                    Layout.columnSpan: colorRepeater.model.count //widthRepeater.model.length
                    Layout.fillWidth: true
                    Layout.row: 2

                    height: 1 * AppFramework.displayScaleFactor
                    color: kSeparatorColor
                }

                Repeater {
                    id: textRepeater

                    model: textScales

                    SketchPaletteButton {
                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: buttonSize
                        Layout.row: 3
                        Layout.column: index

                        color: selectedColor
                        textScale: textRepeater.model[index]
                        selected: textScale === _selectedTextScale && _textMode

                        onClicked: {
                            if (selected) {
                                _textMode = false;
                            } else {
                                _selectedTextScale = textRepeater.model[index];
                                _textMode = true;
                            }
                        }
                    }
                }

//                SketchPaletteButton {
//                    Layout.preferredWidth: buttonSize
//                    Layout.preferredHeight: buttonSize
//                    Layout.row: 2
//                    Layout.column: lineWidths.length + 1

//                    visible: showSmart
//                    imageSource: "images/smart.png"
//                    selected: _smartMode
//                    color: selectedColor

//                    onClicked: {
//                        _smartMode = !_smartMode;
//                    }

//                    onPressAndHold: {
//                        manualMode = !manualMode;
//                        _smartMode = false;
//                    }
//                }

                Rectangle {
                    Layout.columnSpan: colorRepeater.model.count //widthRepeater.model.length
                    Layout.fillWidth: true
                    Layout.row: 4

                    visible: !_smartMode && manualMode
                    height: 1 * AppFramework.displayScaleFactor
                    color: kSeparatorColor
                }

                Repeater {
                    id: arrowRepeater

                    model: lineWidths

                    SketchPaletteButton {
                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: buttonSize
                        Layout.row: 5
                        Layout.column: index

                        visible: !_smartMode && manualMode
                        color: selectedColor
                        lineWidth: widthRepeater.model[index]
                        selected: lineWidth === _selectedWidth && arrowMode
                        showArrow: true

                        onClicked: {
                            _selectedWidth = widthRepeater.model[index];
                            _arrowMode = true;
                        }
                    }
                }

                Rectangle {
                    Layout.columnSpan: colorRepeater.model.count //widthRepeater.model.length
                    Layout.fillWidth: true
                    Layout.row: 6

                    height: 1 * AppFramework.displayScaleFactor
                    color: kSeparatorColor
                }

                Repeater {
                    id: widthRepeater

                    model: lineWidths

                    SketchPaletteButton {
                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: buttonSize
                        Layout.row: 7
                        Layout.column: index

                        color: selectedColor
                        lineWidth: widthRepeater.model[index]
                        selected: lineWidth === _selectedWidth && palette.lineMode

                        onClicked: {
                            if (smartMode) {
                                _selectedWidth = widthRepeater.model[index];
                            } else {
                                _selectedWidth = widthRepeater.model[index];
                                _arrowMode = false;
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.columnSpan: colorRepeater.model.count // 20
                    Layout.fillWidth: true
                    Layout.row: 8

                    height: 1 * AppFramework.displayScaleFactor
                    color: kSeparatorColor
                }

                Repeater {
                    id: colorRepeater

                    model: colors
                    
                    SketchPaletteButton {
                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: buttonSize
                        Layout.row: 9
                        Layout.column: index

                        color: colorRepeater.model.get(index).color
                        selected: color === selectedColor

                        onClicked: {
                            selectedColor = colorRepeater.model.get(index).color;
                        }

                        onPressAndHold: {
                            colorDialog.index = index;
                            colorDialog.currentColor = colorRepeater.model.get(index).color;
                            colorDialog.open();
                        }
                    }
                }
            }
        }

        ColorDialog {
            id: colorDialog

            property int index

            onAccepted: {
                selectedColor = currentColor;
                colors.setProperty(index, "color", currentColor.toString());
            }
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: colors
    }

    //--------------------------------------------------------------------------

    function show() {
        active = true;
    }

    //--------------------------------------------------------------------------

    function hide() {
        active = false;
    }

    //--------------------------------------------------------------------------

    function saveSettings() {
        if (!settings) {
            return;
        }

        console.log("Save sketch settings");

        settings.setValue(kKeyPenColor, selectedColor);
        settings.setValue(kKeyPenWidth, _selectedWidth);
        settings.setValue(kKeyTextScale, _selectedTextScale);
        settings.setValue(kKeySmartMode, _smartMode);
        settings.setValue(kKeyTextMode, _textMode);
        settings.setValue(kKeyArrowMode, _arrowMode);
        settings.setValue(kKeyManualMode, manualMode);

        for (var i = 0; i < colors.count; i++) {
            settings.setValue(kKeyColor.arg(i), colors.get(i).color);
        }
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        if (!settings) {
            return;
        }

        console.log("Read sketch settings");

        selectedColor = settings.colorValue(kKeyPenColor, "red");
        _selectedWidth = settings.numberValue(kKeyPenWidth, 3);
        _selectedTextScale = settings.numberValue(kKeyTextScale, 1.5);
        _smartMode = settings.boolValue(kKeySmartMode, true);
        _textMode = settings.boolValue(kKeyTextMode, true);
        _arrowMode = settings.boolValue(kKeyArrowMode, false);
        manualMode = settings.boolValue(kKeyManualMode, true);

        for (var i = 0; i < colors.count; i++) {
            var color = settings.colorValue(kKeyColor.arg(i), kDefaultColors[i]);
            colors.setProperty(i, "color", color.toString());
        }
    }

    //--------------------------------------------------------------------------
}
