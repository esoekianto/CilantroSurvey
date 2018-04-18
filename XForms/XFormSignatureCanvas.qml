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
import QtQuick.Controls 1.4
import QtQuick.Window 2.0

import ArcGIS.AppFramework 1.0

Rectangle {
    id: sketch

    property int xpos
    property int ypos
    property color penColor: "black"
    property int penWidth: 1
    
    property var imageUrl
    property var polyline
    property bool isNull: !Array.isArray(polyline) && !imageUrl

    property bool useBackgroundImageObject: true

    readonly property string kTempFileName: "$$canvas-temp.jpg"

    property FileFolder workFolder

    //--------------------------------------------------------------------------

    signal penReleased()

    //--------------------------------------------------------------------------

    color: "white"

    Canvas {
        id: canvas

        anchors.fill: parent

        Component.onDestruction: {
            console.log("Destroying sketch canvas")
            if (imageUrl && isImageLoaded(imageUrl)) {
                console.log("Unloading:", imageUrl);
                unloadImage(imageUrl);
            }
        }
        
        onPaint: {
            var ctx = getContext('2d');


            drawBackground(ctx);

            if (polyline && polyline.length > 1) {

                ctx.strokeStyle = penColor;
                ctx.lineWidth = penWidth * AppFramework.displayScaleFactor;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                ctx.beginPath();
                
                for (var i = 0; i < polyline.length; i++) {
                    var point = polyline[i];
                    if (point.x < 0 && point.y < 0) {
                        ctx.moveTo(-point.x, -point.y);
                    } else {
                        ctx.lineTo(point.x, point.y);
                    }
                }
                
                ctx.stroke();
            }
        }

        function drawBackground(ctx) {
            ctx.fillStyle = sketch.color;
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            if (imageUrl && isImageLoaded(imageUrl)) {
                ctx.drawImage(imageUrl, 0, 0);
            }

            if (!backgroundImageObject.empty) {
                ctx.drawImage(backgroundImageObject.url, 0, 0);
            }

            if (!pasteImageObject.empty) {
                ctx.drawImage(pasteImageObject.url, pasteImageObject.offsetX, pasteImageObject.offsetY);
            }
        }
        
        function addVertex(x, y) {
            
//            console.log("addVertex", x, y);
            
            if (!Array.isArray(polyline)) {
                polyline = [];
            }
            
            polyline.push({
                              "x": x,
                              "y": y
                          });
            
            canvas.requestPaint();
        }

        onImageLoaded: {
            console.log("onImageLoaded:", imageUrl);
            requestPaint();
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: parent.height * 0.333
                margins: parent.width * 0.05
            }

            color: "#40808080"
            height: 1 * AppFramework.displayScaleFactor
        }

        MouseArea {
            anchors.fill: parent

            preventStealing: true

            onPressed: {
                canvas.addVertex(-mouseX, -mouseY);
            }

            onReleased: {
                penReleased();
            }

            onPositionChanged: {
                canvas.addVertex(mouseX, mouseY);
            }

            onWheel: {
            }

            onPressAndHold: {
            }
        }
    }

    ImageObject {
        id: backgroundImageObject
    }

    //--------------------------------------------------------------------------

    function clear(fill) {
        if (imageUrl) {
            if (canvas.isImageLoaded(imageUrl)) {
                canvas.unloadImage(imageUrl);
            }
            imageUrl = undefined;
        }

        if (fill) {
            backgroundImageObject.fill("white");
        } else {
            backgroundImageObject.clear();
        }
        pasteImageObject.clear();
        clearVectors();

        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function clearVectors() {
        polyline = null;
    }

    //--------------------------------------------------------------------------

    function load(path) {

        imageUrl = AppFramework.resolvedPathUrl(path);

        if (useBackgroundImageObject) {
            console.log("Loading background image:", imageUrl);

            backgroundImageObject.load(imageUrl);

            canvas.requestPaint();
            return;
        }

        console.log("Loading canvas image:", imageUrl, canvas.isImageLoaded(imageUrl));

        if (canvas.isImageLoaded(imageUrl)) {
            console.log("Unloading:", imageUrl);
            canvas.unloadImage(imageUrl);
        }

        canvas.loadImage(imageUrl);

        return canvas.isImageLoaded(imageUrl);
    }

    //--------------------------------------------------------------------------

    function loadUrl(url) {

        console.log("Loading canvas url:", url, canvas.isImageLoaded(url));

        if (canvas.isImageLoaded(imageUrl)) {
            canvas.unloadImage(imageUrl);
        }

        imageUrl = url;

        canvas.loadImage(imageUrl);
    }

    //--------------------------------------------------------------------------

    function save(path) {
        console.log("Saving canvas:", path);

        var result = canvas.save(path);

        console.log("Canvas saved:", result);

        return result;
    }

    //--------------------------------------------------------------------------

    function rasterize() {
        if (!useBackgroundImageObject) {
            console.error("Unable to rasterize: useBackgroundImageObject not true");
            return;
        }

        if (!workFolder) {
            console.error("Unable to rasterize: workFolder is null");
            return;
        }

        var filePath = workFolder.filePath(kTempFileName, filePath);

        console.log("Rasterizing canvas:", filePath);

        if (!save(filePath)) {
            console.error("Error saving canvas to:", filePath);
            return;
        }

        backgroundImageObject.load(filePath);
        pasteImageObject.clear();
        clearVectors();

        workFolder.removeFile(kTempFileName);
        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function pasteImage(image) {
        console.log("pasteImage:", image);

        if (!pasteImageObject.load(image)) {
            console.error("Failed to load:", image);
            return;
        }

        var canvasRatio = canvas.width / canvas.height;
        var imageRatio = pasteImageObject.width / pasteImageObject.height;

        console.log("canvasRatio:", canvasRatio, "imageRatio:", imageRatio);

        var scaleFactor = 1;

        if (Qt.platform.os === "osx" || Qt.platform.os === "ios") {
            scaleFactor = Screen.devicePixelRatio;
            console.warn("Using Qt canvas bug workaround scaleFactor:", scaleFactor);
        }

        if (imageRatio < canvasRatio) {
            pasteImageObject.scaleToHeight(canvas.height * scaleFactor);
        } else {
            pasteImageObject.scaleToWidth(canvas.width * scaleFactor);
        }

        pasteImageObject.offsetX = (canvas.width - pasteImageObject.width / scaleFactor) / 2;
        pasteImageObject.offsetY = (canvas.height - pasteImageObject.height / scaleFactor) / 2;

        canvas.requestPaint();
    }

    ImageObject {
        id: pasteImageObject

        property int offsetX: 0
        property int offsetY: 0
    }

    //--------------------------------------------------------------------------
}
