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

import "XForm.js" as XFormJS

QtObject {
    //--------------------------------------------------------------------------

    property real latitude
    property real longitude
    property real altitude
    property real speed: Number.NaN
    property real verticalSpeed: Number.NaN
    property real direction: Number.NaN
    property real magneticVariation: Number.NaN
    property real horizontalAccuracy: Number.NaN
    property real verticalAccuracy: Number.NaN
    property var address

    //--------------------------------------------------------------------------

    property int wkid: 4326
    
    //--------------------------------------------------------------------------

    readonly property bool isValid: latitude != 0 && longitude != 0 &&
                                    isFinite(latitude) && isFinite(longitude)

    readonly property bool altitudeValid: isFinite(altitude)
    readonly property bool speedValid: isFinite(speed)
    readonly property bool verticalSpeedValid: isFinite(verticalSpeed)
    readonly property bool directionValid: isFinite(direction)
    readonly property bool magneticVariationValid: isFinite(magneticVariation)
    readonly property bool horizontalAccuracyValid: isFinite(horizontalAccuracy)
    readonly property bool verticalAccuracyValid: isFinite(verticalAccuracy)
    readonly property var addressValid: typeof address ==="object" && address !== null

    //--------------------------------------------------------------------------

    property bool averaging: false
    property real averageCount: 0
    property date averageStart
    property date averageStop

    //--------------------------------------------------------------------------

    property bool debug: true

    //--------------------------------------------------------------------------

    signal changed()
    signal cleared()

    //--------------------------------------------------------------------------

    function clear() {
        latitude = Number.NaN;
        longitude = Number.NaN;
        altitude = Number.NaN;
        speed = Number.NaN;
        verticalSpeed = Number.NaN;
        direction = Number.NaN;
        magneticVariation = Number.NaN;
        horizontalAccuracy = Number.NaN;
        verticalAccuracy = Number.NaN;
        address = null;

        changed();
        cleared();
    }

    //--------------------------------------------------------------------------

    function fromPosition(position) {
        //console.log("fromPosition:", JSON.stringify(position));

        function validValue(value, valid) {
            return valid ? value : Number.NaN;
        }

        latitude = validValue(position.coordinate.latitude, position.latitudeValid);
        longitude = validValue(position.coordinate.longitude, position.longitudeValid);
        altitude = validValue(position.coordinate.altitude, position.altitudeValid);
        speed = validValue(position.speed, position.speedValid);
        verticalSpeed = validValue(position.verticalSpeed, position.verticalSpeedValid);
        direction = validValue(position.direction, position.directionValid);
        magneticVariation = validValue(position.magneticVariation, position.magneticVariationValid);
        horizontalAccuracy = validValue(position.horizontalAccuracy, position.horizontalAccuracyValid);
        verticalAccuracy = validValue(position.verticalAccuracy, position.verticalAccuracyValid);
        address = null;

        changed();
    }

    //--------------------------------------------------------------------------

    function toCoordinate() {
        return QtPositioning.coordinate(latitude, longitude, altitude);
    }

    //--------------------------------------------------------------------------

    function toObject() {
        var o = {
            "type": "point",
            "x": longitude,
            "y": latitude,
            "spatialReference": {
                "wkid": wkid
            }
        }

        if (altitudeValid) {
            o.z = altitude;
        } else {
            o.z = Number.NaN;
        }

        if (speedValid) {
            o.speed = speed;
        }

        if (verticalSpeedValid) {
            o.verticalSpeed = verticalSpeed;
        }

        if (directionValid) {
            o.direction = direction;
        }

        if (magneticVariationValid) {
            o.magneticVariation = magneticVariation;
        }

        if (horizontalAccuracyValid) {
            o.horizontalAccuracy = horizontalAccuracy;
        }

        if (verticalAccuracyValid) {
            o.verticalAccuracy = verticalAccuracy;
        }

        if (addressValid) {
            o.address = address;
        }

        if (debug) {
            console.log("Geoposition toObject:", JSON.stringify(o, undefined, 2));
        }

        return o;
    }

    //--------------------------------------------------------------------------

    function fromObject(o) {
        // console.log("fromObject:", JSON.stringify(o, undefined, 2));

        function validValue(name) {
            var value = o[name];

            return typeof value === "number" && isFinite(value) ? value : Number.NaN;
        }

        if (o.hasOwnProperty("x")) {
            longitude = validValue("x");
        } else if (o.hasOwnProperty("longitude")) {
            longitude = validValue("longitude");
        }

        if (o.hasOwnProperty("y")) {
            latitude = validValue("y");
        } else if (o.hasOwnProperty("latitude")) {
            latitude = validValue("latitude");
        }

        if (o.hasOwnProperty("z")) {
            altitude = validValue("z");
        } else if (o.hasOwnProperty("altitude")) {
            altitude = validValue("altitude");
        } else {
            altitude = Number.NaN;
        }

        speed = validValue("speed");
        verticalSpeed = validValue("verticalSpeed");
        direction = validValue("direction");
        magneticVariation = validValue("magneticVariation");

        if (o.hasOwnProperty("horizontalAccuracy")) {
            horizontalAccuracy = validValue("horizontalAccuracy");
        } else if (o.hasOwnProperty("accuracy")) {
            horizontalAccuracy = validValue("accuracy");
        }

        verticalAccuracy = validValue("verticalAccuracy");

        address = o["address"];

        changed();
    }

    //--------------------------------------------------------------------------

    function toGeopointString() {
        if (!isValid) {
            return;
        }

        return XFormJS.toCoordinateString(toObject());
    }

    //--------------------------------------------------------------------------

    function averageClear() {
        averageCount = -1;
        averaging = false;
    }

    //--------------------------------------------------------------------------

    function averageBegin() {
        averageCount = 0;
        averageStart = new Date();
        averageStop = averageStart;
        averaging = true;
    }

    //--------------------------------------------------------------------------

    function averageEnd() {
        if (!averaging) {
            return;
        }

        averaging = false;
        averageStop = new Date();
    }

    //--------------------------------------------------------------------------

    function averagePosition(position) {
        function averageValue(averagedValue, value) {
            return (averagedValue * averageCount + value) / (averageCount + 1);
        }

        latitude = averageValue(latitude, position.coordinate.latitude);
        longitude = averageValue(longitude, position.coordinate.longitude);

        if (position.altitudeValid) {
            altitude = averageValue(altitude, position.coordinate.altitude);
        }

        if (position.horizontalAccuracyValid) {
            horizontalAccuracy = averageValue(horizontalAccuracy, position.horizontalAccuracy);
        } else {
            horizontalAccuracy = Number.NaN;
        }

        if (position.verticalAccuracyValid) {
            verticalAccuracy = averageValue(verticalAccuracy, position.verticalAccuracy);
        } else {
            verticalAccuracy = Number.NaN;
        }

        averageCount++;

        changed();
    }

    //--------------------------------------------------------------------------

    function dump() {
        console.log("latitude:", latitude);
        console.log("longitude:", longitude);
        console.log("altitude:", altitudeValid, altitude);
        console.log("speed:", speedValid, speed);
        console.log("verticalSpeed:", verticalSpeedValid, verticalSpeed);
        console.log("direction:", directionValid, direction);
        console.log("magneticVariation:", magneticVariationValid, magneticVariation);
        console.log("verticalAccuracy:", verticalAccuracyValid, verticalAccuracy);
        console.log("horizontalAccuracy:", horizontalAccuracyValid, horizontalAccuracy);
        console.log("address:", addressValid, JSON.stringify(address, undefined, 2));
    }

    //    onChanged: {
    //        console.log(arguments.caller);
    //        dump();
    //    }

    //--------------------------------------------------------------------------
}
