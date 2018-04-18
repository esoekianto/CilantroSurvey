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

import QtQuick 2.9

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Item {
    property FileFolder imagesFolder

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kGpsLatitude: "gpslatitude"
    readonly property string kGpsLongitude: "gpslongitude"
    readonly property string kGpsAltitude: "gpsaltitude"
    readonly property string kGpsCoordinate: "gpscoordinate"

    readonly property string kGpsDestLatitude: "gpsdestlatitude"
    readonly property string kGpsDestLongitude: "gpsdestlongitude"
    readonly property string kGpsDestCoordinate: "gpsdestcoordinate"
    readonly property string kGpsDestDistance: "gpsdestdistance"

    //--------------------------------------------------------------------------

    function propertyValue(fileName, propertyName) {
        propertyName = propertyName.toLowerCase();

        if (debug) {
            console.log("Getting EXIF propertyValue fileName:", fileName, "propertyName:", propertyName);
        }

        var value;

        if (XFormJS.isEmpty(fileName)) {
            return value;
        }

        var fileInfo = imagesFolder.fileInfo(fileName);

        if (!fileInfo.exists) {
            console.warn("EXIF file not found:", fileInfo.url);
            return value;
        }

        var exifInfo = exifInfoComponent.createObject();

        if (!exifInfo.load(fileInfo.url)) {
            console.error("Error loading EXIF info:", fileInfo.url);
            exifInfo = undefined;
            gc();
            return value;
        }

        if (!exifInfo.isExifValid) {
            console.warn("No EXIF data:", fileInfo.url);
            return value;
        }

        switch (propertyName) {
        case kGpsLatitude :
            value = exifInfo.gpsLatitude;
            break;

        case kGpsLongitude :
            value = exifInfo.gpsLongitude;
            break;

        case kGpsAltitude :
            value = exifInfo.gpsAltitude;
            break;

        case kGpsCoordinate :
            value = geopoint(exifInfo.gpsLatitude, exifInfo.gpsLongitude, exifInfo.gpsAltitude);
            break;

        case kGpsDestLatitude :
            value = coord(exifInfo, ExifInfo.GpsDestLatitude, ExifInfo.GpsDestLatitudeRef);
            break;

        case kGpsDestLongitude :
            value = coord(exifInfo, ExifInfo.GpsDestLongitude, ExifInfo.GpsDestLongitudeRef);
            break;

        case kGpsDestCoordinate :
            value = geopoint(
                        coord(exifInfo, ExifInfo.GpsDestLatitude, ExifInfo.GpsDestLatitudeRef),
                        coord(exifInfo, ExifInfo.GpsDestLongitude, ExifInfo.GpsDestLongitudeRef));
            break;

        case kGpsDestDistance :
            value = destDistance(exifInfo);
            break;

        default:
            value = findTag(exifInfo, propertyName);
            if (typeof value === "object") {
                //console.log("EXIF Object value:", value);
                value = value.toString();
            }
            break;
        }

        if (debug) {
            console.log("Got EXIF propertyValue:", propertyName, "=", JSON.stringify(value));
        }

        exifInfo = undefined;
        gc();

        return value;
    }

    //--------------------------------------------------------------------------

    function geopoint(lat, lon, alt, accuracy) {
        return {
            type: "point",
            x: lon,
            y: lat,
            z: alt,
            horizontalAccuracy: accuracy,
            spatialReference: {
                wkid: 4326
            }
        };
    }

    //--------------------------------------------------------------------------

    function coord(exifInfo, tag, refTag) {
        var values = exifInfo.gpsValue(tag);
        if (XFormJS.isEmpty(values)) {
            return;
        }

        if (!Array.isArray(values)) {
            console.error("coord tag:", tag, "not an array:", JSON.stringify(values));
            return;
        }

        var ref = exifInfo.gpsValue(refTag);

        var value = values[0] + values[1] / 60 + values[2] / 3600;
        if (ref === "W" || ref === "S") {
            value = -value;
        }

        // console.log("tag:", tag, "=", JSON.stringify(values), "ref:", refTag, "=", ref, "value:", value);

        return value;
    }

    //--------------------------------------------------------------------------

    function destDistance(exifInfo) {
        var value = exifInfo.gpsValue(ExifInfo.GpsDestDistance);
        if (XFormJS.isEmpty(value)) {
            return;
        }

        var ref = exifInfo.gpsValue(ExifInfo.GpsDestDistanceRef);

        switch (ref) {
        case 'K': // Km
            value *= 1000;
            break;

        case 'M': // Miles
            value *= 1609.34;
            break;

        case 'M': // Nautical miles
            value *= 1852;
            break;
        }

        return Math.round(value * 1000) / 1000;
    }

    //--------------------------------------------------------------------------

    function findTag(exifInfo, name) {
        var value = searchTagSet(exifInfo.imageTags, exifInfo.imageTagName, exifInfo.imageValue, name);

        if (!XFormJS.isNullOrUndefined(value)) {
            return value;
        }

        value = searchTagSet(exifInfo.extendedTags, exifInfo.extendedTagName,  exifInfo.extendedValue, name);

        if (!XFormJS.isNullOrUndefined(value)) {
            return value;
        }

        value = searchTagSet(exifInfo.gpsTags, exifInfo.gpsTagName, exifInfo.gpsValue, name);

        if (!XFormJS.isNullOrUndefined(value)) {
            return value;
        }
    }

    function searchTagSet(tags, tagNameFunction, tagValueFunction, name) {
        //console.log("tags:", JSON.stringify(tags, undefined, 2));

        var keys = Object.keys(tags);
        for (var i = 0; i < keys.length; i++) {
            var tag = tags[keys[i]];

            if (Number(name) === tag) {
                return tagValueFunction(tag);
            }

            var tagName = tagNameFunction(tag);

            if (tagName.toLowerCase() === name) {
                return tagValueFunction(tag);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: exifInfoComponent

        ExifInfo {
            Component.onCompleted: {
                if (debug) {
                    console.log("ExifInfo completed");
                }
            }

            Component.onDestruction: {
                if (debug) {
                    console.log("ExifInfo destruction");
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}

