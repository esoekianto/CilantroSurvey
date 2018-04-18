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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Rectangle {
    id: button

    property int key
    property string text: String.fromCharCode(key)
    property alias textColor: buttonText.color

    readonly property bool isNullKey: key === 0

    //--------------------------------------------------------------------------

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.maximumHeight: parent.cellHeight

    implicitWidth: 50
    implicitHeight: 50

    //--------------------------------------------------------------------------

    border {
        width: isNullKey ? 0 : 1
        color: xform.style.keyBorderColor
    }

    radius: height / 2 //* 0.16
    enabled: !isNullKey
    color: isNullKey ? "transparent" : xform.style.keyColor

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
            //verticalCenterOffset: -paintedHeight * 0.05
        }

        font {
            pixelSize: Math.min(parent.width, parent.height) * 0.7
            family: xform.style.keyFontFamily
        }

        style: Text.Raised
        color: xform.style.keyTextColor
        styleColor: xform.style.keyStyleColor
        text: button.text
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        onClicked: {
            button.parent.keyPressed(key, text);
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
