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
import QtGraphicalEffects 1.0

Item {
    property alias source: image.source
    property alias radius: mask.radius
    property alias border: border.border
    property alias color: background.color

    implicitWidth: 100
    implicitHeight: 100
    
    Rectangle {
        id: background

        anchors.fill: parent

        color: "transparent"
        radius: mask.radius
    }

    Image {
        id: image
        
        anchors.fill: parent

        fillMode: Image.PreserveAspectFit
        visible: false
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
    }
    
    Rectangle {
        id: mask

        anchors.fill: parent

        color: "white"
        radius: height / 2
        clip: true
        visible: false
    }
    
    OpacityMask {
        anchors.fill: mask

        source: image
        maskSource: mask
    }

    Rectangle {
        id: border

        anchors.fill: parent

        color: "transparent"
        radius: mask.radius
        visible: border.width > 0
    }
}
