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

.pragma library
.import QtQml 2.2 as QML
.import ArcGIS.AppFramework 1.0 as AF


//------------------------------------------------------------------------------

var options = {
    coords: {
        shortPrecision: 3,
        longPrecision: 6,
        minutesPrecision: 6,
        secondsPrecision: 3,
        east: "E",
        west: "W",
        north: "N",
        south: "S"
    }
};

//------------------------------------------------------------------------------

function replaceAll(string, find, replace) {
    //console.log("replaceAll string:", string, "find:", find, "replace:", replace);
    return string.replace(new RegExp(find, 'g'), replace);
}

//------------------------------------------------------------------------------

function endsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

//------------------------------------------------------------------------------

function attribute(node, name, defaultValue) {
    var value = node['@' + name];
    if (typeof value === 'undefined') {
        return defaultValue;
    } else {
        return value;
    }
}

//------------------------------------------------------------------------------

function nodeName(text) {
    var index = text.indexOf('[');
    if (index < 0) {
        return text;
    } else {
        return text.substr(0, index);
    }
}

//------------------------------------------------------------------------------

function nodeIndex(text) {
    var match = text.match(/[^\[]*\[(.*)\]/);
    return match ? match[1] : -1;
}

//------------------------------------------------------------------------------

function childNode(parentNode, childName) {
    var name = nodeName(childName);
    var index = nodeIndex(childName);

    var node;

    if (index >= 0) {
        node = parentNode[name][index];
    } else {
        node = parentNode[name];
    }

    return node;
}

//------------------------------------------------------------------------------

function childElements(parentNode) {
    var elements = [];
    var nodes = parentNode["#nodes"];

    if (!nodes) {
        return elements;
    }

    for (var i = 0; i < nodes.length; i++) {
        var name = nodes[i];
        if (name.charAt(0) === '#') {
            continue;
        }

        var node = childNode(parentNode, name);
        switch (typeof node) {
        case "object":
            if (node) {
                node["#tag"] = name;
            } else {
                node = {
                    "#tag": name
                };
            }
            break;

        default:
            var newNode = {
                "#tag": name,
                "#text:": node
            };
            node = newNode;
            break;
        }

        elements.push(node);
    }

    return elements;
}

//------------------------------------------------------------------------------

function hasChildElements(parentNode) {
    var elements = 0;
    var nodes = parentNode["#nodes"];
    if (!nodes) {
        return false;
    }

    for (var i = 0; i < nodes.length; i++) {
        var name = nodes[i];
        if (name.charAt(0) === '#') {
            continue;
        }

        elements++;
    }

    return elements > 0;
}

//------------------------------------------------------------------------------

function esriFieldType(type) {
    if (!type) {
        return undefined;
    }

    switch (type.toLowerCase()) {
    case "string":
    case "select":
    case "select1":
    case "text":
    case "note":
        return "esriFieldTypeString";

    case "int":
    case "integer":
        return "esriFieldTypeInteger";

    case "decimal":
        return "esriFieldTypeDouble";

    case "date":
    case "datetime":
        return "esriFieldTypeDate";

    case "time":
        return "esriFieldTypeString";

    case "uuid":
        return "esriFieldTypeGUID";

    case "geopoint":
    case "geotrace":
    case "geoshape":
        return "esriFieldTypeGeometry";

    case "binary":
        return "esriFieldTypeBlob";

    default:
        console.warn("Unhandled type", type);
        return "esriFieldTypeString";
    }
}

//------------------------------------------------------------------------------

function esriGeometryType(type) {
    if (!type) {
        return undefined;
    }

    switch (type.toLowerCase()) {
    case "geopoint":
        return "esriGeometryPoint";

    case "geotrace":
        return "esriGeometryPolyline";

    case "geoshape":
        return "esriGeometryPolygon";

    default:
        return undefined;
    }
}

//------------------------------------------------------------------------------

function geometryTypeHasZ(type) {
    var hasZ = false;

    switch(type) {
    case "esriFieldTypePointZ":
    case "esriFieldTypePointZM":
    case "esriFieldTypePolylineZ":
    case "esriFieldTypePolylineZM":
    case "esriFieldTypePolygonZ":
    case "esriFieldTypePolygonZM":
        hasZ = true;
        break;
    }

    return hasZ;
}

//------------------------------------------------------------------------------

function geometryTypeHasM(type) {
    var hasM = false;

    switch(type) {
    case "esriFieldTypePointM":
    case "esriFieldTypePointZM":
    case "esriFieldTypePolylineM":
    case "esriFieldTypePolylineZM":
    case "esriFieldTypePolygonM":
    case "esriFieldTypePolygonZM":
        hasM = true;
        break;
    }

    return hasM;
}

//------------------------------------------------------------------------------

function geometryDimension(type) {

    switch (type) {
    case "esriGeometryPoint":
    case "geopoint":
        return 0;

    case "esriGeometryPolyline":
    case "geotrace":
        return 1;

    case "esriGeometryPolygon":
    case "geoshape":
        return 2;
    }

    if (type.indexOf("esriFieldTypePoint") === 0) {
        return 0;
    }

    if (type.indexOf("esriFieldTypePolyline") === 0) {
        return 1;
    }

    if (type.indexOf("esriFieldTypePolygon") === 0) {
        return 2;
    }
    return -1;
}

//------------------------------------------------------------------------------

function toDate(value) {
    return (value instanceof Date)
            ? value
            : parseDate(value);
}

//------------------------------------------------------------------------------

function toDateValue(value) {
    return toDate(value).valueOf();
}

//------------------------------------------------------------------------------

function parseDate(value) {
    var date;

    switch (value) {
    case "today()":
        date = new Date();
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
        date.setMilliseconds(0);
        break;

    case "now()":
        date = new Date();
        break;

    default:
        date = new Date(value);
        break;
    }

    if (typeof value ==="string" && !isFinite(date.valueOf())) {
        var hhmmss = value.match(/^([0-1]?\d|2[0-3])(?::([0-5]?\d))?(?::([0-5]?\d))?$/);
        if (Array.isArray(hhmmss)) {
            date = new Date(0);
            date.setHours(hhmmss[1]);
            date.setMinutes(hhmmss[2] ? hhmmss[2] : 0);
            date.setSeconds(hhmmss[3] ? hhmmss[3] : 0);
            date.setMilliseconds(0);
        } else {
            date = new Date(parseInt(value));
        }
    }

    // console.log("parseDate:", value, "date:", date);

    return date;
}

//--------------------------------------------------------------------------

function formatDate(date, appearance, locale) {
    if (!date || !(date instanceof Date)) {
        return "";
    }

    if (!isFinite(date.valueOf())) {
        return "";
    }

    switch (appearance) {
    case "week":
    case "week-number":
        return qsTr("Week %1").arg(weekNumber(date));

    case "iso":
        return Qt.formatDate(date, Qt.ISODate);

    case "rfc2822":
        return Qt.formatDate(date, Qt.RFC2822Date);

    case "short":
        return locale
                ? date.toLocaleDateString(locale, QML.Locale.ShortFormat)
                : Qt.formatDate(date, Qt.DefaultLocaleShortDate);

    case "long":
        return locale
                ? date.toLocaleDateString(locale, QML.Locale.LongFormat)
                : Qt.formatDate(date, Qt.DefaultLocaleLongDate);

    case "default":
    default:
        return locale
                ? date.toLocaleDateString(locale, QML.Locale.LongFormat)
                : Qt.formatDate(date, Qt.DefaultLocaleLongDate);
    }
}

//--------------------------------------------------------------------------

function weekNumber(date) {
    if (typeof date === "number") {
        date = new Date(date);
    }

    return getWeek(date, 1);
}

//--------------------------------------------------------------------------
// Source http://www.epoch-calendar.com/support/getting_iso_week.html

function getWeek(date, dowOffset) {
    /* The original getWeek() was developed by Nick Baicoianu at MeanFreePath: http://www.epoch-calendar.com */

    dowOffset = typeof(dowOffset) === 'number' ? dowOffset : 0; //default dowOffset to zero
    var newYear = new Date(date.getFullYear(),0,1);
    var day = newYear.getDay() - dowOffset; //the day of week the year begins on
    day = (day >= 0 ? day : day + 7);
    var daynum = Math.floor((date.getTime() - newYear.getTime() -
                             (date.getTimezoneOffset()-newYear.getTimezoneOffset())*60000)/86400000) + 1;
    var weeknum;
    //if the year starts before the middle of a week
    if(day < 4) {
        weeknum = Math.floor((daynum+day-1)/7) + 1;
        if(weeknum > 52) {
            nYear = new Date(date.getFullYear() + 1,0,1);
            nday = nYear.getDay() - dowOffset;
            nday = nday >= 0 ? nday : nday + 7;
            /*if the next year starts before the middle of
              the week, it is week #1 of that year*/
            weeknum = nday < 4 ? 1 : 53;
        }
    }
    else {
        weeknum = Math.floor((daynum+day-1)/7);
    }
    return weeknum;
};

//--------------------------------------------------------------------------

function formatTime(date, appearance, locale) {
    if (!date || !(date instanceof Date)) {
        return "";
    }

    if (!isFinite(date.valueOf())) {
        return "";
    }

    switch (appearance) {
    case "long":
        return locale
                ? date.toLocaleTimeString(locale, QML.Locale.LongFormat)
                : Qt.formatTime(date, Qt.DefaultLocaleShortDate);

    case "default":
    case "short":
    default:
        return locale
                ? date.toLocaleTimeString(locale, QML.Locale.ShortFormat)
                : Qt.formatTime(date, Qt.DefaultLocaleShortDate);
    }
}

//--------------------------------------------------------------------------

function replacePlaceholders(expression, values) {

    var fieldTokens = expression.match(/\$\{(.+?)\}/g);

    var text = expression;

    if (!fieldTokens) {
        return text;
    }

    fieldTokens.forEach(function (field) {
        var fieldName = field.substr(2, field.length - 3).trim();
        var value = values[fieldName];

        if (value === undefined || value === null) {
            value = "";
        }

        //console.log("field", field, fieldName, "value", value, JSON.stringify(attributes, undefined, 2));

        text = text.replace(field, value.toString());
    });

    return text;
}

//------------------------------------------------------------------------------

// dd    Decimal degrees - long
// d     Decimal degrees - short
// dmss  Degrees Minutes Seconds - long
// dms
// dmm   Degrees Minutes - long
// dm    Degrees Minutes - short

function formatLatitude(latitude, coordinateFormat) {
    switch (coordinateFormat) {
    case "dd":
        return dd(latitude, options.coords.north, options.coords.south, options.coords.longPrecision);

    case "d":
        return dd(latitude, options.coords.north, options.coords.south, options.coords.shortPrecision);

    case "dmss":
    default:
        return dms(latitude, options.coords.north, options.coords.south);

    case "dmm":
        return dmm(latitude, options.coords.north, options.coords.south);

    case "dm":
        return dm(latitude, options.coords.north, options.coords.south);
    }
}

function formatLongitude(longitude, coordinateFormat) {
    switch (coordinateFormat) {
    case "dd":
        return dd(longitude, options.coords.east, options.coords.west, options.coords.longPrecision);

    case "d":
        return dd(longitude, options.coords.east, options.coords.west, options.coords.shortPrecision);

    case "dmss":
    default:
        return dms(longitude, options.coords.east, options.coords.west);

    case "dmm":
        return dmm(longitude, options.coords.east, options.coords.west);

    case "dm":
        return dm(longitude, options.coords.east, options.coords.west);
    }
}

//------------------------------------------------------------------------------

function dd(value, pos, neg, precision) {
    var isNeg = value < 0;
    value = Math.abs(value);

    return value.toFixed(precision) + "°" + (isNeg ? neg : pos);
}

function dm(value, pos, neg) {
    var isNeg = value < 0;
    value = Math.abs(value);
    var d = Math.floor(value);
    value = (value - d) * 60;
    var m = Math.round(value);

    return d.toString() + "°" + m.toString() + "'" + (isNeg ? neg : pos);
}

function dms(value, pos, neg) {
    var isNeg = value < 0;
    value = Math.abs(value);
    var d = Math.floor(value);
    value = (value - d) * 60;
    var m = Math.floor(value);
    var s = (value - m) * 60;

    return d.toString() + "°" + m.toString() + "'" + s.toFixed(options.coords.secondsPrecision) + "\"" + (isNeg ? neg : pos);
}

function dmm(value, pos, neg) {
    var isNeg = value < 0;
    value = Math.abs(value);
    var d = Math.floor(value);
    var m = (value - d) * 60;

    return d.toString() + "°" + m.toFixed(options.coords.minutesPrecision) + "'" + (isNeg ? neg : pos);
}

//------------------------------------------------------------------------------

function inRange(value, min, max) {
    return value >= min && value <= max;
}

//------------------------------------------------------------------------------
// GeoODK coordinate format: space-separated list of valid
//                              latitude (decimal degrees),
//                              longitude (decimal degrees),
//                              altitude (decimal meters)
//                              and accuracy (decimal meters)

function parseCoordinate(text) {

    var coordinate = {
        isValid: false,
        latitude: Number.NaN,
        longitude: Number.NaN,
        altitude: Number.NaN,
        horizontalAccuracy: Number.NaN
    }

    if (!text) {
        return coordinate;
    }

    var splitText = text.split(" ");
    if (!splitText.length) {
        return coordinate;
    }

    var values = [];

    for (var i = 0; i < splitText.length; i++) {
        var value = splitText[i].toString().trim();
        if (value > "") {
            value = Number(value)
            if (!isNaN(value)) {
                values.push(value);
            }
        }
    }

    if (values.length < 2) {
        console.log("Insufficient values:", text, JSON.stringify(values));
        return coordinate;
    }

    if (inRange(values[0], -90, 90) && inRange(values[1], -180, 180)) {
        coordinate.latitude = values[0];
        coordinate.longitude = values[1];
        coordinate.isValid = true;
        //        coordinate.spatialReference = {
        //            wkid: 4326
        //        }
    } else {
        console.log("Invalid lat/lon values:", text, JSON.stringify(values));
        return coordinate;
    }

    if (values.length > 2) {
        coordinate.altitude = values[2];
    }

    if (values.length > 3) {
        coordinate.horizontalAccuracy = values[3];
    }

    // console.log("coordinate:", text, "=>", JSON.stringify(coordinate));

    return coordinate;
}

//------------------------------------------------------------------------------

function parsePoly(text) {
    var poly = [];

    if (!text) {
        return poly;
    }

    var splitText = text.split(";");
    if (!splitText.length) {
        return poly;
    }

    for (var i = 0; i < splitText.length; i++) {
        var value = splitText[i].toString().trim();
        if (value > "") {
            var coordinate = parseCoordinate(value);

            if (coordinate.isValid) {
                poly.push(coordinate);
            }
        }
    }

    return poly;
}

//------------------------------------------------------------------------------

function toBoolean(value, defaultValue) {

    switch (typeof value) {
    case "boolean":
        return value;

    case "number":
        return value !== 0;
    }

    if (typeof defaultValue !== "boolean") {
        defaultValue = false;
    }

    if (value === undefined) {
        return defaultValue;
    }

    if (!value) {
        return false;
    }

    var s = value.toString().toLowerCase();

    switch (s) {
    case "1":
    case "t":
    case "true":
    case "true()":
    case "y":
    case "yes":
        return true;

    case "0":
    case "f":
    case "false":
    case "false()":
    case "n":
    case "no":
    case "null":
        return false;
    }

    return defaultValue;
}

//------------------------------------------------------------------------------

function toNumber(value, defaultValue) {
    var number = Number(value);

    return isFinite(number) ? number : defaultValue;
}

//------------------------------------------------------------------------------
// GeoODK coordinate format: space-separated list of valid
//                              latitude (decimal degrees),
//                              longitude (decimal degrees),
//                              altitude (decimal meters)
//                              and accuracy (decimal meters)

function toCoordinateString(coordinate) {
    function getValue(names) {
        for (var i = 0; i < names.length; i++) {
            var value = coordinate[names[i]];
            if (isFinite(value)) {
                return value;
            }
        }
    }

    var x = getValue(["x", "latitude", "lon"]);
    var y = getValue(["y", "longitude", "lat"]);

    if (!isFinite(x) && !isFinite(y)) {
        return;
    }

    var text = "%1 %2".arg(y.toString()).arg(x.toString());

    var z = getValue(["z", "altitude", "alt"]);
    var a = getValue(["horizontalAccuracy", "accuracy"]);

    if (isFinite(z) || isFinite(a)) {
        text += " %1".arg(isFinite(z) ? z.toString() : 0);
    }

    if (isFinite(a)) {
        text += " " + a.toString();
    }

    return text;
}

//------------------------------------------------------------------------------

function isNullOrUndefined(value) {
    return value === null || value === undefined;
}

//------------------------------------------------------------------------------

function isEmpty(value) {
    switch (typeof value) {
    case "undefined":
        return true;

    case "string":
        return value.length === 0;

    case "object":
        if (value instanceof Date) {
            return !isFinite(value.valueOf());
        } else if (Array.isArray(value)) {
            return !value.length;
        } else {
            return value === null || Object.keys(value) === 0 || isNullGeometry(value);
        }

    case "number":
        return !isFinite(value);

    default:
        return false;
    }
}

//------------------------------------------------------------------------------

function isNullGeometry(value) {
    if (!value || typeof value !== "object") {
        return true;
    }

    if (!value.type || value.type === "point") {
        return !(isFinite(value.x) && isFinite(value.y) && value.x && value.y);
    }

    console.error("isNullGeometry (unhandled value):", JSON.stringify(value, undefined, 2));

    return false;
}

//------------------------------------------------------------------------------

function toBindingType(value, binding) {
    if (!binding) {
        console.error("toBindingType empty binding for:", value);

        return value;
    }

    var bindingType = binding["@type"];

    if (isEmpty(value)) {
        switch (bindingType) {
        case "int":
        case "decimal":
            value = Number.NaN;
            break;

        case "date":
        case "dateTime":
        case "time":
            value = Number.NaN; //new Date(Number.NaN);
            break;

        case "barcode":
        case "string":
        default:
            value = undefined;
        }

        return value;
    }


    switch (bindingType) {
    case "int":
        value = Number(value);
        if (isFinite(value)) {
            value = Math.round(value);
        } else {
            value = Number.NaN;
        }
        break;

    case "decimal":
        value = Number(value);
        if (!isFinite(value)) {
            value = Number.NaN;
        }
        break;

    case "date":
    case "dateTime":
    case "time":
        return toDateValue(value);

    case "barcode":
    case "string":
        return value.toString()
    }

    if (isNullOrUndefined(value)) {
        return;
    }

    return value;
}

//------------------------------------------------------------------------------

function clone(value) {
    if (value === null || typeof value !== 'object') {
        return value;
    }

    if (value instanceof Date) {
        return new Date(value.valueOf());
    }

    // var object = JSON.parse(JSON.stringify(value));

    var object = value.constructor();

    for (var key in value) {
        object[key] = clone(value[key]);
    }

    return object;
}

//------------------------------------------------------------------------------

function systemProperty(app, name) {

    function uri(scheme, value) {
        return value > "" ? scheme + ":" + value : undefined;
    }

    var value

    switch (name) {
    case "deviceid":
        value = deviceProperty(app, "udid");
        break;

    case "uri:deviceid":
        value = uri(Qt.platform.os, deviceProperty(app, "udid"));
        break;

    case "subscriberid":
    case "uri:subscriberid": // imsi:<imsd>
        break;

    case "simserial":
    case "uri:simserial": // simserial:<simserial>
        break;

    case "phonenumber":
    case "uri:phonenumber": //tel:
        break;

    case "username":
        value = userProperty(app, 'username');
        break;

    case "uri:username":
        value = uri("username", userProperty(app, 'username'));
        break;

    case "email":
        value = userProperty(app, 'email');
        break;

    case "uri:email":
        value = uri("mailto", userProperty(app, 'email'));
        break;
    }

    console.log("systemProperty:", name, "value:", value);

    return value;
}

//--------------------------------------------------------------------------

function deviceProperty(app, name) {

    function udid() {
        var udid = app.settings.value("udid", "");
        if (!(udid > "")) {
            udid = AF.AppFramework.createUuidString(2);
            app.settings.setValue("udid", udid);
        }

        return udid;
    }

    switch (name) {
    case "udid":
        return udid();
    }
}

//--------------------------------------------------------------------------

function userProperty(app, name) {
    var userInfo = app.userInfo;

    if (!userInfo) {
        return;
    }

    return userInfo[name];
}

//--------------------------------------------------------------------------

function contains(values, value, separator) {
    if (Array.isArray(values)) {
        return values.indexOf(value) >= 0;
    }

    if (typeof values !== "string") {
        return false;
    }

    if (typeof separator !== "string") {
        separator = " ";
    }

    return values.split(separator).indexOf(value) >= 0;
}

//--------------------------------------------------------------------------

function asArray(object) {
    if (!object) {
        return object;
    }

    if (Array.isArray(object)) {
        return object;
    }

    return [object];
}

//------------------------------------------------------------------------------
// Workaround for backward compatibility with AppStudio 1.3

function encode(value) {
    var version = AF.AppFramework.version.split(".");

    return version[0] === "1" && version[1] <= "3"
            ? encodeURIComponent(value)
            : value;
}

//------------------------------------------------------------------------------

function dequote(value) {
    if (typeof value !== "string") {
        return value;
    }

    if (value.length < 2) {
        return value;
    }

    var cFirst = value.charAt(0);
    var cLast = value.charAt(value.length - 1);

    if ((cFirst === cLast) && "\"'".indexOf(cFirst) >= 0) {
        return value.substring(1, value.length - 1);
    } else {
        return value;
    }
}

//------------------------------------------------------------------------------

function parseParameters(text, toLowerCase) {
    var params = {};

    if (!text) {
        return params;
    }

    var tokens = text.match(/(([^\s]+)=\s*(?:"((?:\\.|[^"])*)"|([^\s]*)))|([^\s]+)/g);

    if (!tokens || !tokens.length) {
        console.warn(arguments.callee.name, "Empty tokens array");
        return params;
    }

    tokens.forEach(function (token) {
        token = token.trim();

        console.log("token:", token);

        if (isEmpty(token)) {
            return;
        }

        var key;

        var separator = token.indexOf("=");
        if (separator < 1) {
            key = token;
            if (toLowerCase) {
                key = key.toLowerCase();
            }
            params[key] = true;
            return;
        }

        key = token.substring(0, separator).trim();
        var value = token.substring(separator + 1);

        if (isEmpty(key)) {
            console.warn(arguments.callee.name, "Empty key:", key);
            return;
        }

        if (toLowerCase) {
            key = key.toLowerCase();
        }

        params[key] = dequote(value);
    });


    // console.log("parseParamaters:", text, "params:", JSON.stringify(params, undefined, 2));

    return params;
}

//------------------------------------------------------------------------------

function encodeHTMLEntities(str){
    // only handles '<' currently
    var regex = /<(?=\d)|<(?=\s)/g;
    var outStr = str.replace(regex, "&lt;")
    return outStr;
}

//--------------------------------------------------------------------------

function getPropertyPathValue(object, propertyPath) {

    var path = propertyPath.split(/\[\]\.|\[\]|\]\.|\.|\[|\]/);
    if (path.length < 1) {
        console.error("getPropertyPath: Invalid property path:", propertyPath);
        return;
    }

    var jsonObject = object;

    for (var i = 0; i < path.length - 1; i++) {
        // console.log("getPropertyPath: jsonObject:", i, path[i], JSON.stringify(jsonObject));

        jsonObject = jsonObject[path[i]];
        if (!jsonObject) {
            return;
        }
    }

    var value = jsonObject[path[path.length - 1]];

    // console.log("getPropertyPath:", path[path.length - 1], "=", value);

    return value;
}

//------------------------------------------------------------------------------
