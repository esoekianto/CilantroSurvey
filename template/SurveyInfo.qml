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

import ArcGIS.AppFramework 1.0

import "../template/SurveyHelper.js" as Helper

Item {
    id: surveyInfo

    property alias folder: fileInfo.folder
    property alias path: fileInfo.filePath
    property alias fileInfo: fileInfo
    property var itemInfo: null
    property var info: null
    readonly property alias name: fileInfo.baseName
    readonly property string itemId: itemInfo ? itemInfo.id || "" : ""
    readonly property string title: (itemInfo && itemInfo.title > "") ? itemInfo.title : fileInfo.baseName
    readonly property string description: (itemInfo && itemInfo.description) ? itemInfo.description : ""
    readonly property string snippet: (itemInfo && itemInfo.snippet) ? itemInfo.snippet : ""
    readonly property url thumbnail: Helper.findThumbnail(fileInfo.folder, fileInfo.baseName, "images/form-thumbnail.png") //fileInfo.folder.fileUrl(fileInfo.baseName + ".png")
    property alias mapPackages: mapPackages
    property url defaultMapThumbnail: "images/map-thumbnail.png"
    readonly property bool isPublished: itemInfo ? itemInfo.id > "" : false
    readonly property bool isPublic: itemInfo ? itemInfo.access === "public" : false
    property var queryInfo: info && info.queryInfo ? info.queryInfo : {}
    property var sentInfo: info && info.sentInfo ? info.sentInfo : {}
    property var notificationsInfo: info && info.notificationsInfo ? info.notificationsInfo : {}

    property bool isRapidSubmit: info && info.rapidSubmit ? info.rapidSubmit : false

    //--------------------------------------------------------------------------
    
    FileInfo {
        id: fileInfo

        onFilePathChanged: {
            read();
        }
    }

    FileFolder {
        id: libraryFolder

        path: app.kDefaultMapLibraryPath
    }

    ListModel {
        id: mapPackages
    }

    //--------------------------------------------------------------------------

    function readInfo() {
        itemInfo = fileInfo.folder.readJsonFile(fileInfo.baseName + ".itemInfo");
        info = fileInfo.folder.readJsonFile(fileInfo.baseName + ".info");

        console.log("surveyInfo:", JSON.stringify(info, undefined, 2));
    }

    //--------------------------------------------------------------------------

    function read() {
        readInfo();

        updateMapPackages();
    }

    //--------------------------------------------------------------------------

    function write() {
        fileInfo.folder.writeJsonFile(fileInfo.baseName + ".info", info);
    }

    //--------------------------------------------------------------------------

    function updateMapPackages() {

        var paths = app.mapLibraryPaths.split(";");
        if (paths.length > 0 && paths[0] > "") {
            libraryFolder.path = paths[0];
        }

        console.log("Primary library path:", libraryFolder.path);

        libraryFolder.makeFolder();

        mapPackages.clear();

        if (!info.displayInfo
                || !info.displayInfo.map
                || !info.displayInfo.map.mapTypes
                || !info.displayInfo.map.mapTypes.mapSources) {
            return;
        }

        var mapTypes = info.displayInfo.map.mapTypes;
        var mapSources = mapTypes.mapSources;
        var includeLibrary = true;
        if (mapTypes.hasOwnProperty("includeLibrary")) {
            includeLibrary = Boolean(mapTypes.includeLibrary);
        }

        if (!Array.isArray(mapSources)) {
            return;
        }

        var mapsFolder = fileInfo.folder.folder("Maps");

        mapSources.forEach(function (mapSource) {
            var urlInfo = AppFramework.urlInfo(mapSource.url);
            var query = urlInfo.queryParameters;
            var itemId = query.id;

            if (urlInfo.fileName === "item.html" && itemId > "") {

                urlInfo.path = "";
                urlInfo.query = "";
                urlInfo.userInfo = "";
                urlInfo.fragment = "";

                var name = mapSource.name;
                if (!(name > "")) {
                    name = "";
                }

                var description = mapSource.description;
                if (!(description > "")) {
                    description = "";
                }

                var storeInLibrary = includeLibrary;
                if (includeLibrary && mapSource.hasOwnProperty("storeInLibrary")) {
                    storeInLibrary = Boolean(mapSource.storeInLibrary);
                }

                var localUrl = storeInLibrary
                        ? libraryFolder.fileUrl(itemId)
                        : mapsFolder.fileUrl(itemId);

                var packageInfo = {
                    "name": name,
                    "description": description,
                    "itemId": itemId,
                    "portalUrl": urlInfo.url.toString(),
                    "localUrl": localUrl.toString(),
                    "thumbnailUrl": defaultMapThumbnail.toString(),
                    "mapSource": mapSource,
                    "storeInLibrary": storeInLibrary
                };

                mapPackages.append(packageInfo);
            }
        });
    }

    //--------------------------------------------------------------------------

    function componentFilePath(suffix) {
        return folder.filePath(fileInfo.baseName + "." + suffix);
    }

    //--------------------------------------------------------------------------

    function componentFileExists(suffix) {
        return folder.fileExists(fileInfo.baseName + "." + suffix);
    }

    //--------------------------------------------------------------------------
}
