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

import QtQuick 2.7

import ArcGIS.AppFramework 1.0

Rectangle {
    id: progressBar

    property real minimumValue: 0
    property real maximumValue: 1
    property real value: 0

    property alias fillColor: fill.color
    
    //--------------------------------------------------------------------------

    implicitHeight: 5 * AppFramework.displayScaleFactor
    implicitWidth: 100 * AppFramework.displayScaleFactor
    
    color: "lightgrey"

    border {
        width: 1
        color: "darkgrey"
    }

    radius: 2 * AppFramework.displayScaleFactor
    
    //--------------------------------------------------------------------------

    Rectangle {
        id: fill

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 1
        }
        
        radius: progressBar.radius
        width: Math.max(Math.min(progressBar.value, progressBar.maximumValue), progressBar.minimumValue) * (progressBar.width - progressBar.anchors.margins) / progressBar.maximumValue;

        color: "#00b2ff"
    }

    //--------------------------------------------------------------------------
}
