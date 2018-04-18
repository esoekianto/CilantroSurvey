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
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Barcodes 1.0
import ArcGIS.AppFramework.Controls 1.0

Rectangle {

    id: barcodeScanView

    property alias camera: camera
    property alias decodeHints: barcodeFilter.decodeHints // TODO bug workaround
    property bool debugMode: false
    property int retryDuration: 3000

    property alias useFlash: cameraControls.useFlash

    property real defaultZoom: 2.0

    signal codeScanned(string code, int codeType, string codeTypeString)
    signal selectCamera()

    implicitWidth: 100
    implicitHeight: 100

    color: "black"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (QtMultimedia.availableCameras.length > 0) {
            var cameraIndex = 0;
            for (var i = 0; i < QtMultimedia.availableCameras.length; i++) {
                if (QtMultimedia.availableCameras[i].deviceId === camera.deviceId) {
                    cameraIndex = i;
                    console.log("camera device found:", i, camera.deviceId);
                    break;
                }
                if (QtMultimedia.availableCameras[i].position === Camera.BackFace) {
                    cameraIndex = i;
                    break;
                }
            }
            camera.deviceId = QtMultimedia.availableCameras[cameraIndex].deviceId;
            camera.start();
        }

        Qt.inputMethod.hide();
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        camera.stop();
    }

    //--------------------------------------------------------------------------

    Camera {
        id: camera

        property real zoom: opticalZoom * digitalZoom
        property real maximumZoom: maximumOpticalZoom * maximumDigitalZoom

        cameraState: Camera.CaptureStillImage

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointAuto
        }

        exposure {
            exposureCompensation: Camera.ExposureAuto
        }

        viewfinder.resolution: Qt.size(640, 480)

        Component.onCompleted: {
            setZoom(defaultZoom);
            zoomControl.updateZoom(defaultZoom);
            //selectFocusMode();
        }

        onDeviceIdChanged: {
            debugMode = false;
        }

        function selectFocusMode() {
            if (focus.isFocusModeSupported(Camera.FocusContinuous)) {
                focus.focusMode = Camera.FocusContinuous;
            } else if (focus.isFocusModeSupported(Camera.FocusAuto)) {
                focus.focusMode = Camera.FocusAuto;
            }

            if (focus.isFocusPointModeSupported(Camera.FocusPointCenter)) {
                focus.focusPointMode = Camera.FocusPointCenter;
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top controls --------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

            XFormCameraControls {
                id: cameraControls

                anchors {
                    fill: parent
                }

                camera: barcodeScanView.camera
                preferredFlashMode: Camera.FlashVideoLight

                onSelectCamera: {
                    barcodeScanView.selectCamera();
                }
            }
        }

        // Video output area ---------------------------------------------------

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            VideoOutput {
                id: videoOutput

                anchors.fill: parent
                source: camera
                autoOrientation: true
                filters: [ barcodeFilter ]

                Rectangle {
                    id: captureFrame
                    anchors.centerIn: parent
                    width: Math.min(videoOutput.contentRect.width, videoOutput.contentRect.height) * 9 / 10 + 10
                    height: width
                    radius: 10
                    color: "transparent"
                }

                Repeater {
                    visible: debugMode
                    model: camera.focus.focusZones

                    Rectangle {
                        border {
                            width: 2
                            color: status == Camera.FocusAreaFocused ? "green" : "white"
                        }
                        color: "transparent"

                        // Map from the relative, normalized frame coordinates
                        property variant mappedRect: videoOutput.mapNormalizedRectToItem(area)

                        x: mappedRect.x
                        y: mappedRect.y
                        width: mappedRect.width
                        height: mappedRect.height
                    }
                }

                PinchArea {
                    property real pinchInitialZoom: 1.0
                    property real pinchScale: 1.0

                    anchors {
                        fill: captureFrame
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

                    MouseArea {
                        anchors {
                            fill: parent
                        }

                        enabled: camera.cameraStatus == Camera.ActiveStatus

                        hoverEnabled: true
                        cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor

                        /*
                        onPressAndHold: {
                            if (camera.focus.isFocusModeSupported(Camera.FocusAuto)) {
                                if (camera.lockStatus == Camera.Unlocked) {
                                    scanMessage.show("Focusing");
                                    camera.searchAndLock();
                                }
                                else {
                                    scanMessage.show("Unlocking Focus");
                                    camera.unlock();
                                }
                            }
                        }
                        */
                    }
                }

                MouseArea {
                    width: 50 * AppFramework.displayScaleFactor
                    height: width
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }

                    onClicked: {
                        if (debugMode) {
                            camera.unlock();
                            if (camera.focus.focusMode != Camera.FocusAuto) {
                                camera.focus.focusMode = Camera.FocusAuto;
                            } else {
                                camera.focus.focusMode = Camera.FocusContinuous;
                            }
                        }
                    }

                    onPressAndHold: {
                        debugMode = !debugMode;
                        scanMessage.show(debugMode ? "Debug Mode On" : "Debug Mode Off", undefined, "red");
                    }
                }

                XFormText {
                    x: 0
                    y: (videoOutput.contentRect.y + videoOutput.contentRect.height - height ) - 10 * AppFramework.displayScaleFactor
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("%1x").arg(camera.zoom.toFixed())
                    color: "black"
                }
            }

            Item {
                property int frameSize: (videoOutput.contentRect.height > videoOutput.contentRect.width ? videoOutput.contentRect.width : videoOutput.contentRect.height) * 0.9
                height: frameSize
                width: frameSize
                z: 100
                anchors.centerIn: parent

                XFormBarcodeScanMarker {
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                }

                XFormBarcodeScanMarker {
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                    rotation: 90
                }

                XFormBarcodeScanMarker {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                    }
                    rotation: 270
                }

                XFormBarcodeScanMarker {
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                    }
                    rotation: 180
                }
            }
        }

        // Bottom tools --------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 * AppFramework.displayScaleFactor

            XFormCameraZoomControl {
                id: zoomControl
                visible: camera.maximumZoom > 1
                height: 30 * AppFramework.displayScaleFactor
                width: parent.width * .75
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                minimumZoom: 1
                maximumZoom: camera.maximumZoom > 8 ? 8 : camera.maximumZoom
                onZoomTo: {
                    camera.setZoom(value)
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormCameraDebugInfo {
        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        visible: debugMode
        camera: camera
    }

    //--------------------------------------------------------------------------



    /*
    XFormCameraZoomControl {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        width : 100 * AppFramework.displayScaleFactor

        currentZoom: camera.digitalZoom
        maximumZoom: Math.min(4.0, camera.maximumDigitalZoom)
        onZoomTo: camera.setDigitalZoom(value)
    }
    */

    //--------------------------------------------------------------------------

    XFormFaderMessage {
        id: scanMessage

        anchors.centerIn: parent
    }

    //--------------------------------------------------------------------------

    BarcodeFilter {
        id: barcodeFilter

        orientation: videoOutput.orientation

        onDecoded: {
            console.log(barcode, barcodeType, barcodeTypeString)

            if (debugMode) {
                scanMessage.hide();
                scanMessage.show(qsTr("%1 (%2)").arg(barcode).arg(barcodeTypeString));
                return;
            }

            codeScanned(barcode, barcodeType, barcodeTypeString);
        }

        onInfoChanged: {
            console.log("info: ", JSON.stringify(info, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

}
