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
import QtGraphicalEffects 1.0

Item {
    property alias source: image.source
    property alias color: colorOverlay.color

    width: parent.width/5
    height: width

    Image {
        id: image

        anchors.fill: parent

        fillMode: Image.PreserveAspectFit
        source: "images/cornerMarker.png"
    }

    ColorOverlay {
        id: colorOverlay
        anchors.fill: parent

        source: image
        color: "red"
    }
}
