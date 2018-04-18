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
import QtPositioning 5.3

Item {
    property XFormPositionSourceManager positionSourceManager
    property bool active: false
    readonly property bool valid: positionSourceManager.valid
    readonly property int wkid: positionSourceManager.wkid

    signal newPosition(var position)

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        release();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceManager

        onNewPosition: {
            if (active || force) {
                newPosition(position);
            }
        }

        onError: {
            active = false;
        }
    }

    //--------------------------------------------------------------------------

    function activate() {
        if (active) {
            return;
        }

        if (!positionSourceManager.valid) {
            return;
        }

        active = true;
        positionSourceManager.activate();
    }

    //--------------------------------------------------------------------------

    function release() {
        if (!active) {
            return;
        }

        active = false;

        if (!positionSourceManager.valid) {
            return;
        }

        positionSourceManager.release();
    }

    //--------------------------------------------------------------------------
}
