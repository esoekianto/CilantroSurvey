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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import "SketchLib.js" as SketchLib

Canvas {
    id: canvas

    //--------------------------------------------------------------------------

    property Settings settings

    property int xpos
    property int ypos

    property alias palette: sketchPalette
    property alias textInput: textInput
    property alias fontFamily: textInput.font.family

    property alias penColor: sketchPalette.selectedColor
    property alias penWidth: sketchPalette._selectedWidth
    property alias textScale: sketchPalette.selectedTextScale
    readonly property alias textMode: sketchPalette.textMode
    readonly property alias lineMode: sketchPalette.lineMode
    readonly property alias arrowMode: sketchPalette.arrowMode

    property var sketchPoints
    property var arrowSketch
    property bool sketchText: false // Text input is associated with a sketch
    property bool isNull: true
    property alias smartMode: sketchPalette.smartMode
    property bool debug

    property real arrowHeadLength: 25 * AppFramework.displayScaleFactor
    property real minimumLineLength: arrowHeadLength * 1.1
    property real minimumSketchSize: (10 + penWidth / 2) * AppFramework.displayScaleFactor

    property var sketches: []

    property var paintBackground

    property alias message: messageText.text

    property alias unistroke: unistroke

    signal rotate(int rotation)

    //--------------------------------------------------------------------------

    onPaint: {
        var ctx = getContext('2d');
        
        if (mouseArea.pressed) {
            if (arrowMode) {
                repaint(ctx);
                if (arrowSketch.length >= minimumLineLength ) {
                    SketchLib.drawArrowSketch(ctx, arrowSketch);
                }
            } else if (lineMode) {

                ctx.save();


                ctx.fillStyle = penColor;
                ctx.strokeStyle = penColor;
                ctx.lineWidth = penWidth * AppFramework.displayScaleFactor;
                ctx.lineCap = "round";

                if (smartMode) {
                    ctx.beginPath();
                    var s = penWidth * AppFramework.displayScaleFactor * 2;
                    var x = sketchPoints[0].x - s / 2;
                    var y = sketchPoints[0].y - s / 2;
                    ctx.ellipse(x, y, s, s);
                    ctx.fill();
                }

                SketchLib.drawLine(ctx, sketchPoints);
                ctx.restore();
            }
        } else {
            repaint(ctx);
        }
    }

    function repaint(ctx) {
        ctx.fillStyle = "white";
        ctx.fillRect(0, 0, width, height);

        if (paintBackground) {
            ctx.save();
            paintBackground(ctx);
            ctx.restore();
        }

        if (debug) {
            ctx.save();
            ctx.strokeStyle = Qt.rgba(0, 0, 1, 1);
            ctx.lineWidth = penWidth * AppFramework.displayScaleFactor;
            ctx.lineCap = "round";

            SketchLib.drawSmoothLine(ctx, sketchPoints);
            ctx.restore();
        }

        SketchLib.drawSketches(ctx, sketches);
    }
    
    //--------------------------------------------------------------------------

    Text {
        id: messageText

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        visible: debug
    }

    //--------------------------------------------------------------------------

    MouseArea {
        id: mouseArea
        
        anchors.fill: parent
        
        onPressed: {
            textInput.finish();
            sketchPoints = undefined;

            var sketch;

            if (arrowMode) {
                sketch = SketchLib.beginArrowSketch(mouseX, mouseY);

                sketch.headLength = arrowHeadLength;
                sketch.headAngle = 30;
                sketch.lineWidth = penWidth * AppFramework.displayScaleFactor;
                sketch.lineColor = penColor.toString();
            } else if (textMode && !smartMode && !lineMode) {
                textInput.show(mouseX, mouseY, penColor);
            } else if (lineMode) {
                addSketchPoint(mouseX, mouseY);
            } else {
                textInput.finish();
            }

            arrowSketch = sketch;
        }
        
        onReleased: {
            var sketch;

            if (smartMode) {
                sketch = unistroke.recognize(sketchPoints);

                if (debug) {
                    message = "%1 %2%".arg(unistroke.result.Name).arg(Math.round(unistroke.result.Score * 100));
                }

                if (sketch) {
                    addSketch(sketch);

                    sketch.lineWidth = penWidth;
                    sketch.lineColor = penColor.toString();

                    if (textMode) {
                        sketchText = true;
                        textInput.show(
                                    sketch.center.x,
                                    sketch.center.y,
                                    sketch.lineColor,
                                    sketch.a - 90,
                                    "center",
                                    "bottom",
                                    sketch.width * 0.8);
                    }
                }
            }
            
            if (smartMode && !sketch) {
                sketch = SketchLib.detectSketch(sketchPoints);
                
                if (sketch && sketch.type === "line") {
                    var good = sketch.q <= 0.05 && sketch.length >= minimumLineLength;
                    
                    sketch.type = "arrow";
                    sketch.headLength = arrowHeadLength;
                    sketch.headAngle = 30;
                    sketch.lineWidth = penWidth * AppFramework.displayScaleFactor;
                    sketch.lineColor = (!good ? Qt.rgba(1, 0, 0, 1) : penColor).toString();
                    
                    if (good || debug) {
                        addSketch(sketch);
                    } else {
                        sketch = undefined;
                    }
                    
                    if (good && textMode) {
                        sketchText = true;
                        textInput.show(
                                    (sketch.x1 + sketch.x2) / 2,
                                    (sketch.y1 + sketch.y2) / 2,
                                    sketch.lineColor,
                                    sketch.a - 90,
                                    "center",
                                    "bottom",
                                    sketch.length * 0.8);
                    }
                }
            } else if (arrowMode) {
                SketchLib.updateArrowSketch(arrowSketch, mouseX, mouseY);

                if (arrowSketch.length >= minimumLineLength ) {
                    sketch = arrowSketch;
                    addSketch(sketch);

                    if (textMode) {
                        textInput.show(
                                    (sketch.x1 + sketch.x2) / 2,
                                    (sketch.y1 + sketch.y2) / 2,
                                    sketch.lineColor,
                                    sketch.a - 90,
                                    "center",
                                    "bottom",
                                    sketch.length * 0.8);
                    }
                }
            }
            
            if (!sketch) {
                if (Array.isArray(sketchPoints)) {
                    var extent = SketchLib.extent(sketchPoints);

                    if (penWidth > 0 && extent.width >= minimumSketchSize && extent.height >= minimumSketchSize) {
                        sketch = addPolylineSketch(sketchPoints);
                        if (textMode) {
                            console.log("T1:", sketchText);
                            sketchText = true;
                            textInput.show(
                                        sketch.extent.center.x,
                                        sketch.extent.center.y,
                                        sketch.lineColor,
                                        0,
                                        "center",
                                        "middle",
                                        sketch.extent.width);
                        }
                    } else if ((textMode || smartMode) && !sketchText) {
                        requestPaint();
                        console.log("T2:", sketchText);
                        textInput.show(
                                    extent.center.x,
                                    extent.center.y,
                                    penColor);
                    } else {
                        sketchText = false;
                    }
                } else {
                    requestPaint();
                    if ((textMode || smartMode) && !sketchText) {
                        console.log("T3:", sketchText);
                        textInput.show(
                                    mouseX,
                                    mouseY,
                                    penColor);
                    } else {
                        sketchText = false;
                    }
                }
            }
        }
        
        onPressAndHold: {
            //textInput.show(mouseX, mouseY);
        }
        
        onPositionChanged: {
            if (arrowMode) {
                SketchLib.updateArrowSketch(arrowSketch, mouseX, mouseY);
                canvas.requestPaint();
            } else if (lineMode) {
                addSketchPoint(mouseX, mouseY);
            } else if (textInput.visible) {
                textInput.move(mouseX, mouseY);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    SketchTextInput {
        id: textInput
        textScale: canvas.textScale
    }

    SketchPalette {
        id: sketchPalette

        settings: canvas.settings
        onRotate: {
            canvas.rotate(rotation);
        }
    }

    //--------------------------------------------------------------------------

    Unistroke {
        id: unistroke

        onActionStroke: {
            switch (action) {
            case "delete":
                deleteLastSketch();
                break;

            default:
                console.warn("Unhandled action:", action);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    function addSketchPoint(x, y) {

        // console.log("addSketchPoint:", x, y);

        var point = {
            "x": x,
            "y": y
        };

        if (!Array.isArray(sketchPoints)) {
            sketchPoints = [point];
            return;
        }

        if (SketchLib.eq(point, sketchPoints[sketchPoints.length - 1])) {
            console.log("Dup point:", JSON.stringify(point), JSON.stringify(sketchPoints[sketchPoints.length - 1]));
            return;
        }

        sketchPoints.push(point);

        if (sketchPoints.length > 0) {
            canvas.requestPaint();
        }
    }

    //--------------------------------------------------------------------------

    function addTextSketch(x, y, text, color, angle, alignment, baseline, font, maximumWidth, shadowBlur) {

        var sketch = {
            type: "text",
            x: x,
            y: y,
            text: text,
            color: color.toString(),
            angle: angle,
            height: font.pixelSize + 3 * AppFramework.displayScaleFactor,
            maximumWidth: maximumWidth,
            font: SketchLib.toFontString(font),
            alignment: alignment > "" ? alignment : "center",
                                        baseline: baseline > "" ? baseline : "middle",

            shadowBlur: shadowBlur,
        };

        addSketch(sketch);

        return sketch;
    }

    //--------------------------------------------------------------------------

    function addPolylineSketch(points) {
        var sketch = {
            type: "polyline",
            points: points,
            lineColor: penColor.toString(),
            lineWidth: penWidth * AppFramework.displayScaleFactor,
            extent: SketchLib.extent(points)
        };

        addSketch(sketch);

        return sketch;
    }

    //--------------------------------------------------------------------------

    function addSketch(sketch) {
        if (!sketch) {
            console.warn("Adding empty skectch");
            return;
        }

        if (sketch.type === "polyline") {
            console.log("addSketch:", JSON.stringify(sketch.type, undefined, 2));
        } else {
            console.log("addSketch:", JSON.stringify(sketch, undefined, 2));
        }

        sketches.push(sketch);
        isNull = sketches.length < 1;
        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function addImageObject(imageObject) {
        var sketch = {
            type: "image",
            x: 0,
            y: 0,
            width: imageObject.width,
            height: imageObject.height,
            url: imageObject.url,
            fit: true
        }

        addSketch(sketch);
    }

    //--------------------------------------------------------------------------

    function clear() {
        textInput.hide();
        sketchPalette.hide();
        sketches = [];
        isNull = sketches.length < 1;
        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function deleteLastSketch() {
        if (sketches.length > 0) {
            sketches.pop();
            canvas.requestPaint();
        }

        isNull = sketches.length < 1;

        if (textInput.visible) {
            textInput.forceActiveFocus();
        }
    }

    //--------------------------------------------------------------------------
}
