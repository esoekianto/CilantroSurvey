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

import "SketchControl"

Rectangle {
    id: sketch

    property var imageUrl
    property url defaultImageUrl
    property bool isNull: loaded && canvas.isNull && !imageUrl && pasteImageObject.empty
    property bool loaded: true
    property string lastLoadedImage

    property bool useImageObject: true

    readonly property string kTempFileName: "$$canvas-temp.jpg"

    property FileFolder workFolder
    property alias canvas: canvas

    //--------------------------------------------------------------------------

    signal penReleased()

    //--------------------------------------------------------------------------

    color: "white"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (defaultImageUrl > "")
        {
            console.log("Initialize sketch default:", defaultImageUrl);

            if (!defaultImageObject.load(defaultImageUrl)) {
                console.error("Failed to load:", defaultImageUrl);
                return;
            }

            canvas.requestPaint();
        }
    }

    //--------------------------------------------------------------------------

    SketchCanvas {
        id: canvas

        anchors.fill: parent

        settings: app.settings
        fontFamily: xform.style.fontFamily

        palette.rotationAvailable: lastLoadedImage > ""

        Component.onDestruction: {
            console.log("Destroying sketch canvas")
            if (imageUrl && isImageLoaded(imageUrl)) {
                console.log("Unloading:", imageUrl);
                unloadImage(imageUrl);
            }
        }

        onRotate: {
            rotateCurrentImage(rotation);
        }

        paintBackground: function (ctx) {

            ctx.fillStyle = sketch.color;
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            if (imageUrl && isImageLoaded(imageUrl)) {
                ctx.drawImage(imageUrl, 0, 0);
            }

            if (!defaultImageObject.empty && currentImageObject.empty && pasteImageObject.empty) {
                var rect = fitImageObject(defaultImageObject);
                ctx.drawImage(defaultImageObject.url, rect.x, rect.y, rect.width, rect.height);
            }

            if (!currentImageObject.empty) {
                ctx.drawImage(currentImageObject.url, 0, 0);
            }

            if (!pasteImageObject.empty) {
                sketch.setOffsets(pasteImageObject);
                ctx.drawImage(pasteImageObject.url, pasteImageObject.offsetX, pasteImageObject.offsetY);
            }
        }

        onImageLoaded: {
            console.log("onImageLoaded:", imageUrl);
            requestPaint();
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: defaultImageObject

        property int offsetX: 0
        property int offsetY: 0

    }

    ImageObject {
        id: currentImageObject
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
            currentImageObject.fill("white");
        } else {
            currentImageObject.clear();
        }
        pasteImageObject.clear();
        clearVectors();

        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function clearVectors() {
        canvas.clear();
    }

    //--------------------------------------------------------------------------

    function load(path) {

        imageUrl = AppFramework.resolvedPathUrl(path);

        if (useImageObject) {
            console.log("Loading current image:", imageUrl);

            if (currentImageObject.load(imageUrl)) {
                loaded = false;
            }

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
        if (!useImageObject) {
            console.error("Unable to rasterize: useImageObject not true");
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

        currentImageObject.load(filePath);
        pasteImageObject.clear();
        clearVectors();

        workFolder.removeFile(kTempFileName);
        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function pasteImage(image, rotation) {
        console.log("pasteImage:", image);

        if (!pasteImageObject.load(image)) {
            console.error("Failed to load:", image);
            return;
        }

        rotateImageObject(pasteImageObject, rotation);
        resizeImageObject(pasteImageObject);

        canvas.requestPaint();
    }

    function resetPastedImageObject(){
        pasteImageObject.currentRotation = 0;
    }

    ImageObject {
        id: pasteImageObject

        property int offsetX: 0
        property int offsetY: 0
        property int currentRotation: 0

    }

    //--------------------------------------------------------------------------

    function fitImageObject(imageObject) {
        // console.log("Fit:", imageObject.width, "x", imageObject.height, "=>", canvas.width, canvas.height);

        var canvasRatio = canvas.width / canvas.height;
        var imageRatio = imageObject.width / imageObject.height;

        var scaleFactor = 1;

        if (Qt.platform.os === "osx" || Qt.platform.os === "ios") {
            scaleFactor = Screen.devicePixelRatio;
        }

        var width;
        var height;

        if (imageRatio < canvasRatio) {
            height = canvas.height * scaleFactor;
            width = height * imageRatio;
        } else {
            width = canvas.width * scaleFactor;
            height = width / imageRatio;
        }

        var x = (canvas.width - width / scaleFactor) / 2;
        var y = (canvas.height - height / scaleFactor) / 2;

        return Qt.rect(x, y, width, height);
    }

    //--------------------------------------------------------------------------

    function rotateCurrentImage(rotation){
        pasteImageObject.clear();
        pasteImage(lastLoadedImage,rotation);
    }

    //--------------------------------------------------------------------------

    function rotateImageObject(imageObject, rotation) {

        if (rotation === undefined) {
            rotation = null;
        }

        var exif = imageObject.exifInfo;

        if (!exif) {
            return;
        }

        var orientation = rotation === null ? exif.imageValue(ExifInfo.ImageOrientation) : -1;

        if (!orientation) {
            return;
        }

        switch (orientation) {
            case -1:
                pasteImageObject.currentRotation += rotation;
                imageObject.rotate(pasteImageObject.currentRotation, 0 ,0);
                break;
            case 1:
                break;
            case 3:
                pasteImageObject.currentRotation = 180;
                imageObject.rotate(180, 0, 0);
                break;
            case 6:
                pasteImageObject.currentRotation = 90;
                imageObject.rotate(90, 0, 0);
                break;
            case 8:
                pasteImageObject.currentRotation = -90;
                imageObject.rotate(-90, 0, 0);
                break;
            default:
                break;
        }
    }

    //--------------------------------------------------------------------------

    function resizeImageObject(imageObject) {
        console.log("Resize:", imageObject.width, "x", imageObject.height, "=>", canvas.width, canvas.height);

        var canvasRatio = canvas.width / canvas.height;
        var imageRatio = imageObject.width / imageObject.height;

        console.log("canvasRatio:", canvasRatio, "imageRatio:", imageRatio);

        var scaleFactor = 1;

        if (Qt.platform.os === "osx" || Qt.platform.os === "ios") {
            scaleFactor = Screen.devicePixelRatio;
            console.warn("Using Qt canvas bug workaround scaleFactor:", scaleFactor);
        }

        if (imageRatio < canvasRatio) {
            imageObject.scaleToHeight(canvas.height * scaleFactor);
        } else {
            imageObject.scaleToWidth(canvas.width * scaleFactor);
        }

        console.log("Image resized:", imageObject.width, "x", imageObject.height, "offset:", imageObject.offsetX, imageObject.offsetY);
    }

    //--------------------------------------------------------------------------

    function setOffsets(imageObject){

        var scaleFactor = 1;

        if (Qt.platform.os === "osx" || Qt.platform.os === "ios") {
            scaleFactor = Screen.devicePixelRatio;
            console.warn("Using Qt canvas bug workaround scaleFactor:", scaleFactor);
        }

        imageObject.offsetX = (canvas.width - imageObject.width / scaleFactor) / 2;
        imageObject.offsetY = (canvas.height - imageObject.height / scaleFactor) / 2;
    }

    //--------------------------------------------------------------------------
}
