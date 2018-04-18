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
import QtQuick.Layouts 1.1

Rectangle {
    id: button

    property CalculatorALU alu: parent.alu

    property string operation
    property alias text: buttonText.text
    property color textColor: "white"
    property color disabledTextColor: "grey"

    readonly property bool selected: (alu && operation > "") ? alu.currentOperation == operation : false

    signal clicked

    //--------------------------------------------------------------------------

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.maximumHeight: parent.cellHeight

    implicitWidth: 50
    implicitHeight: 50

    //--------------------------------------------------------------------------

    border {
        width: selected ? 3 : 1
        color: selected ? "black" : "lightgrey"
    }

    color: "#aab1bb"
    radius: height / 2 //* 0.16

    Rectangle {
        id: shade

        anchors.fill: parent
        radius: parent.radius
        color: "black"
        opacity: 0
    }

    Text {
        id: buttonText

        anchors {
            centerIn: parent
            verticalCenterOffset: -paintedHeight * 0.05
        }

        font {
            pixelSize: Math.min(parent.width, parent.height) * 0.5
        }

        style: Text.Raised
        color: button.enabled ? textColor : disabledTextColor
        styleColor: "grey"
        smooth: true
        text: operation
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        onClicked: {
            alu.doOperation(operation);
            button.clicked()
        }
    }

    states: State {
        name: "pressed"
        when: mouseArea.pressed

        PropertyChanges {
            target: shade
            opacity: 0.4
        }
    }
}
