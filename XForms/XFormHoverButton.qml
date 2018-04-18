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
import QtQuick.Controls.Private 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: button
    property alias source: image.source
    property alias repeatInterval: repeatTimer.interval

    property alias horizontalAlignment: image.horizontalAlignment
    property alias verticalAlignment: image.verticalAlignment

    signal clicked
    signal pressAndHold
    signal repeat

    Rectangle {
        id: fillRect
        anchors.fill: parent
        color: "black"
        opacity: mouse.pressed ? 0.07 : mouse.containsMouse ? 0.02 : 0.0
    }

    Rectangle {
        border.color: gridColor
        anchors.fill: parent
        anchors.margins: -1
        color: "transparent"
        opacity: fillRect.opacity * 10
    }

    Image {
        id: image

        anchors {
            fill: parent
            margins: 4 * AppFramework.displayScaleFactor
        }

        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        //opacity: 0.7
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: Settings.hoverEnabled

        onClicked: button.clicked()

        onPressAndHold: {
            button.pressAndHold();
            repeatTimer.start();
        }

        onReleased: {
            repeatTimer.stop();
        }

        onExited: {
            repeatTimer.stop();
        }

        onCanceled: {
            repeatTimer.stop();
        }
    }

    Timer {
        id: repeatTimer

        running: false
        interval: 100
        repeat: true
        triggeredOnStart: true

        onTriggered: button.repeat();
    }
}
