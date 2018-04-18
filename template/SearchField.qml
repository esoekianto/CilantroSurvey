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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

TextField {
    id: searchField

    readonly property bool clearVisible: text > "" && !readOnly
    property alias editTimeout: editTimer.interval
    property string __text

    signal pressAndHold()
    signal cleared()

    //--------------------------------------------------------------------------

    placeholderText: qsTr("Search")

    style: TextFieldStyle {
        renderType: Text.QtRendering
        textColor: "black"
        font {
            pointSize: 18 * app.textScaleFactor
            family: app.fontFamily
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (clearVisible) {
            clearButtonLoader.active = true;
        }

        __panel.leftMargin = searchButton.width + searchButton.anchors.margins * 1.5;
    }

    //--------------------------------------------------------------------------

    ImageButton {
        id: searchButton

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 2
        }

        width: height
        source: "images/search.png"
        glowColor: "transparent"
        hoverColor: "transparent"
        pressedColor: "transparent"

        onClicked: {
            textChanged();
        }

        onPressAndHold: {
            searchField.pressAndHold();
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: clearButtonLoader

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 2
        }

        visible: clearVisible
        width: height
        active: false

        sourceComponent: ImageButton {
            source: "images/clear.png"
            glowColor: "transparent"
            hoverColor: "transparent"
            pressedColor: "transparent"

            onClicked: {
                clear();
            }
        }

        onVisibleChanged: {
            if (parent.__panel) {
                parent.__panel.rightMargin = visible ? clearButtonLoader.width + clearButtonLoader.anchors.margins * 1.5 : 0;
            }
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        __text = "";
        text = "";
        cleared();
    }

    //--------------------------------------------------------------------------

    Timer {
         id: editTimer

         interval: 500
         running: false
         repeat: false

         onTriggered: {
             if (text !== __text) {
                 __text = text;
                 editingFinished();
             }
         }
     }

    onCleared: {
        editTimer.stop();
        editingFinished();
    }

    //--------------------------------------------------------------------------

    onLengthChanged: {
        if (length > 0 && !readOnly) {
            clearButtonLoader.active = true;
        }
    }

    onTextChanged: {
        if (text > "") {
            if (editTimeout) {
                editTimer.restart();
            }
        } else {
            editTimer.stop();
            editingFinished();
        }
    }

    onEditingFinished: {
        editTimer.stop();
    }

    //--------------------------------------------------------------------------
}
