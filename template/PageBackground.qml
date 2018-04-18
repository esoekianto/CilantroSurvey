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

import QtQuick 2.3

import ArcGIS.AppFramework 1.0

Rectangle {
    color: app.backgroundColor

    Image {
        anchors.fill: parent
        source: app.backgroundImage
        fillMode: Image.Tile
    }

    Rectangle {
        anchors.fill: parent
        color: app.info.propertyValue("startForegroundColor", "transparent")
    }
}
