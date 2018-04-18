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
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Rectangle {
    id: busyPanel

    property alias text: text.text
    property string fontFamily: app.fontFamily
    
    anchors.fill: parent
    
    color: "#80000000"
    
    Rectangle {
        anchors {
            fill: contentColumn
            topMargin: -10 * AppFramework.displayScaleFactor
            bottomMargin: -10 * AppFramework.displayScaleFactor
        }
        
        color: "white"
        radius: 5
        border {
            width: 1
            color: "lightgray"
        }
    }
    
    ColumnLayout {
        id: contentColumn
        
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 15 * AppFramework.displayScaleFactor
        }
        
        spacing: 5 * AppFramework.displayScaleFactor
        
        Text {
            id: text

            Layout.fillWidth: true
            
            color: "black"
            font {
                pointSize: 20
                bold: true
                family: fontFamily
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }
        
        AppBusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            
            running: busyPanel.visible
        }
    }
    
    MouseArea {
        anchors.fill: parent
        
        onClicked: {}
        onWheel: {}
    }
}
