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

Rectangle {
    id: control

    property int count
    property alias text: countText

    readonly property color firebrick: "#b22222"
    readonly property color red: "#e71b00"
    readonly property color amber: "#ff7e00"
    readonly property color blue: "#3e78b3"
    readonly property color green: "#56ad89"
    readonly property color cyan: "#00aeef"
    property color textColor: "white"
    property real textSize: 14
    property color borderColor: "white"

    signal clicked();


    height: countText.paintedHeight + 8
    width: Math.max(height, countText.paintedWidth + 8)
    visible: count > 0
    radius: height / 2
    color: red

    border {
        color: borderColor
        width: 1
    }

    Text {
        id: countText

        anchors.centerIn: parent

        text: count.toString();
        color: textColor
        font {
            pointSize: textSize
            bold: true
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            control.clicked();
        }
    }
}

