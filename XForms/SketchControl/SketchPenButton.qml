/* Copyright 2017 Esri
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
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: control

    implicitWidth: 35 * AppFramework.displayScaleFactor
    implicitHeight: 35 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    property SketchCanvas canvas
    property bool showSmart: true

    readonly property color color : canvas.penColor
    readonly property real lineWidth: canvas.penWidth
    readonly property real textScale: canvas.textScale
    readonly property bool textMode: canvas.textMode
    readonly property bool lineMode: canvas.lineMode
    readonly property bool arrowMode: canvas.arrowMode
    readonly property bool smartMode: canvas.smartMode

    //--------------------------------------------------------------------------

    signal clicked()

    //--------------------------------------------------------------------------

    onClicked: {
        canvas.textInput.hide();
        canvas.palette.show();
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: lineRect

        anchors {
            left: parent.left
            bottom: parent.bottom
        }

        height: lineWidth * AppFramework.displayScaleFactor
        width: parent.width / (showSmart ? 2 : 1)

        color: control.color
        visible: lineMode || arrowMode
    }

    //--------------------------------------------------------------------------

    Image {
        id: image
        
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            bottomMargin: 5 * AppFramework.displayScaleFactor
        }

        width: height

        source: "images/pencil.png"
        visible: false
    }
    
    ColorOverlay {
        anchors.fill: image
        source: image
        color: control.color
    }

    //--------------------------------------------------------------------------

    Image {
        id: smartImage

        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        width: parent.width * 0.4
        height: width

        source: "images/smart.png"
        visible: false
    }

    ColorOverlay {
        anchors.fill: smartImage
        visible: showSmart && smartMode
        source: smartImage
        color: control.color
    }

    //--------------------------------------------------------------------------

    Text {
        anchors {
            left: parent.left
            top: parent.top
        }

        width: parent.width * 0.4
        height: width

        visible: textMode
        color: control.color
        text: "A"
        font.pixelSize: height
    }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            control.clicked();
        }
    }

    //--------------------------------------------------------------------------

}
