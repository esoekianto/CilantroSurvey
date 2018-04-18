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

import ArcGIS.AppFramework 1.0


Item {
    id: textInput

    //--------------------------------------------------------------------------

    property double angle
    property string alignment
    property string textBaseline
    property color textColor
    property real textScale
    property alias font: textField.font
    property real maximumWidth

    //--------------------------------------------------------------------------

    visible: false

    //--------------------------------------------------------------------------

    TextField {
        id: textField

        //implicitWidth: 100 * AppFramework.displayScaleFactor * textScale

        transformOrigin: Item.Center
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: - font.pixelSize / 2
        }

        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        selectByMouse: true

        //----------------------------------------------------------------------

        color: textColor

        font {
            pixelSize: 15 * AppFramework.displayScaleFactor * textScale
        }

        background: Rectangle {
            color: "transparent"

            border {
                width: (textField.focus ? 2 : 1) * AppFramework.displayScaleFactor
                color: textField.focus ? textColor : "lightgrey"
            }

            opacity: 0.5
        }

        //--------------------------------------------------------------------------

        Keys.onEscapePressed: {
            hide();
        }

        onEditingFinished: {
            finish();
        }
    }

    //--------------------------------------------------------------------------

    function finish() {
        if (!visible) {
            return;
        }

        hide();

        var text = textField.text.trim();

        if (text.length > 0) {
            var sketch = addTextSketch(
                        textInput.x,
                        textInput.y,// - y, // - 3 * AppFramework.displayScaleFactor,
                        text,
                        textColor,
                        angle,
                        alignment,
                        textBaseline,
                        font,
                        maximumWidth,
                        2);
        }
    }

    //--------------------------------------------------------------------------

    function show(x, y, color, angle, alignment, baseline, maximumWidth) {
        textField.text = "";

        console.log("show textInput x:", x, "y:", y, "angle:", angle, "maximumWidth:", maximumWidth);

        var r = textInput.parent.width - x;
        var w = Math.min(r, x);

        if (!maximumWidth) {
            maximumWidth = textInput.parent.width * 0.95;
            textInput.maximumWidth = Math.min(maximumWidth, w * 2);
        } else {
            textInput.maximumWidth = maximumWidth;
        }

        textField.width = Math.min(maximumWidth, w * 2);
        textInput.x = x;
        textInput.y = y;
        textInput.angle = angle === undefined ? 0 : angle;
        textInput.alignment = alignment > "" ? alignment : "";
        textInput.textBaseline = baseline > "" ? baseline : "";
        textInput.textColor = color === undefined ? "black" : color;

        //console.log("textInput:", textField.width, "r:", r, "x:", x, "pw:", textInput.parent.width);

        visible = true;
        textField.forceActiveFocus();
    }

    //--------------------------------------------------------------------------

    function move(x, y) {
        var r = textInput.parent.width - x;
        var w = Math.min(r, x);

        maximumWidth = textInput.parent.width * 0.95;
        textInput.maximumWidth = Math.min(maximumWidth, w * 2);
        textField.width = Math.min(maximumWidth, w * 2);
        textInput.x = x;
        textInput.y = y;
    }

    //--------------------------------------------------------------------------

    function hide() {
        visible = false;
    }
    
    //--------------------------------------------------------------------------
}
