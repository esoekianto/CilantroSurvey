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
import QtQml 2.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "XForm.js" as XFormJS


QtObject {
    property var getValue
    property var getValues
    property var thisNodeset
    property string expression
    property var purpose
    property string jsExpression
    property var nodesets: []
    property bool debug
    property var errorResult
    property bool isOnce: false
    property bool isDeterministic: true
    property XFormExif exif

    property bool _bindingTrigger

    signal valueChanged(var nodeset, var value);

    readonly property real kMillisecondsPerDay: 86400000

    readonly property var nonDeterministicFunctions: [
        "now()",
        "today()",
        "random()"
    ]

    //--------------------------------------------------------------------------

    property var kAggregateFunctions: [
        "count",
        "sum",
        "min",
        "max",
        //        "join",
    ]

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (debug) {
            console.log("Expression instance:", expression);
            console.log("  jsExpression:", jsExpression);
            console.log("  thisNodeset:", thisNodeset);
            console.log("  nodesets:", JSON.stringify(nodesets));
            console.log("  purpose:", purpose);
        }
    }

    //--------------------------------------------------------------------------

    onValueChanged: {
        //        if (debug) {
        //            console.log("expression valueChanged:", nodeset, "value:", value);
        //        }

        if (!nodeset || nodesets.indexOf(nodeset) >= 0) {
            trigger();
        }
    }

    //--------------------------------------------------------------------------

    function trigger() {
        _bindingTrigger = !_bindingTrigger;
    }

    //--------------------------------------------------------------------------

    onExpressionChanged: update()
    onThisNodesetChanged: update()

    function update() {
        isOnce = expression.trim().substring(0, 5) === "once(" && thisNodeset > "";
        nodesets = [];
        jsExpression = translate(expression, thisNodeset, nodesets, _valueRef);

        if (isOnce && debug) {
            console.log("once expression for:", purpose, "nodeset:", thisNodeset, "expression:", expression);
        }

        isDeterministic = isDeterministicExpression(expression);

        if (debug) {
            console.log("isDeterministic:", isDeterministic, "expression:", expression);
        }
    }

    //--------------------------------------------------------------------------

    function isDeterministicExpression(text) {
        for (var i = 0; i < nonDeterministicFunctions.length; i++) {
            if (text.indexOf(nonDeterministicFunctions[i]) >= 0) {
                return false;
            }
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function _valueRef(nodeset, aggregate) {
        if (debug) {
            console.log("valueRef:", nodeset, "aggregate:", aggregate);
        }

        if (aggregate) {
            return '_values("%1")'.arg(nodeset);
        } else {
            return '_value("%1")'.arg(nodeset);
        }
    }

    //--------------------------------------------------------------------------

    function _value(nodeset) {
        if (!getValue) {
            console.error("getValue not defined");
            return undefined;
        }

        var value = getValue(nodeset);

        if (XFormJS.isNullOrUndefined(value)) {
            value = '';
        }

        if (debug) {
            console.log("_value:", typeof value, "nodeset:", nodeset, "=", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function _values(nodeset) {
        if (!getValues) {
            console.error("getValues not defined");
            return [];
        }

        var values = getValues(nodeset);

        if (!Array.isArray(values)) {
            values = [];
        }

        if (debug) {
            console.log("_values nodeset:", nodeset, "=", JSON.stringify(values));
        }

        return values;
    }

    //--------------------------------------------------------------------------

    function binding() {
        return Qt.binding(function () {
            return evaluate(errorResult, _bindingTrigger);
        });
    }

    //--------------------------------------------------------------------------

    function boolBinding(errorResult) {
        return Qt.binding(function () {
            return Boolean(evaluate(errorResult, _bindingTrigger));
        });
    }

    //--------------------------------------------------------------------------

    function numberBinding() {
        return Qt.binding(function () {
            return Number(evaluate(errorResult, _bindingTrigger));
        });
    }

    //--------------------------------------------------------------------------

    function nodesetValuesBinding() {
        return Qt.binding(function () {
            return nodesetValues(_bindingTrigger);
        });
    }

    //--------------------------------------------------------------------------

    function nodesetValues() {
        var values = {};

        nodesets.forEach(function (nodeset) {
            values[nodeset] = getValue(nodeset);
        });

        return values;
    }

    //--------------------------------------------------------------------------

    function evaluate(errorResult) {
        if (isOnce) {
            var value = getValue(thisNodeset);

            if (debug) {
                console.log("once:", purpose, "value:", value, "nodeset:", thisNodeset);
            }

            if (!XFormJS.isEmpty(value)) {
                return value;
            }
        }

        var result;

        try {
            result = eval(jsExpression);
        } catch (error) {
            console.error(error, 'in expression:', jsExpression, "xml expression:", expression);
            if (typeof errorResult !== "undefined") {
                result = errorResult;
            } else {
                result = "%1 in expression: %2".arg(error).arg(expression);
            }
        }

        if (debug) {
            console.log("evaluated:", result, "type:", typeof result, "from:", expression);
        }

        return result;
    }

    //--------------------------------------------------------------------------

    function tryEval(jsExpression, errorResult) {
        var result;

        try {
            result = eval(jsExpression);
        } catch (error) {
            console.error(error, 'in expression:', jsExpression);
            if (typeof errorResult !== "undefined") {
                result = errorResult;
            } else {
                result = "%1 in expression: %2".arg(error).arg(jsExpression);
            }
        }

        if (debug) {
            console.log("tryEval:", result, "type:", typeof result, "from:", jsExpression);
        }

        return result;
    }

    //--------------------------------------------------------------------------

    function translate(expression, thisNodeset, nodesets, valueCallback) {

        if (typeof valueCallback !== "function") {
            console.error("valueCallback not a function:", typeof valueCallback)
        }

        var expressionTokens = expression.match(/(['][^']*['])|([0-9A-Za-z_\-\/.']+)|./g);

        if (debug) {
            console.log("expression:", expression, "thisNodeset:", thisNodeset);
            console.log("expression tokens:", JSON.stringify(expressionTokens));
        }

        function addNodeset(nodeset) {
            if (!(nodeset > "")) {
                return;
            }

            if (Array.isArray(nodesets)) {
                if (nodesets.indexOf(nodeset) < 0) {
                    nodesets.push(nodeset);
                }
            }
        }

        function parentNode(nodeset) {
            if (!nodeset) {
                return "";
            }

            return nodeset.substr(0, nodeset.lastIndexOf('/'));
        }

        function inThisNodesetLevel(nodeset) {
            var thisParent = parentNode(thisNodeset);
            var nodeParent = parentNode(nodeset);

            // console.log("isSameLevel:", nodeParent === thisParent, "this:", thisParent, "node:", nodeParent);

            return thisParent === nodeParent;
        }

        var tokens = [];
        var inString;
        var stringToken;

        expressionTokens.forEach(function (element, index) {

            if (debug) {
                console.log("expressionToken:", element, "index:", index);
            }

            if (inString) {
                if (element === inString) {
                    if (debug) {
                        console.log("Exiting string:", inString, "value:", inString + stringToken + inString);
                    }

                    tokens.push(inString + stringToken + inString);
                    inString = undefined;
                } else {
                    if (debug) {
                        console.log("inString:", inString, "element:", element);
                    }

                    stringToken += element;
                }
                return;
            } else if (element === "'" || element === '"') {
                if (debug) {
                    console.log("Entering string:", inString);
                }

                inString = element;
                stringToken = "";
                return;
            }

            // In an aggregate function ?
            var aggregateFunction;
            if (index > 1) {
                index--;
                while (index > 0 && expressionTokens[index].trim().length <= 0) {
                    index--;
                }

                if (index > 0 && expressionTokens[index] === "(") {
                    if (kAggregateFunctions.indexOf(expressionTokens[index - 1]) >= 0) {
                        aggregateFunction = expressionTokens[index - 1];
                    }
                }
            }

            // Aggregate min/max only if not in same nodeset level

            var aggregate;
            if (aggregateFunction) {

                aggregate = (aggregateFunction === "min" || aggregateFunction === "max")
                        ? !inThisNodesetLevel(element)
                        : true;

                if (debug) {
                    console.log("aggregateFunction:", aggregateFunction, "aggregate:", aggregate);
                }
            }

            var token = element;

            switch (element.toLowerCase()) {
            case "=":
                token = "==";
                break;

            case "or":
                token = "||";
                break;

            case "and":
                token = "&&";
                break;

            case "mod":
                token = "%";
                break;

            case "div":
                token = "/";
                break;

            case ".":
                token = valueCallback(thisNodeset);
                addNodeset(thisNodeset);
                break;

            default:
                if (element.charAt(0) === '/') {
                    token = valueCallback(element, aggregate);
                    addNodeset(element);
                } else if (element.charAt(0) === '.') {
                    var nodeset = thisNodeset;
                    var nodeParent = parentNode(nodeset);
                    var relativeNode = nodeParent + element.substr(2);
                    //console.log("relative ref", element, "nodeset:", nodeset, "nodeParent:", nodeParent, "relativeNode:", relativeNode);
                    token = valueCallback(relativeNode);
                    addNodeset(relativeNode);
                } else if (element.charAt(0) === '\'') {
                    token = token.replace(/\\/g, "\\\\");
                }
                break;
            }

            tokens.push(token);
        });

        var translatedExpression = tokens.join("");

        // Quick hack until better regex is figured out

        translatedExpression = XFormJS.replaceAll(translatedExpression, "<==", "<=");
        translatedExpression = XFormJS.replaceAll(translatedExpression, ">==", ">=");
        translatedExpression = XFormJS.replaceAll(translatedExpression, "!==", "!=");
        translatedExpression = translatedExpression.replace(/string-length\(/g, "string_length(");
        translatedExpression = translatedExpression.replace(/count-selected\(/g, "count_selected(");
        translatedExpression = translatedExpression.replace(/decimal-date-time\(/g, "decimal_date_time(");
        translatedExpression = translatedExpression.replace(/decimal-date\(/g, "decimal_date(");
        translatedExpression = translatedExpression.replace(/decimal-time\(/g, "decimal_time(");
        translatedExpression = translatedExpression.replace(/format-date\(/g, "format_date(");
        translatedExpression = translatedExpression.replace(/date-time\(/g, "date_time(");
        translatedExpression = translatedExpression.replace(/boolean\(/g, "_boolean(");
        translatedExpression = translatedExpression.replace(/int\(/g, "_int(");
        translatedExpression = translatedExpression.replace(/if\(/g, "_if(");
        translatedExpression = translatedExpression.replace(/string\(/g, "_string(");
        translatedExpression = translatedExpression.replace(/true\(\)/g, "true");
        translatedExpression = translatedExpression.replace(/false\(\)/g, "false");

        if (debug) {
            console.log("expression tokens:", JSON.stringify(tokens));
            console.log("expression:", expression, "==>>", translatedExpression);
        }

        return translatedExpression;
    }

    //--------------------------------------------------------------------------
    // Expression functions
    // Ref: http://opendatakit.org/help/form-design/binding/
    //--------------------------------------------------------------------------

    function selected(array, value) {
        if (Array.isArray(array)) {
            return array.indexOf(value) >= 0;
        } else {
            return array == value;
        }
    }

    //--------------------------------------------------------------------------

    function count_selected(array) {
        if (Array.isArray(array)) {
            return array.length;
        } else {
            return array.toString() > "" ? 1 : 0;
        }
    }

    //--------------------------------------------------------------------------

    function _if(condition, a, b) {
        return condition ? a : b;
    }

    //--------------------------------------------------------------------------

    function _int(value) {
        return Math.floor(Number(value));
    }

    //--------------------------------------------------------------------------

    function _boolean(value) {
        return Boolean(value);
    }

    //--------------------------------------------------------------------------

    function not(value) {
        return !Boolean(value);
    }

    //--------------------------------------------------------------------------

    function number(value) {
        return Number(value);
    }

    //--------------------------------------------------------------------------

    function _string(value) {
        if (XFormJS.isEmpty(value)) {
            return "";
        }

        function objectToString() {
            if (value instanceof Date) {
                return Qt.formatDateTime(value, Qt.ISODate);
            }

            if (value.type) {
                switch (value.type) {
                case "point":
                case "geopoint":
                    return XFormJS.toCoordinateString(value);
                }
            }

            return JSON.stringify(value);
        }

        switch (typeof value) {
        case "object":
            return objectToString()
        default:
            return value.toString();
        }
    }

    //--------------------------------------------------------------------------

    function string_length(value) {
        //console.log("string-length:", value);

        return _string(value).length;
    }

    //--------------------------------------------------------------------------

    function concat() {
        //console.log("concat:", JSON.stringify(arguments));

        var text = "";

        for (var i = 0; i < arguments.length; i++) {
            text += _string(arguments[i]);
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function join() {
        var separator = arguments[0];
        var text = "";

        function joinValue(value) {
            if (text > "") {
                text += separator;
            }

            text += _string(value);
        }

        for (var i = 1; i < arguments.length; i++) {
            if (Array.isArray(arguments[i])) {
                arguments[i].forEach(function (value) {
                    joinValue(value);
                });
            } else {
                joinValue(arguments[i]);
            }
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function coalesce() {
        for (var i = 0; i < arguments.length; i++) {
            if (!XFormJS.isEmpty(arguments[i])) {
                return arguments[i];
            }
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function round(value, power) {
        var p = Math.pow(10, power);
        return Math.round(value * p) / p;
    }

    //--------------------------------------------------------------------------

    function pow(value, power) {
        return Math.pow(value, power);
    }

    //--------------------------------------------------------------------------

    function substr(value, start, end) {
        if (end) {
            return _string(value).substr(start, end - start);
        } else {
            return _string(value).substr(start);
        }
    }

    //--------------------------------------------------------------------------

    function regex(value, pattern) {
        return (new RegExp(pattern)).test(value);
    }

    //--------------------------------------------------------------------------

    function uuid() {
        return AppFramework.createUuidString(1);
    }

    //--------------------------------------------------------------------------

    function now() {
        return XFormJS.toDateValue(new Date());
    }

    //--------------------------------------------------------------------------

    function today() {
        return clearTimeValue(new Date());
    }

    //--------------------------------------------------------------------------

    function date(value) {
        return clearTimeValue(date_time(value));
    }

    //--------------------------------------------------------------------------

    function date_time(value) {
        if (typeof value === "number") {
            return XFormJS.toDateValue(value * kMillisecondsPerDay);
        } else {
            return XFormJS.toDateValue(value);
        }
    }

    //--------------------------------------------------------------------------

    function clearTime(dateValue) {
        if (XFormJS.isEmpty(dateValue)) {
            return;
        }

        var date = XFormJS.toDate(dateValue);

        return new Date(date.getFullYear(), date.getMonth(), date.getDate());
    }

    function clearTimeValue(date) {
        return XFormJS.toDateValue(clearTime(date));
    }

    //--------------------------------------------------------------------------

    function decimal_date_time(value) {
        var date = XFormJS.toDate(value);

        if (XFormJS.isEmpty(date)) {
            return;
        }

        return date.valueOf() / kMillisecondsPerDay;
    }

    //--------------------------------------------------------------------------

    function decimal_date(value) {
        var date = clearTime(value);

        if (XFormJS.isEmpty(date)) {
            return;
        }

        return date.valueOf() / kMillisecondsPerDay;
    }

    //--------------------------------------------------------------------------

    function decimal_time(value) {
        var date = XFormJS.toDate(value);

        if (XFormJS.isEmpty(date)) {
            return;
        }

        return date.getHours()
                + date.getMinutes()  / 60
                + (date.getSeconds() + date.getMilliseconds() / 1000)  / 3600;
    }

    //--------------------------------------------------------------------------
    // %y           2-digit year
    // %Y           4-digit year
    // %n           numeric month
    // %m           0-padded month
    // %b           3 letter short text month (3 char)
    // %e           day of month
    // %d           0-padded day of month
    // %a           Three letter short text day
    // %H           0-padded hour (24-hr time)
    // %h           hour (24-hr time)
    // %M           0-padded minute
    // %S           0-padded second
    // %3           0-padded millisecond ticks (000-999)
    // %Z %A %B     Unsupported
    // %W           Week number (Survey123 specific)

    function format_date(value, format) {
        var date = XFormJS.toDate(value);

        if (XFormJS.isEmpty(date)) {
            return "";
        }

        if (XFormJS.isEmpty(format)) {
            return date.toLocaleDateString(xform.locale);
        }

        // Special case for non-spec %W

        if (format.indexOf("%W") >= 0) {
            return format.replace("%W", XFormJS.weekNumber(date).toString());
        }

        var text = "";

        for (var i = 0; i < format.length; i++) {
            var c = format.charAt(i);

            if (c !== '%') {
                text += c;
                continue;
            }

            c = format.charAt(++i);
            if (c === '%') {
                text += c;
                continue;
            }

            switch (c) {
            case 'y':
                text += Qt.formatDate(date, "yy");
                break;

            case 'Y':
                text += Qt.formatDate(date, "yyyy");
                break;

            case 'n':
                text += Qt.formatDate(date, "M");
                break;

            case 'm':
                text += Qt.formatDate(date, "MM");
                break;

            case 'b':
                text += Qt.formatDate(date, "MMM").substr(0, 3);
                break;

            case 'e':
                text += Qt.formatDate(date, "d");
                break;

            case 'd':
                text += Qt.formatDate(date, "dd");
                break;

            case 'a':
                text += Qt.formatDate(date, "ddd").substr(0, 3);
                break;

            case 'h':
                text += Qt.formatTime(date, "h");
                break;

            case 'H':
                text += Qt.formatTime(date, "hh");
                break;

            case 'M':
                text += Qt.formatTime(date, "mm");
                break;

            case 'S':
                text += Qt.formatTime(date, "ss");
                break;

            case '3':
                text += Qt.formatTime(date, "zzz");
                break;

                // case 'W:
                // text += XFormJS.weekNumber(date).toString();
                // break;

            default:
                console.warn("format-date:", format, "Unhandled escape:", "'" + c + "'");
                break;
            }
        }

        //console.log("format-date:", value, "date:", date, "format:", format, "text:", text);

        return text;
    }

    //--------------------------------------------------------------------------
    // Trignometry

    function pi() {
        return Math.PI;
    }

    function cos(value) {
        return Math.cos(value);
    }

    function sin(value) {
        return Math.sin(value);
    }

    function tan(value) {
        return Math.tan(value);
    }

    function acos(value) {
        return Math.acos(value);
    }

    function asin(value) {
        return Math.asin(value);
    }

    function atan(value) {
        return Math.atan(value);
    }

    function atan2(y, x) {
        return Math.atan2(y, x);
    }

    //--------------------------------------------------------------------------
    // Other math

    function sqrt(value) {
        return Math.sqrt(value);
    }

    function exp(value) {
        return Math.exp(value);
    }

    function exp10(value) {
        return Math.exp(value * Math.LN10);
    }

    function log(value) {
        return Math.log(value);
    }

    function log10(value) {
        return Math.log(value) / Math.LN10;
    }

    function min(values) {
        var minValue;

        for (var i = 0; i < arguments.length; i++) {
            var value = arguments[i];
            if (Array.isArray(value)) {
                value = _arrayMin(value);
            }

            if (!XFormJS.isEmpty(value)) {
                if (minValue === undefined || value < minValue) {
                    minValue = value;
                }
            }
        }

        return minValue;
    }

    function max(values) {
        var maxValue;

        for (var i = 0; i < arguments.length; i++) {
            var value = arguments[i];
            if (Array.isArray(value)) {
                value = _arrayMax(value);
            }
            if (!XFormJS.isEmpty(value)) {
                if (maxValue === undefined || value > maxValue) {
                    maxValue = value;
                }
            }
        }

        return maxValue;
    }


    function random() {
        return Math.random();
    }

    //--------------------------------------------------------------------------
    // Nodeset aggregate functions

    function count(values) {
        return values.length;
    }

    function sum(values) {
        if (!values.length) {
            return;
        }

        var s;

        values.forEach(function(value) {
            if (typeof s === "undefined") {
                if (typeof value === "number") {
                    s = 0;
                } else {
                    s = "";
                }
            }

            s += value;
        });

        return s;
    }

    function _arrayMin(values) {
        if (!values.length) {
            return;
        }

        var m = values[0];
        values.forEach(function(value) {
            if (value < m) {
                m = value;
            }
        });

        return m;
    }

    function _arrayMax(values) {
        if (!values.length) {
            return;
        }

        var m = values[0];
        values.forEach(function(value) {
            if (value > m) {
                m = value;
            }
        });

        return m;
    }

    //--------------------------------------------------------------------------

    function version() {
        return xform.version;
    }

    //--------------------------------------------------------------------------

    function pulldata(sourceName) {
        if (sourceName.charAt(0) === "@") {
            var typeName = sourceName.substring(1);

            switch (typeName) {
            case "geopoint":
                return pulldata_geopoint(arguments[1], arguments[2]);

            case "exif":
                return pulldata_exif(arguments[1], arguments[2]);

            case "json":
                return pulldata_json(arguments[1], arguments[2]);

            case "javascript":
                return pulldata_javascript(arguments);

            case "property":
                return pulldata_property(arguments[1]);

            default:
                console.error("Unknown pulldata type name:", typeName);
                return;
            }
        }

        if (arguments.length < 4) {
            console.error("pulldata requires 4 parameters", arguments.length);
            return;
        }

        return pulldata_list(sourceName, arguments[1], arguments[2], arguments[3]);
    }

    //--------------------------------------------------------------------------

    function pulldata_list(listName, nameField, keyField, keyValue) {
        var dataList = dataLists.getList(listName);
        if (!dataList) {
            return "";
        }

        var data = dataList.data;
        for (var i = 0; i < data.length; i++) {
            if (data[i][keyField] === keyValue) {
                return data[i][nameField];
            }
        }

        return "";
    }

    //--------------------------------------------------------------------------

    function pulldata_geopoint(geopoint, propertyName) {
        if (typeof geopoint === "string") {
            geopoint = XFormJS.parseCoordinate(geopoint);
        }

        if (typeof geopoint !== "object") {
            console.error("geopoint is not an object:", typeof geopoint, geopoint);
            return;
        }

        switch (propertyName) {
        case "longitude":
        case "lon":
            propertyName = "x";
            break;

        case "latitude":
        case "lat":
            propertyName = "y";
            break;

        case "altitude":
        case "alt":
            propertyName = "z";
            break;

        case "accuracy":
            propertyName = "horizontalAccuracy";
            break;

        case "sog":
            propertyName = "speed";
            break;

        case "cog":
            propertyName = "direction";
            break;
        }

        //        var value = geopoint[propertyName];
        var value = XFormJS.getPropertyPathValue(geopoint, propertyName);

        if (debug) {
            console.log("propertyName:", propertyName, "=", value, "geopoint:", JSON.stringify(geopoint));
        }

        switch (typeof value) {
        case "number":
            return  isFinite(value) ? value : undefined;

        case "object":
            return value ? JSON.stringify(object) : undefined;

        default:
            return value;
        }
    }

    //--------------------------------------------------------------------------

    function pulldata_exif(imageName, propertyName) {
        //console.log("pulldata_exif:", imageName, propertyName);

        return exif.propertyValue(imageName, propertyName);
    }

    //--------------------------------------------------------------------------

    function pulldata_json(jsonValue, propertyPath) {
        // console.log("pulldata_json:", typeof jsonValue, jsonValue, propertyPath);

        if (XFormJS.isNullOrUndefined(jsonValue) || XFormJS.isNullOrUndefined(propertyPath)) {
            return;
        }

        var json;

        if (typeof jsonValue === "object") {
            json = jsonValue;
        } else {
            if (typeof jsonValue !== "string") {
                console.error("pulldata_json: Not a string:", typeof jsonValue, jsonValue);
                return;
            }

            try {
                json = JSON.parse(jsonValue);
            } catch (error) {
                console.error("pulldata_json:", error, 'parsing:', jsonValue);
            }

            if (!json) {
                return;
            }
        }

        var value = XFormJS.getPropertyPathValue(json, propertyPath);

        // console.log("pulldata_json:", path[path.length - 1], "=", value);

        return value;
    }

    //--------------------------------------------------------------------------

    function pulldata_javascript(arguments) {
        if (!xform.extensionsEnabled) {
            console.warn("pulldata_javascript extensions disabled");
            return "Extensions disabled";
        }

        //console.log("pulldata_javascript:", JSON.stringify(arguments));

        var jsFileName = arguments[1];
        var jsFunction = arguments[2];

        var jsUrl = extensionsFolder.fileUrl(jsFileName);
        var jsObject = expressionsList.jsCache[jsFileName];

        if (!jsObject) {
            console.log("@javascript url:", jsUrl);

            var jsSource = "import QtQml 2.2;\r\nimport \"%1\" as JS;\r\nQtObject {\r\n\tfunction evaluate(e) {\r\n\t\treturn eval(e);\r\n\t}\r\n}".arg(jsUrl);

            if (debug) {
                console.log("Creating @javascript component:", jsSource);
            }

            jsObject = Qt.createQmlObject(jsSource, expressionsList, extensionsFolder.path);

            expressionsList.jsCache[jsFileName] = jsObject;
        }

        var expression = "JS." + jsFunction + "(";

        for (var i = 3; i < arguments.length; i++) {
            if (i > 3) {
                expression += ", ";
            }

            var value = JSON.stringify(arguments[i]);

            expression += value;
        }

        expression += ");";

        if (debug) {
            console.log("pulldata_javascript:", jsFileName, "expression:", expression);
        }

        try {
            value = jsObject.evaluate(expression);
        } catch (error) {
            console.error(error, 'in expression:', jsExpression);
            value = "@javascript error:%1 in %2:%3".arg(error).arg(jsFileName).arg(jsFunction);
        }

        if (debug) {
            console.log("pulldata_javascript:", jsFunction, "=", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function pulldata_property(name) {
        if (typeof name !== "string") {
            console.warn("Invalid @property:", JSON.stringify(name));
            return;
        }

        if (!name.length) {
            return;
        }

        name = name.toLowerCase();

        var value;

        switch (name) {
        case "online":
            value = AppFramework.network.isOnline; //Networking.isOnline; @TODO
            break;

        case "portalurl":
            value = app.portal.portalUrl.toString();
            break;

        case "portalinfo":
            value = app.portal.info;
            break;

        case "token":
            value = app.portal.token > "" ? app.portal.token : undefined;
            break;

        case "owningsystemurl":
            value = app.portal.owningSystemUrl.toString();
            break;

        case "utcoffset":
            value = - new Date().getTimezoneOffset() / 60;
            break;

        case "timezone":
            value = Qt.formatDateTime(new Date(), "t");
            break;

        case "language":
            value = xform.language;
            break;

        case "locale":
            value = xform.locale;
            break;

        case "localeinfo":
            value = AppFramework.localeInfo(xform.locale.name);
            break;

        default:
            console.warn("Unknown @property:", name);
            value = "Unknown @property: %1".arg(name);
            break;
        }

        if (true) {//debug) {
            console.log("@property:", name, "value:", JSON.stringify(value, undefined, 2));
        }

        return value;
    }

    //--------------------------------------------------------------------------
    // Special handling required

    function once(value) {
        return value;
    }

    //--------------------------------------------------------------------------

    function property(name) {
        return XFormJS.systemProperty(app, name);
    }

    //--------------------------------------------------------------------------
}
