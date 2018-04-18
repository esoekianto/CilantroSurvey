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

Rectangle {
    id: background

    property alias text: messageText.text
    property alias textColor: messageText.color

    readonly property int kDefaultDuration: 3000
    readonly property color kDefaultColor: "cyan"

    height: messageText.height * 1.2
    width: messageText.width * 1.2
    color: "#80A0A0A0"
    opacity: 0
    radius: 4
    visible: opacity > 0
    border {
        color: messageText.color
        width: 1
    }

    XFormText {
        id: messageText

        anchors {
            horizontalCenter: parent.horizontalCenter
        }

        color: kDefaultColor
        horizontalAlignment: Text.AlignHCenter

        font {
            pointSize: 25
        }
    }

    OpacityAnimator {
        id: hideAnimator
        target: background
        from: 1
        to: 0
        duration: 3000
    }

    function show(text, duration, color) {
        if (text) {
            messageText.text = text;
        }

        messageText.color = color ? color: kDefaultColor;

        hideAnimator.stop();
        hideAnimator.duration = duration ? duration : kDefaultDuration;
        opacity = 1;
        hideAnimator.start();
    }

    function hide(fade) {
        hideAnimator.stop();
        opacity = 0;
    }
}
