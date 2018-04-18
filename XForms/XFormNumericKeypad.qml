/* Copyright 2016 Esri
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
import QtQuick.Layouts 1.1

XFormKeypad {
    property bool showSign: true
    property bool showPoint: true
    property bool showEnter: false

    property var locale: Qt.locale()

    //--------------------------------------------------------------------------

    columns: 4
    rows: 4

    //--------------------------------------------------------------------------

    XFormKey {
        key: Qt.Key_7
    }

    XFormKey {
        key: Qt.Key_8
    }

    XFormKey {
        key: Qt.Key_9
    }

    XFormKey {
        key: Qt.Key_Delete
        text: "←"
    }


    XFormKey {
        key: Qt.Key_4
    }

    XFormKey {
        key: Qt.Key_5
    }

    XFormKey {
        key: Qt.Key_6
    }

    XFormKey {
    }


    XFormKey {
        key: Qt.Key_1
    }

    XFormKey {
        key: Qt.Key_2
    }

    XFormKey {
        key: Qt.Key_3
    }

    XFormKey {
    }


    XFormKey {
        visible: showSign
        key: Qt.Key_plusminus
//        text: "±"
    }

    Item {
        implicitWidth: 1
        implicitHeight: 1

        visible: !showSign
    }

    XFormKey {
        Layout.columnSpan: !showPoint ? showSign ? 2 : 1 : 1

        key: Qt.Key_0
    }

    XFormKey {
        visible: showPoint

        key: Qt.Key_Period
        // text: locale.decimalPoint
    }

    Item {
        implicitWidth: 1
        implicitHeight: 1

        visible: !showPoint && !showSign
    }

    XFormKey {
        visible: showEnter

        key: Qt.Key_Return
        text: "↵"
        color: "#007aff"
        textColor: "white"
    }

}
