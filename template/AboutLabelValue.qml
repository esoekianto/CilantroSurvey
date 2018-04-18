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

import QtQuick 2.0

Item {
    property alias label: labelText.text
    property alias value: valueText.text
    property alias font: valueText.font
    property alias color: labelText.color
    property alias valueColor: valueText.color

    signal clicked
    signal pressAndHold

    id: labelValue
    width: parent.width
    height: labelText.height

    AppText {
        id: labelText
        font {
            pointSize: valueText.font.pointSize
            bold: !valueText.font.bold
        }
        text: "Label"
        anchors {
            left: parent.left
            top: parent.top
        }
    }

    AppText {
        id: valueText
        font {
            pointSize: 9
            bold: true
        }
        color: labelText.color

        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 1
        text: "-"
        anchors {
            left: labelText.right
            leftMargin: 5
            top: labelText.top
            right: parent.right
        }

        onLinkActivated: {
            Qt.openUrlExternally(link);
        }
    }

    MouseArea {
        anchors.fill: labelText

        onClicked: {
            labelValue.clicked();
        }

        onPressAndHold: {
            labelValue.pressAndHold();
        }
    }
}
