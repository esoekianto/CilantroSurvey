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

import ArcGIS.AppFramework 1.0

import "../Portal"

Item {
    id: mapPackage

    property Portal portal
    property var info: null

    property alias itemId: packageItem.itemId
    property alias progress: packageItem.progress
    property string name
    property string description
    property string packageName

    property bool canDownload: AppFramework.network.isOnline && onlineAvailable
    property bool isLocal: localSize != 0
    property var localItemInfo
    property var localSize: 0
    property bool onlineAvailable
    property bool updateAvailable
    property date updateDate
    property var updateSize: 0
    property string errorText

    readonly property string kWebMercator: "WGS_1984_Web_Mercator_Auxiliary_Sphere"
    readonly property string kTilePackage: "Tile Package"

    readonly property string kSuffixItemInfo: ".iteminfo"
    readonly property string kSuffixMapTypeInfo: ".maptype"
    readonly property string kSuffixTilePackage: ".tpk"
    readonly property string kSuffixThumbnail: ".thumbnail"

    signal downloaded()
    signal failed(var error)

    //--------------------------------------------------------------------------

    onInfoChanged: {
        if (!info) {
            return;
        }

        var urlInfo = AppFramework.urlInfo(info.localUrl);
        var fileInfo = AppFramework.fileInfo(urlInfo.localFile);

        itemId = info.itemId;
        packageName = fileInfo.baseName;
        mapFolder.path = fileInfo.folder.path;

        if (info.name > "") {
            name = info.name;
        }

        if (info.description > "") {
            description = info.description;
        }
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: mapFolder

        onPathChanged: {
            checkLocal();
        }
    }

    PortalItem {
        id: packageItem

        portal: mapPackage.portal

        onItemInfoDownloaded: {
            console.log("Online itemInfo:", JSON.stringify(itemInfo, undefined, 2));


            info.thumbnailUrl = (portal.restUrl + "/content/items/" + itemId + "/info/" + itemInfo.thumbnail + (portal.token > "" ? "?token=" + portal.token : "")).toString();
            updateInfo(itemInfo);

            updateAvailable = localItemInfo ? itemInfo.modified > localItemInfo.modified : false;
            updateDate = new Date(itemInfo.modified);
            updateSize = mb(itemInfo.size);
            localItemInfo = itemInfo;

            onlineAvailable = itemInfo.type === kTilePackage // && itemInfo.spatialReference === kWebMercator;

            if (itemInfo.type !== kTilePackage) {
                errorText = qsTr("Unsupported type: %1").arg(itemInfo.type);
            } else if (itemInfo.spatialReference !== kWebMercator) {
                errorText = qsTr("Unsupported spatial reference: %1").arg(itemInfo.spatialReference);
            }
        }

        onThumbnailDownloaded: {
            info.thumbnailUrl = AppFramework.fileInfo(path).url;

            download(mapFolder.filePath(packageName + kSuffixTilePackage));
        }

        onDownloaded: {
            var mapTypeInfo = {
                "style": info.style,
                "name": info.name,
                "description": info.description > "" ? info.description : "",
                "mobile": info.mobile,
                "night": info.night,
                "copyrightText": info.copyrightText
            };


            mapFolder.writeJsonFile(packageName + kSuffixItemInfo, localItemInfo);

            var mapTypeFileName = packageName + kSuffixMapTypeInfo;
            if (removeEmpty(mapTypeInfo)) {
                mapFolder.writeJsonFile(mapTypeFileName, mapTypeInfo);
            } else {
                console.log("Removing empty maptype info:", mapTypeFileName);
                mapFolder.removeFile(mapTypeFileName);
            }

            isLocal = true;
            updateAvailable = false;
            localSize = mb(mapFolder.fileInfo(packageName + kSuffixTilePackage).size);

            mapPackage.downloaded();
        }

        onFailed: {
            mapPackage.failed(error);
        }

        function removeEmpty(o) {
            var keys = Object.keys(o);

            keys.forEach(function(key) {
                var value = o[key]
                if (typeof value === "undefined" || value === null || value === "" ) {
                    // delete o[key];
                    o[key] = undefined;
                }
            });

            return Object.keys(o).length > 0;
        }
    }

    //--------------------------------------------------------------------------

    function requestItemInfo() {
        packageItem.requestInfo();
    }

    function requestDownload() {
        mapFolder.makeFolder();

        if (!packageItem.downloadThumbnail(mapFolder.filePath(packageName + kSuffixThumbnail))) {
            packageItem.download(mapFolder.filePath(packageName + kSuffixTilePackage));
        }
    }

    function checkLocal() {

        console.log("checkLocal:", mapFolder.path, packageName);

        var itemInfoFileName = packageName + kSuffixItemInfo;

        if (mapFolder.fileExists(itemInfoFileName)) {
            localItemInfo = mapFolder.readJsonFile(itemInfoFileName);

            console.log("Local itemInfo:", JSON.stringify(localItemInfo, undefined, 2));

            updateInfo(localItemInfo);
        }

        var thumbnailFileName = packageName + kSuffixThumbnail;
        if (mapFolder.fileExists(thumbnailFileName)) {
            info.thumbnailUrl = mapFolder.fileUrl(thumbnailFileName).toString();
            console.log("local thumbnail:", info.thumbnailUrl);
        }

        if (mapFolder.fileExists(packageName + kSuffixTilePackage)) {
            localSize = mb(mapFolder.fileInfo(packageName + kSuffixTilePackage).size);
        }
    }

    function updateInfo(itemInfo) {
        name = itemInfo.title;
        description = itemInfo.description > "" ? info.description : "";

        console.log("mapPackage:", JSON.stringify(info, undefined, 2));
    }

    function mb(size) {
        return (size / 1048576.0).toFixed(1);
    }

    function deleteLocal() {
        console.log("Delete:", mapFolder.path);

        var result = deleteLocalFile(kSuffixTilePackage);
        result = result && deleteLocalFile(kSuffixItemInfo);
        result = result && deleteLocalFile(kSuffixThumbnail);
        result = result && deleteLocalFile(kSuffixMapTypeInfo);

        if (result) {
            localSize = 0;
        } else {
            console.error("Error removing:", mapFolder.filePath(packageName));
        }
    }

    function deleteLocalFile(suffix) {
        var result = mapFolder.removeFile(packageName + suffix);
        if (!result) {
            console.warn("Error deleting:", mapFolder.filePath(packageName + suffix))
        }

        return result;
    }
}
