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

ComboBox {
    property Camera camera

    model: QtMultimedia.availableCameras
    visible: false
    textRole: "displayName"
    
    onActivated: {
        camera.stop();
        camera.deviceId = model[index].deviceId;
        camera.start()
    }
    
    onVisibleChanged: {
        if (!visible) {
            return;
        }
        
        for (var i = 0; i < model.length; i++) {
            if (model[i].deviceId === camera.deviceId) {
                currentIndex = i;
                break;
            }
        }
    }
}
