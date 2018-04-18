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
import QtMultimedia 5.5
import QtQuick.Window 2.0
import QtGraphicalEffects 1.0
import QtSensors 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Rectangle {
    id: page

    property string title: "Camera"
    property FileFolder imagesFolder
    property string imagePrefix: "Image"
    property string makerNote

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: AppFramework.alphaColor(accentColor, 0.75)

    readonly property bool isDesktop: Qt.platform.os === "windows" || Qt.platform.os === "osx"
    readonly property bool isPortrait : Screen.orientation === Qt.PortraitOrientation || Screen.orientation === Qt.InvertedPortraitOrientation

    property size resolution
    property var location
    property double compassAzimuth: NaN

    signal captured(string path, url url)    

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        positionSourceConnection.activate();

        compass.start();

        var deviceId = app.settings.value("Camera/deviceId", "");
        if (QtMultimedia.availableCameras.length > 0)
        {
            var cameraIndex = 0;
            for (var i = 0; i < QtMultimedia.availableCameras.length; i++)
            {
                if (QtMultimedia.availableCameras[i].deviceId === deviceId) {
                    cameraIndex = i;
                    console.log("camera device found:", i, camera.deviceId);
                    break;
                }

                if (QtMultimedia.availableCameras[i].position === Camera.BackFace)
                {
                    cameraIndex = i;
                    break;
                }
            }

            camera.deviceId = QtMultimedia.availableCameras[cameraIndex].deviceId;
        }

        Qt.inputMethod.hide();

        console.log("resolution:", resolution.width, "x", resolution.height);
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        app.settings.setValue("Camera/deviceId", camera.deviceId);

        if (compass.active) {
            compass.stop();
        }
    }

    //--------------------------------------------------------------------------

    Camera {
        id: camera

        property real zoom: opticalZoom * digitalZoom
        property real maximumZoom: maximumOpticalZoom * maximumDigitalZoom

        cameraState: cameraWindow.visible ? Camera.ActiveState : Camera.UnloadedState

        captureMode: Camera.CaptureStillImage

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointAuto
        }

        exposure {
            exposureCompensation: Camera.ExposureAuto
        }

        Component.onCompleted: {
            if (page.resolution.width > 0 && page.resolution.height > 0) {
                imageCapture.resolution = page.resolution;
            }
        }

        onCameraStatusChanged: {

            switch (cameraStatus) {
            case Camera.ActiveStatus:
                //captureMessage.show(qsTr("Touch to capture"), 5000);
                break;
            }
        }

        imageCapture {
            onImageMetadataAvailable: {
                console.log("metadata:", requestId, ":", key, "=", value);
            }

            onImageCaptured: {
                // Show the preview in an Image
                //photoPreview.visible = true
                //photoPreview.source = preview
            }

            onCapturedImagePathChanged: {
                //                            var url = AppFramework.resolvedPathUrl(camera.imageCapture.capturedImagePath);
                console.log("Camera image path changed: ", camera.imageCapture.capturedImagePath);
                //                            captured(camera.imageCapture.capturedImagePath, url);
                //                            closeControl();
            }

            onImageSaved: {
                exifInfo.load(path);
                var o = exifInfo.imageValue(ExifInfo.ImageOrientation);
                var exifOrientation = o ? o : 1;

                var exifOrientationAngle = 0;
                switch (exifOrientation) {
                case 3:
                    exifOrientationAngle = 180;
                    break;

                case 6:
                    exifOrientationAngle = 270;
                    break;

                case 8:
                    exifOrientationAngle = 90;
                    break;
                }

                var rotateFix = 0;

                switch (Qt.platform.os)
                {
                case "android":
                    rotateFix = -exifOrientationAngle;
                    break;

                case "ios":
                    rotateFix = -videoOutput.orientation;

                    if (camera.position === Camera.FrontFace && isPortrait) {
                        rotateFix = (-videoOutput.orientation + 180) % 360;
                    }
                    break;

                default:
                    rotateFix = -videoOutput.orientation;
                    break;
                }

                if (rotateFix !== 0) {
                    imageObject.load(path);
                    imageObject.rotate(rotateFix);
                    imageObject.save(path);
                }

                var url = AppFramework.resolvedPathUrl(path);
                console.log("onImageSaved", requestId, path, url, resolution.width, "x", resolution.height);
                updateExif(path);
                captured(camera.imageCapture.capturedImagePath, url);
                closeControl();
            }
        }
        
        function setZoom(newZoom) {
            newZoom = Math.max(Math.min(newZoom, maximumZoom), 1.0);

            var newOpticalZoom = 1.0;
            var newDigitalZoom = 1.0;

            if (newZoom > camera.maximumOpticalZoom) {
                newOpticalZoom = camera.maximumOpticalZoom;
                newDigitalZoom = newZoom / camera.maximumOpticalZoom;
            } else {
                newOpticalZoom = newZoom;
                newDigitalZoom = 1.0;
            }

            if (camera.maximumOpticalZoom > 1.0) {
                camera.opticalZoom = newOpticalZoom;
            }

            if (camera.maximumDigitalZoom > 1.0) {
                camera.digitalZoom = newDigitalZoom;
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        positionSourceManager: xform.positionSourceManager

        onNewPosition: {
            updateLocation(position);
        }

        //--------------------------------------------------------------------------

        function updateLocation(position) {
            console.log("Updating camera position:", JSON.stringify(position));

            positionSourceConnection.release();

            location = {
                datum: "WGS-84",

                timestamp: position.timestamp,

                latitude: position.coordinate.latitude,
                longitude: position.coordinate.longitude,

                altitudeValid: position.altitudeValid,
                altitude: position.coordinate.altitude,

                horizontalAccuracyValid: position.horizontalAccuracyValid,
                horizontalAccuracy: position.horizontalAccuracy,

                speedValid: position.speedValid,
                speed: position.speed,

                directionValid: position.directionValid,
                direction: position.direction
            };
        }
    }

    //--------------------------------------------------------------------------

    Compass {
        id: compass

        onReadingChanged: {
            if (connectedToBackend) {
                compassAzimuth = Math.round(reading.azimuth * 100) / 100;
            }
        }
    }

    //--------------------------------------------------------------------------

    Item {
        id: cameraWindow

        anchors.fill: parent

        z: 88

        Rectangle {
            anchors.fill: parent

            color: "black"

            ColumnLayout {
                anchors.fill: parent

                Rectangle {
                    id: titleBar

                    Layout.fillWidth: true

                    property int buttonHeight: 35 * AppFramework.displayScaleFactor

                    height: columnLayout.height + 5
                    //color: barBackgroundColor //"#80000000"
                    color: "transparent"

                    ColumnLayout {
                        id: columnLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 2
                        }

                        RowLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                            }

                            ImageButton {
                                Layout.fillHeight: true
                                Layout.preferredHeight: titleBar.buttonHeight
                                Layout.preferredWidth: titleBar.buttonHeight

                                // source: "images/close.png"
                                source: "images/back.png"
                                pressedColor: "transparent"
                                hoverColor: "transparent"

                                ColorOverlay {
                                    anchors.fill: parent
                                    source: parent.image
                                    color: xform.style.titleTextColor
                                }

                                onClicked: {
                                    closeControl();
                                }
                            }

                            Rectangle {
                                //for spacing when camera combobox is not visible
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                color: "transparent"

                                XFormCameraComboBox {
                                    id: cameraComboBox

                                    width: Math.min(parent.width,300*AppFramework.displayScaleFactor)
                                    anchors.verticalCenter: parent.verticalCenter

                                    camera: camera

                                    onActivated: {
                                        cameraComboBox.visible = false;
                                        cameraControls.switchButton.visible = true;
                                    }
                                }
                            }

                            XFormCameraControls {
                                id: cameraControls

                                Layout.preferredHeight: titleBar.buttonHeight
                                Layout.margins: 5 * AppFramework.displayScaleFactor
                                Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                                Layout.rightMargin: 10 * AppFramework.displayScaleFactor
                                spacing: 25 * AppFramework.displayScaleFactor

                                camera: camera
                                preferredFlashMode: Camera.FlashOn

                                onSelectCamera: {
                                    cameraComboBox.visible = true;
                                    switchButton.visible = false;
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredHeight: titleBar.buttonHeight
                                Layout.preferredWidth: titleBar.buttonHeight

                                //                            color: "#80FFFFFF"
                                //                            radius: 5

                                visible: positionSourceConnection.valid

                                ImageButton {
                                    id: positionButton

                                    anchors.fill: parent

                                    pressedColor: "transparent"
                                    hoverColor: "transparent"
                                    source: positionSourceConnection.active ? "images/position-on.png" : "images/position-off.png"

                                    onClicked: {
                                        if (positionSourceConnection.active) {
                                            positionSourceConnection.release();
                                        } else {
                                            positionSourceConnection.activate();
                                        }
                                    }
                                }

                                ColorOverlay {
                                    anchors.fill: positionButton
                                    source: positionButton.image
                                    color: xform.style.titleTextColor
                                }

                                BusyIndicator {
                                    anchors.fill: parent
                                    running: positionSourceConnection.active
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    VideoOutput {
                        id: videoOutput

                        anchors.fill: parent

                        source: camera
                        focus : visible // to receive focus and capture key events when visible

                        //orientation: Qt.platform.os === "ios" ? 270 : 0
                        //orientation: isDesktop ? 0 : 270
                        autoOrientation: true

                        fillMode: VideoOutput.PreserveAspectFit
                        PinchArea {
                            id: cameraPinchControl
                            property real pinchInitialZoom: 1.0
                            property real pinchScale: 1.0

                            anchors {
                                fill: parent
                            }

                            onPinchStarted: {
                                pinchInitialZoom = camera.zoom;
                                pinchScale = 1.0;
                            }

                            onPinchUpdated: {
                                pinchScale = pinch.scale;
                                camera.setZoom(pinchInitialZoom * pinchScale);
                                zoomControl.updateZoom(pinchInitialZoom * pinchScale);
                            }
                        }

                        Component.onCompleted: {
                            console.log("pic Orientation:", orientation, Qt.platform.os)

                            if (Qt.platform.os === "ios") {
                                if (isIPhone()) {
                                    autoOrientation = false;
                                    orientation = Qt.binding(function () {
                                        return (camera.position === Camera.FrontFace) ? ((camera.orientation + 180) % 360) : camera.orientation;
                                    } );
                                }
                            }
                        }

                        XFormText {
                            id: zoomText
                            visible: camera.maximumZoom > 1
                            anchors {
                                horizontalCenter: videoOutput.horizontalCenter
                                bottom: zoomControlContainer.top
                                bottomMargin: 5 * AppFramework.displayScaleFactor
                            }

                            text: qsTr("%1x").arg(camera.zoom.toFixed())

                            color: "#000"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Item {
                            id: zoomControlContainer
                            visible: camera.maximumZoom > 1
                            width: parent.width * .75
                            height: 30 * AppFramework.displayScaleFactor
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                            XFormCameraZoomControl {
                                id: zoomControl
                                anchors.fill: parent
                                minimumZoom: 1
                                maximumZoom: camera.maximumZoom
                                onZoomTo: {
                                    camera.setZoom(value)
                                }                                
                            }
                        }
                    } // VideoOutput
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80 * AppFramework.displayScaleFactor

                    color: "transparent"

                    ImageButton {
                        Layout.fillHeight: true
                        height: 50 * AppFramework.displayScaleFactor
                        width: 50 * AppFramework.displayScaleFactor
                        anchors.centerIn: parent

                        source: "images/camera-click.png"
                        pressedColor: "transparent"
                        hoverColor: "transparent"

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        onClicked: {
                            captureImage()
                        }
                    }

                }
            }

            Text {
                color: "cyan"
                anchors.centerIn: parent
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                maximumLineCount: 3
                visible: false
                text: Qt.platform.os + " | Camera: " + videoOutput.orientation  +  " <br> Orientation: " + Screen.orientation + " | Primary orientation: " + Screen.primaryOrientation
            }

            BusyIndicator {
                anchors.centerIn: parent
                visible: !camera.imageCapture.ready
            }
        }

        XFormFaderMessage {
            id: captureMessage

            anchors.centerIn: parent
        }
    }

    //--------------------------------------------------------------------------

    function zeroPad(num, places) {
        var zero = places - num.toString().length + 1;
        return new Array(+(zero > 0 && zero)).join("0") + num;
    }

    function captureImage() {
        captureMessage.show(qsTr("Capturing image"));

        var imageDate = new Date();
        var imageName = imagePrefix + "-" +
                imageDate.getUTCFullYear().toString() +
                zeroPad(imageDate.getUTCMonth() + 1, 2) +
                zeroPad(imageDate.getUTCDate(), 2) +
                "-" +
                zeroPad(imageDate.getUTCHours(), 2) +
                zeroPad(imageDate.getUTCMinutes(), 2) +
                zeroPad(imageDate.getUTCSeconds(), 2) +
                ".jpg";

        camera.imageCapture.captureToLocation(imagesFolder.filePath(imageName));
    }

    function closeControl() {
        camera.stop();
        parent.pop();
    }

    //----------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    ExifInfo {
        id: exifInfo
    }

    function updateExif(filePath) {
        var infoChanged = false;

        exifInfo.load(filePath);

        if (exifInfo.imageValue(ExifInfo.ImageOrientation) !== 1) {
            exifInfo.setImageValue(ExifInfo.ImageOrientation, 1);

            infoChanged = true;
        }

        if (location) {
            exifInfo.setImageValue(ExifInfo.ImageDateTime, new Date());
            exifInfo.setImageValue(ExifInfo.ImageSoftware, app.info.title);
            exifInfo.setImageValue(ExifInfo.ImageXPTitle, title);

            exifInfo.setExtendedValue(ExifInfo.ExtendedDateTimeOriginal, new Date());
            exifInfo.setExtendedValue(ExifInfo.ExtendedDateTimeDigitized, new Date());
            if (makerNote > "") {
                exifInfo.setExtendedValue(ExifInfo.ExtendedMakerNote, makerNote);
            }

            exifInfo.setGpsValue(ExifInfo.GpsDateStamp, location.timestamp);
            exifInfo.setGpsValue(ExifInfo.GpsTimeStamp, location.timestamp);
            exifInfo.setGpsValue(ExifInfo.GpsMapDatum, location.datum);
            exifInfo.gpsLongitude = location.longitude;
            exifInfo.gpsLatitude = location.latitude;

            if (location.altitudeValid)
            {
                exifInfo.gpsAltitude = location.altitude;
            }

            if (location.horizontalAccuracyValid)
            {
                exifInfo.setGpsValue(ExifInfo.GpsHorizontalPositionError, location.horizontalAccuracy);
            }

            if (location.speedValid) {
                exifInfo.setGpsValue(ExifInfo.GpsSpeed, location.speed * 3.6); // Convert M/S to KM/H
                exifInfo.setGpsValue(ExifInfo.GpsSpeedRef, "K");
            }

            if (location.directionValid) {
                exifInfo.setGpsValue(ExifInfo.GpsTrack, location.direction);
                exifInfo.setGpsValue(ExifInfo.GpsTrackRef, "T");
            }

            infoChanged = true;
        }

        if (isFinite(compassAzimuth)) {
            exifInfo.setGpsValue(ExifInfo.GpsImageDirection, compassAzimuth);
            exifInfo.setGpsValue(ExifInfo.GpsImageDirectionRef, "M");

            infoChanged = true;
        }

        if (infoChanged) {
            exifInfo.save(filePath);

            console.log("EXIF info updated:", filePath, "location:", JSON.stringify(location, undefined, 2), "compassAzimuth:", compassAzimuth);
        }
    }

    function isIPhone() {
        if (Qt.platform.os === "ios" && AppFramework.systemInformation.hasOwnProperty("unixMachine")) {
            if (AppFramework.systemInformation.unixMachine.match(/^iPhone/)) {
                return true;
            }
        }

        return false;
    }

    //--------------------------------------------------------------------------
}
