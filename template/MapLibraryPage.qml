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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Page {
    id: page

    property url defaultMapThumbnail: "images/map-thumbnail.png"

    title: qsTr("Map Library")

    actionButton {
        //        visible: AppFramework.network.isOnline
        //        source: "images/cloud-download.png"

        //        onClicked: {
        //            showDownloadPage();
        //        }

        visible: true

        menu: Menu {
            MenuItem {
                property bool noColorOverlay: portal.signedIn

                visible: portal.signedIn || AppFramework.network.isOnline
                enabled: visible

                text: portal.signedIn ? qsTr("Sign out %1").arg(portal.user ? portal.user.fullName : "") : qsTr("Sign in")
                iconSource: portal.signedIn ? portal.userThumbnailUrl : "images/user.png"

                onTriggered: {
                    if (portal.signedIn) {
                        portal.signOut();
                    } else {
                        portal.signIn(undefined, true);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        findMaps();
    }

    //--------------------------------------------------------------------------

    function findMaps() {

        mapPackages.clear();

        var paths = app.mapLibraryPaths.split(";")
        paths.forEach(function (path) {
            path = path.trim();
            if (path > "") {

                var mapLibrary = AppFramework.fileFolder(path);

                console.log("Searching for maps in:", mapLibrary.path);

                var fileNames = mapLibrary.fileNames("*.tpk");

        //        console.log("fileNames:", JSON.stringify(fileNames, undefined, 2));

                fileNames.forEach(function(fileName) {
                    addMap(mapLibrary, fileName);
                });
            }
        });

    }

    function addMap(mapLibrary, fileName) {

        var fileInfo = mapLibrary.fileInfo(fileName);

        var mapSource = {
        };

        var packageInfo = {
            "name": fileInfo.baseName,
            "description": fileName,
            "itemId": fileInfo.baseName,
            "portalUrl": "http://www.arcgis.com",
            "localUrl": mapLibrary.fileUrl(fileName).toString(),
            "thumbnailUrl": defaultMapThumbnail.toString(),
            "mapSource": mapSource,
            "storeInLibrary": true
        };

        mapPackages.append(packageInfo);

        console.log("addMap:", JSON.stringify(packageInfo, undefined, 2));
    }

    //--------------------------------------------------------------------------

    contentItem: MapsView {
        id: mapsView

        showLibraryIcon: false
        mapPackages: ListModel {
            id: mapPackages
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel
    }

    ConfirmPanel {
        id: confirmPanel
    }

    //--------------------------------------------------------------------------
}
