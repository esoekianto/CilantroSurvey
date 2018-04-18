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

.import ArcGIS.AppFramework 1.0 as ArcGISAppFramework

//------------------------------------------------------------------------------

function findFirstSuffix(folder, baseName, suffixes) {
    for (var i = 0; i < suffixes.length; i++) {
        var fileName = baseName + "." + suffixes[i];
        if (folder.fileExists(fileName)) {
            return fileName;
        }
    }

    return "";
}

//------------------------------------------------------------------------------

function findThumbnail(folder, baseName, defaultThumbnail) {
    var fileName = findFirstSuffix(folder, baseName, ["png", "jpg", "gif"]);

    if (fileName > "") {
        return folder.fileUrl(fileName).toString();
    }

    return defaultThumbnail ? defaultThumbnail : "";
}

//------------------------------------------------------------------------------

function resolveSurveyPath(filePath, surveysFolder) {
    var surveyPath = ArcGISAppFramework.AppFramework.resolvedPath(filePath);

    var fileInfo = ArcGISAppFramework.AppFramework.fileInfo(surveyPath);
    if (fileInfo.exists) {
        return surveyPath;
    }

    var packageFolder = ArcGISAppFramework.AppFramework.fileFolder(fileInfo.path);

    var relativeName;
    if (packageFolder.folderName === "esriinfo") {
        packageFolder.path = packageFolder.path.replace(/esriinfo$/, "");
        relativeName = packageFolder.folderName + "/esriinfo/" + fileInfo.fileName;
    } else {
        relativeName = packageFolder.folderName + "/" + fileInfo.fileName;
    }

    var packageName = packageFolder.folderName;

    console.log("resolveSurveyPath:", surveyPath, "packageName:", packageName, "relativeName:", relativeName);

    if (surveysFolder.fileExists(relativeName)) {
        console.warn("resolved with relativeName:", relativeName);
        return surveysFolder.filePath(relativeName);
    }

    relativeName = packageName + "/" + fileInfo.fileName;

    if (surveysFolder.fileExists(relativeName)) {
        console.warn("resolved with modified relativeName:", relativeName);
        return surveysFolder.filePath(relativeName);
    }

    var formPath;

    if (packageFolder.exists) {
        formPath = resolveformInfoPath(packageFolder.path);
        if (formPath > "") {
            console.warn("resolved from forminfo:", packageName, "in:", packageFolder.path);
            return formPath;
        }
    }

    if (surveysFolder.fileExists(packageName)) {
        formPath = resolveformInfoPath(surveysFolder.filePath(packageName));
        if (formPath > "") {
            console.warn("resolved from forminfo:", packageName, "in:", surveysFolder.path);
            return formPath;
        }
    }

    console.error("Unable to resolve survey path:", surveyPath);

    return null;
}

//--------------------------------------------------------------------------

function resolveformInfoPath(folderPath) {
    function formInfoName(folder) {
        var formInfo = folder.readJsonFile("forminfo.json");
        if (formInfo.name > "") {
            return formInfo.name;
        }

        formInfo = folder.readJsonFile("esriinfo/forminfo.json");
        if (formInfo.name) {
            return "esriinfo/" + formInfo.name;
        }

        return null;
    }

    var folder = ArcGISAppFramework.AppFramework.fileFolder(folderPath);
    var name = formInfoName(folder);
    if (name > "") {
        name += ".xml";
        if (folder.fileExists(name)) {
            console.log("Found form in:", folder.path, "name:", name);

            return folder.filePath(name);
        }

        console.log("Form not found in:", folder.path, "name:", name);
    } else {
        console.warn("forminfo.json not found in:", folder.path);
    }

    return null;
}

//--------------------------------------------------------------------------

function getPropertyValue(object, name, defaultValue) {
    if (!object) {
        return defaultValue;
    }

    if (typeof name !== "string") {
        return defaultValue;
    }

    var keys = Object.keys(object);

    for (var i = 0; i < keys.length; i++) {
        if (name === keys[i]) {
            return object[keys[i]];
        }
    }

    for (i = 0; i < keys.length; i++) {
        if (name.toLowerCase() === keys[i].toLowerCase()) {
            return object[keys[i]];
        }
    }

    return defaultValue;
}

//--------------------------------------------------------------------------

function isEmpty(value) {
    if (value === undefined || value === null) {
        return true;
    }

    if (typeof value === "string") {
        return !(value > "");
    }

    return false;
}

//--------------------------------------------------------------------------

function toBoolean(value) {
    if (typeof value == "boolean") {
        return value;
    }

    if (!value) {
        return false;
    }

    var s = value.toString().toLowerCase();

    switch (s) {
    case "t":
    case "true":
    case "y":
    case "yes":
        return true;
    }

    return false;
}

//--------------------------------------------------------------------------

function removeArrayProperties(o) {
    if (!o || (typeof o !== "object")) {
        return o;
    }

    var keys = Object.keys(o);

    keys.forEach(function (key) {
        if (Array.isArray(o[key])) {
            o[key] = undefined;
        }
    });

    return o;
}

//--------------------------------------------------------------------------
