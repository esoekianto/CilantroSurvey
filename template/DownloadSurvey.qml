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

import ArcGIS.AppFramework 1.0

import "../Portal"

Item {
    id: downloadSurvey

    property alias portal: formItem.portal
    property ProgressPanel progressPanel
    property bool succeededPrompt: true
    property bool debug: false

    signal succeeded()
    signal failed(var error)

    //--------------------------------------------------------------------------

    function download(itemInfo) {
        progressPanel.open();

        console.log("Download", itemInfo.id, itemInfo.title);

        workFolder.makeFolder();

        progressPanel.title = itemInfo.title;
        progressPanel.message = qsTr("Downloading");

        formItem.itemId = itemInfo.id;
        formItem.download(workFolder.filePath(itemInfo.id + ".zip"));
    }

    //--------------------------------------------------------------------------

    PortalItem {
        id: formItem

        onDownloaded: {
            progressPanel.message = qsTr("Unpacking");

            console.log("Downloaded form package:", path);

            zipReader.path = path;
            var surveyPath = surveysFolder.filePath(itemId);
            var result = zipReader.extractAll(surveyPath);
            if (!result) {
                console.error("Error unpacking:", result, path);
                progressPanel.closeError("Error unpacking");
            }
        }

        onItemInfoChanged: {
            if (!itemInfo.orgId && itemInfo.owner === portal.user.username) {
                console.info("Adding owner orgId to itemInfo");
                itemInfo.orgId = portal.user.orgId;
            }

            if (debug) {
                console.log("itemInfo:", JSON.stringify(itemInfo, undefined, 2));
            }
            storeInfo(surveysFolder.folder(itemId));
            //surveysFolder.update();

            if (succeededPrompt) {
                progressPanel.closeSuccess(qsTr("%1 survey download completed").arg(itemInfo.title));
            } else {
                progressPanel.close();
            }

            downloadSurvey.succeeded();
        }

        onProgressChanged: {
            progressPanel.progressBar.value = progress;
        }

        function storeInfo(folder) {
            var formInfoFile = "forminfo.json";

            if (!folder.fileExists(formInfoFile)) {
                if (folder.fileExists("esriinfo/" + formInfoFile)) {
                    folder = folder.folder("esriinfo");
                } else {
                    console.log("fileinfo.json not found:", folder.path);
                    return;
                }
            }

            var formInfo = folder.readJsonFile("forminfo.json");
            if (!formInfo.name) {
                console.log("forminfo.json error:", JSON.stringify(formInfo))
                return;
            }

            folder.writeJsonFile(formInfo.name + ".itemInfo", itemInfo);
            //folder.writeJsonFile(formInfo.name + ".portalInfo", portal.info);
            //folder.writeJsonFile(formInfo.name + ".userInfo", portal.user);
        }
    }

    //--------------------------------------------------------------------------

    ZipReader {
        id: zipReader

        onCompleted: {
            close();
            if (workFolder.removeFile(path)) {
                console.log("Deleted:", path);
            } else {
                //progressPanel.closeError("Delete package error");
                console.error("Error deleting:", path);
            }

            formItem.requestInfo();
        }

        onError: {
            progressPanel.closeError(qsTr("Unpack error"));
        }

        onProgress: {
            progressPanel.progressBar.value = percent / 100;
        }
    }

    //--------------------------------------------------------------------------
}
