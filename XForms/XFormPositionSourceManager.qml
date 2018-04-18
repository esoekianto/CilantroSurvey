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

import ArcGIS.AppFramework 1.0

Item {
    property alias positionSource: positionSource
    property int referenceCount: 0
    property date activatedTimestamp
    property int wkid: 4326

    readonly property bool valid: positionSource.valid

    property string errorString

    signal newPosition(var position, bool force)
    signal error()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        AppFramework.environment.setValue("APPSTUDIO_POSITION_DESIRED_ACCURACY", "HIGHEST");
        AppFramework.environment.setValue("APPSTUDIO_POSITION_ACTIVITY_MODE", "OTHERNAVIGATION");
    }

    //--------------------------------------------------------------------------

    PositionSource {
        id: positionSource

        Component.onCompleted: {
            console.log("positionSource:", name);
        }

        onActiveChanged: {
            console.log("positionSource.active:", active);
        }

        onPositionChanged: {
            if (referenceCount <= 0) {
                console.warn("Position changed when referenceCount:", referenceCount);
                active = false;
                return;
            }

            var position = positionSource.position;

            // console.log("positionSource active:", (position.timestamp - activatedTimestamp) / 1000);

            if (position.latitudeValid && position.longitudeValid && position.timestamp >= activatedTimestamp) {
                //console.log("newPosition:", JSON.stringify(position));
                console.log("newPosition:", position.timestamp, "coordinate:", position.coordinate.latitude, position.coordinate.longitude, position.coordinate.altitude);

                newPosition(position, false);
            }
        }

        onSourceErrorChanged: {
            if (positionSource.sourceError !== PositionSource.NoError) {
                console.error("Deactivating positioning sourceError:", positionSource.sourceError);
                reset();

                switch (positionSource.sourceError) {
                case PositionSource.AccessError :
                    errorString = qsTr("Position source access error");
                    break;

                case PositionSource.ClosedError :
                    errorString = qsTr("Position source closed error");
                    break;

                case PositionSource.SocketError :
                    errorString = qsTr("Position source error");
                    break;

                case PositionSource.NoError :
                    errorString = "";
                    break;

                default:
                    errorString = qsTr("Unknown position source error %1").arg(positionSource.sourceError);
                    break;
                }

                error();
            }
        }
    }

    //--------------------------------------------------------------------------

    function activate() {
        if (!valid) {
            console.error("activate: Invalid positionSource");
            return;
        }

        if (!referenceCount) {
            errorString = "";
            activatedTimestamp = new Date();
        }

        referenceCount++;

        if (positionSource.valid) {
            positionSource.active = referenceCount > 0;
        }

        console.log("Activate positionSource referenceCount:", referenceCount, "active:", positionSource.active);
//        console.trace();
    }

    //--------------------------------------------------------------------------

    function release() {
        if (!valid) {
            console.error("release: Invalid positionSource");
            return;
        }

        if (referenceCount > 0) {
            referenceCount--;
        } else {
            console.error("GeoPosition referenceCount <= 0 mismatch:", referenceCount);
            //console.trace();
            referenceCount = 0;
        }

        if (positionSource.valid) {
            positionSource.active = referenceCount > 0;
        }

        console.log("Release positionSource referenceCount:", referenceCount, "active:", positionSource.active);
//        console.trace();
    }

    //--------------------------------------------------------------------------

    function reset() {
        referenceCount = 0;

        if (positionSource.valid) {
            positionSource.active = false;
        }
    }

    //--------------------------------------------------------------------------

    function setPostion(coordinate) {
        if (!coordinate.isValid) {
            console.error("setPosition invalid coordinate");
            return;
        }

        console.log("Setting position:", coordinate.latitude, coordinate.longitude);

        reset();

        var position = {
            altitudeValid: false,
            coordinate: coordinate,
            direction: 0,
            directionValid: false,
            horizontalAccuracy: 0,
            horizontalAccuracyValid: false,
            latitudeValid: true,
            longitudeValid: true,
            magneticVariation: 0,
            magneticVariationValid: false,
            speed: 0,
            speedValid: false,
            timestamp: new Date(),
            verticalAccuracy: 0,
            verticalAccuracyValid: false,
            verticalSpeed: 0,
            verticalSpeedValid: false
        };

        newPosition(position, true);
    }

    //--------------------------------------------------------------------------
}
