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
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0

Item {
    id: debugPanel

    property color debugColor: "white"
    property Camera camera
    readonly property alias _debugMode: debugPanel.visible

    width: debugInfo.width
    height: debugInfo.height
    
    Rectangle {
        anchors.fill: parent
        color: "#60FFFFFF"
        radius: 4
    }
    
    Column {
        id: debugInfo
        
        Text {
            text: camera.displayName
            color: debugColor
        }
        
        Text {
            text: "Position: " + (camera.position === Camera.FrontFace ? "Front Face" : camera.position === Camera.BackFace ? "Back Face" : "Unspecified")
            color: debugColor
        }
        
        /*
            Text {
                text: "Device ID: " + camera.deviceId
                color: debugColor
            }
            */
        
        Text {
            text: "Lock Status: " + camera.lockStatus.toString()
            color: debugColor
        }
        
        Text {
            text: "Digital Zoom: " + camera.digitalZoom.toString() + " Max: " + camera.maximumDigitalZoom.toString()
            color: debugColor
        }
        
        Text {
            text: "Optical Zoom: " + camera.opticalZoom.toString() + " Max: " + camera.maximumOpticalZoom.toString()
            color: debugColor
        }
        
        Text {
            text: "Flash Mode: " + camera.flash.mode.toString()
            color: debugColor
            visible: camera.flash.ready
        }
        
        Text {
            text: "Focus Mode: " + camera.focus.focusMode.toString()
            color: debugColor
        }
        
        Text {
            text: Camera.FocusManual.toString() + " Manual"
            color: debugColor
            font.bold: camera.focus.focusMode == Camera.FocusManual
            font.italic: !camera.focus.isFocusModeSupported(Camera.FocusManual) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusHyperfocal.toString() + " Hyperfocal"
            color: debugColor
            font.bold: camera.focus.focusMode == Camera.FocusHyperfocal
            font.italic: !camera.focus.isFocusModeSupported(Camera.FocusHyperfocal) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusAuto.toString() + " Auto"
            color: debugColor
            font.bold: camera.focus.focusMode == Camera.FocusAuto
            font.italic: !camera.focus.isFocusModeSupported(Camera.FocusAuto) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusInfinity.toString() + " Infinity"
            color: debugColor
            font.bold: camera.focus.focusMode == Camera.FocusInfinity
            font.italic: !camera.focus.isFocusModeSupported(Camera.FocusInfinity) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusContinuous.toString() + " Continuous"
            color: debugColor
            font.bold: camera.focus.focusMode == Camera.FocusContinuous
            font.italic: !camera.focus.isFocusModeSupported(Camera.FocusContinuous) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            property bool isSupported: camera.focus.isFocusModeSupported(Camera.FocusMacro) && _debugMode
            
            text: Camera.FocusMacro.toString() + " Macro"
            color: debugColor
            font.bold: camera.focus.focusMode == Camera.FocusMacro
            font.italic: !isSupported
            visible: font.bold || isSupported
            MouseArea {
                anchors.fill: parent
                enabled: parent.isSupported
                onClicked: {
                    camera.focus.focusMode = Camera.FocusMacro;
                }
            }
        }
        
        Text {
            text: "Focus Point Mode: " + camera.focus.focusPointMode.toString()
            color: debugColor
        }
        
        Text {
            text: Camera.FocusPointAuto.toString() + " Auto"
            color: debugColor
            font.bold: camera.focus.focusPointMode == Camera.FocusPointAuto
            font.italic: !camera.focus.isFocusPointModeSupported(Camera.FocusPointAuto) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusPointCenter.toString() + " Center"
            color: debugColor
            font.bold: camera.focus.focusPointMode == Camera.FocusPointCenter
            font.italic: !camera.focus.isFocusPointModeSupported(Camera.FocusPointCenter) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusPointFaceDetection.toString() + " Face Detection"
            color: debugColor
            font.bold: camera.focus.focusPointMode == Camera.FocusPointFaceDetection
            font.italic: !camera.focus.isFocusPointModeSupported(Camera.FocusPointFaceDetection) && _debugMode
            visible: font.bold || !font.italic
        }
        
        Text {
            text: Camera.FocusPointCustom.toString() + " Custom (" + camera.focus.customFocusPoint.x.toString() + ", " + camera.focus.customFocusPoint.y.toString() + ")"
            color: debugColor
            font.bold: camera.focus.focusPointMode == Camera.FocusPointCustom
            font.italic: !camera.focus.isFocusPointModeSupported(Camera.FocusPointCustom) && _debugMode
            visible: font.bold || !font.italic
        }
    }
}
