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
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Rectangle {
    id: dropdownField

    property bool dropdownVisible: false
    property alias text: valueText.text
    property alias textField: valueText
    property int count: 1
    property int originalCount: 1

    signal cleared();

    anchors {
        left: parent.left
        right: parent.right
    }
    
    border {
        color: xform.style.inputBorderColor
        width: 1
    }
    
    height: valueLayout.height + padding * 2
    radius: height * 0.16
    color: xform.style.inputBackgroundColor
    
    RowLayout {
        id: valueLayout
        
        anchors {
            left: parent.left
            right: parent.right
            margins: padding
            verticalCenter: parent.verticalCenter
        }

        layoutDirection: xform.languageDirection
        
        XFormTextField {
            id: valueText
            
            Layout.fillWidth: true
            
            inputMethodHints: Qt.ImhNoPredictiveText
            enabled: originalCount > 0
            actionEnabled: true

            onAction: {
                text = "";
                cleared();
            }
        }

        Loader {
            Layout.preferredHeight: 15 * AppFramework.displayScaleFactor
            Layout.preferredWidth:  15 * AppFramework.displayScaleFactor

            sourceComponent: dropdownImageComponent
        }
    }

    Component {
        id: dropdownImageComponent
        Image {
            visible: originalCount > 0
            source: dropdownVisible ? "images/arrow-up.png" : "images/arrow-down.png"
            fillMode: Image.PreserveAspectFit
            
            MouseArea {
                anchors.fill: parent

                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: originalCount > 0

                onClicked: {
                    dropdownVisible = !dropdownVisible;
                }
            }
        }
    }
}
