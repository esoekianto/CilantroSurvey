/* Copyright 2018 Esri
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

Item {
    property string provider: "AppStudio"
    property string name
    property real zoomLevel: defaultZoomLevel
    property real latitude: -37.830643
    property real longitude: 144.965520
    property real previewZoomLevel: defaultPreviewZoomLevel
    property string previewCoordinateFormat: "dm"
    property real positionZoomLevel: previewZoomLevel
    property string coordinateFormat: "dmss"
    property var mapSources: []
    property bool appendMapTypes: false//true
    property bool sortMapTypes: false
    property bool includeLibrary: true
    property string libraryPath: "~/ArcGIS/My Surveys/Maps"
    property bool mobileOnly: true
    property url defaultMapConfig: "XFormMapSettings.json"
    property bool debug: false

    readonly property real defaultZoomLevel: 9
    readonly property real defaultPreviewZoomLevel: 14

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!appendMapTypes) {
            addDefaultMapSources();
        }
    }

    //--------------------------------------------------------------------------

    function selectMapType(map) {
        if (name > "") {
            for (var i = 0; i < map.supportedMapTypes.length; i++) {
                var mapType = map.supportedMapTypes[i];

                if (mapType.name == name) {
                    map.activeMapType = mapType;
                    return true;
                }
            }
        }

        return false;
    }

    //--------------------------------------------------------------------------

    function refresh(surveyPath, mapInfo) {
        if (!mapInfo) {
            mapInfo = {};
        }

        console.log("Refreshing map settings surveyPath:", surveyPath, "info:", JSON.stringify(mapInfo, undefined, 2));

        function isNumber(value) {
            return isFinite(Number(value));
        }

        function isBool(value) {
            return typeof value === "boolean";
        }

        if (mapInfo.coordinateFormat > "") {
            coordinateFormat = mapInfo.coordinateFormat;
        }

        var defaultType = mapInfo.defaultType;
        if (defaultType) {
            if (defaultType.name > "") {
                name = defaultType.name;
            }
        }

        var homeInfo = mapInfo.home;
        if (homeInfo) {
            if (isNumber(homeInfo.latitude)) {
                latitude = Number(homeInfo.latitude);
            }

            if (isNumber(homeInfo.longitude)) {
                longitude = Number(homeInfo.longitude);
            }

            if (isNumber(homeInfo.zoomLevel)) {
                var zoom = Number(homeInfo.zoomLevel);
                if (zoom > 0) {
                    zoomLevel = zoom;
                } else {
                    zoomLevel = defaultZoomLevel;
                }
            }
        }

        var previewInfo = mapInfo.preview;
        if (previewInfo) {
            if (isNumber(previewInfo.zoomLevel)) {
                zoom = Number(previewInfo.zoomLevel);
                if (zoom > 0) {
                    previewZoomLevel = zoom;
                } else {
                    previewZoomLevel = defaultPreviewZoomLevel;
                }
            }

            if (previewInfo.coordinateFormat > "") {
                previewCoordinateFormat = previewInfo.coordinateFormat;
            }
        }

        if (!Array.isArray(mapSources)) {
            mapSources = [];
        }

        var mapTypes = mapInfo.mapTypes;
        if (mapTypes) {
            if (isBool(mapTypes.append)) {
                //appendMapTypes = mapTypes.append;
                if (!mapTypes.append) {
                    mapSources = [];
                }
            }

            if (isBool(mapTypes.sort)) {
                sortMapTypes = mapTypes.sort;
            }

            if (isBool(mapTypes.includeLibrary)) {
                includeLibrary = mapTypes.includeLibrary;
            }

            if (Array.isArray(mapTypes.mapSources)) {
                mapTypes.mapSources.forEach(function (mapSource) {
                    var urlInfo = AppFramework.urlInfo(mapSource.url);

                    if (urlInfo.fileName === "item.html") {
                        console.log("Map package item source:", JSON.stringify(mapSource, undefined, 2));
                    } else {
                        mapSources.push(mapSource);
                    }
                });
            }
        }

        var surveyPathInfo = AppFramework.fileInfo(surveyPath);
        var surveyFolder = AppFramework.fileFolder(surveyPath);

        var mapFolderNames = [
                    surveyPathInfo.baseName + "-media",
                    "media",
                    "Maps",
                    "maps"
                ];

        console.log("Map folders:", JSON.stringify(mapFolderNames, undefined, 2));

        mapFolderNames.forEach(function (folderName) {
            var mapsFolder = surveyFolder.folder(folderName);

            if (mapsFolder.exists) {
                var privateSource = {
                    "url": mapsFolder.url.toString(),
                    "recursive": true
                };

                mapSources.push(privateSource);

                console.log("Adding private maps folder:", JSON.stringify(privateSource, undefined, 2));
            }
        });


        if (includeLibrary && libraryPath > "") {
            var paths = libraryPath.split(";");

            paths.forEach(function (path) {
                path = path.trim();
                if (path > "") {
                    var libraryFolder = AppFramework.fileFolder(path);

                    var librarySource = {
                        "url": libraryFolder.url.toString(),
                        "recursive": true
                    };

                    mapSources.push(librarySource);

                    console.log("Adding maps library folder:", JSON.stringify(librarySource, undefined, 2));
                }
            });
        }
    }


    //--------------------------------------------------------------------------

    function addDefaultMapSources() {
        var fileInfo = AppFramework.fileInfo(defaultMapConfig);
        console.log("Reading default map sources:", defaultMapConfig);
        var config = fileInfo.folder.readJsonFile(fileInfo.fileName);

        if (Array.isArray(config.mapSources)) {
            mapSources = mapSources.concat(config.mapSources);
        }

        if (debug) {
            console.log("mapSources:", JSON.stringify(mapSources, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------
}
