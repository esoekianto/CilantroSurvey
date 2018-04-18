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
import QtLocation 5.3
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Column {
    id: column
    
    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: 5
    }
    
    spacing: 5
    
    Text {
        width: parent.width
        text: qsTr("Latitude")
        color: xform.style.textColor
    }
    
    XFormTextField {
        id: latitudeField
        
        width: parent.width
        text: latitude.toString()
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        validator: DoubleValidator {
            bottom: -90
            top: 90
            notation: DoubleValidator.StandardNotation
        }
        
        onEditingFinished: {
            latitude = Number(text);
        }
    }
    
    Text {
        width: parent.width
        text: qsTr("Longitude")
        color: xform.style.textColor
    }
    
    XFormTextField {
        id: longitudeField
        
        width: parent.width
        text: longitude.toString()
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        validator: DoubleValidator {
            bottom: -180
            top: 180
            notation: DoubleValidator.StandardNotation
        }
        
        onEditingFinished: {
            longitude = Number(text);
        }
    }
    
    /*
    Text {
        width: parent.width
        text: qsTr("Altitude")
        color: xform.style.textColor
    }
    
    XFormTextField {
        id: altitudeField
        
        width: parent.width
        text: altitude.toString()
        
        onEditingFinished: {
            altitude = Number(text);
        }
    }
    */
}
