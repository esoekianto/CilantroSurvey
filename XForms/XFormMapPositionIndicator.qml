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
import QtLocation 5.3
import QtPositioning 5.3

MapCircle {
    id: positionIndicator
    
    property XFormPositionSourceConnection positionSourceConnection
    property real horizontalAccuracy: 0
    
    visible: positionSourceConnection.active
    color: horizontalAccuracy > 0 ? "#8000b2ff" : "#80ff0000"
    radius: horizontalAccuracy
    border {
        color: "#80ffffff"
        width: 1
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            positionIndicator.center = position.coordinate;

            if (position.horizontalAccuracyValid) {
                positionIndicator.horizontalAccuracy = position.horizontalAccuracy;
            } else {
                positionIndicator.horizontalAccuracy = -1;
            }
        }
    }

    //--------------------------------------------------------------------------
}
