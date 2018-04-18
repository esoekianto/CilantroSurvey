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
import QtQuick.Layouts 1.1
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0

RowLayout {
    property Camera camera

    property alias flashButton: flashButton
    property alias switchButton: switchButton

    property bool useFlash: false
    property int preferredFlashMode: Camera.FlashOn
    property real buttonSize: 35 * AppFramework.displayScaleFactor

    signal selectCamera()

    //--------------------------------------------------------------------------

    XFormImageButton {
        id: flashButton

        Layout.preferredHeight: buttonSize
        Layout.preferredWidth: buttonSize
        Layout.alignment: Qt.AlignHCenter
        
        visible: camera ? camera.flash.ready : false
        source: useFlash ? "images/camera_flash_fill.png" : "images/camera_flash_off.png"
        color: "white"
        
        onClicked: {
            useFlash = !useFlash;
            if (useFlash) {
                camera.flash.mode = preferredFlashMode;
            }
            else {
                camera.flash.mode = Camera.FlashOff;
            }
        }
    }
    
    XFormImageButton {
        id: switchButton
        
        Layout.preferredHeight: buttonSize
        Layout.preferredWidth: buttonSize
        Layout.alignment: Qt.AlignHCenter
        
        visible: QtMultimedia.availableCameras.length > 1
        source: "images/camera-switch-filled.png"
        color: "white"
        
        onClicked: {
            if (QtMultimedia.availableCameras.length > 2) {
                selectCamera();
            }
            else {
                switchCamera();
            }
        }
    }

    //--------------------------------------------------------------------------

    function switchCamera() {
        if (QtMultimedia.availableCameras.length > 0) {

            var cameraIndex = 0;
            for (var i = 0; i < QtMultimedia.availableCameras.length; i++)
            {
                if (QtMultimedia.availableCameras[i].deviceId === camera.deviceId) {
                    cameraIndex = i;
                    break;
                }
            }

            cameraIndex = (cameraIndex + 1) % QtMultimedia.availableCameras.length;

            camera.stop();
            camera.deviceId = QtMultimedia.availableCameras[cameraIndex].deviceId;
            camera.start();
        }
    }

    //--------------------------------------------------------------------------
}
