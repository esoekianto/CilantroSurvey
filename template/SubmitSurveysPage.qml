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
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../Portal"
import "../XForms"

import "../XForms/XForm.js" as XFormJS


SurveysListPage {
    id: page

    property int submitIndex: 0
    property bool autoSubmit: false
    property bool autoDelete: false

    property bool submitting: false
    property bool isPublic: false

    property alias objectCache: xformFeatureService.objectCache

    //--------------------------------------------------------------------------

    statusFilter: app.surveysModel.statusComplete
    statusFilter2: app.surveysModel.statusSubmitError

    title: qsTr("%1 Outbox").arg(surveyTitle)

    backButton {
        onClicked: {
            deleteSubmitted();
        }
    }

    /*
    listActionButton {
        text: qsTr("Send Surveys")
        visible: AppFramework.network.isOnline && xformsDatabase.count > 0

        onClicked: {
            submitDatabase();
        }
    }
    */

    listAction: ConfirmButton {
        visible: AppFramework.network.isOnline && xformsDatabase.count > 0

        text: qsTr("Send")
        iconSource: "images/cloud-upload.png"

        onClicked: {
            submitDatabase();
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (autoSubmit) {
            Qt.callLater(submitDatabase);
        }
    }

    Component.onDestruction: {
        deleteSubmitted();
    }

    //--------------------------------------------------------------------------

    Rectangle {
        parent: app
        anchors.fill:  parent
        color: "#40000000"
        visible: submitting

        MouseArea {
            anchors.fill: parent
            onClicked: {
            }
        }
    }

    //--------------------------------------------------------------------------

    function submitDatabase() {
        //        progressPanel.open();
        //        progressPanel.title = qsTr("Authenticating");
        if (isPublic) {
            submitStart();
        } else {
            portal.signInAction(qsTr("Please sign in to send surveys"), submitStart);
        }
    }

    function submitStart() {
        submitting = true;
        progressPanel.open();
        submitIndex = 0;
        submitCurrent();
    }

    function submitCurrent() {
        if (submitIndex >= xformsDatabase.count) {
            return;
        }

        var row = xformsDatabase.get(submitIndex);
        submitData(row);
    }


    function submitNext() {
        submitIndex++;
        if (submitIndex >= xformsDatabase.count) {
            submitComplete();
            return;
        }

        submitCurrent();
    }

    function submitComplete() {
        submitting = false;
        progressPanel.close();
        refreshList();
    }

    //--------------------------------------------------------------------------

    function submitData(row) {

        console.log("submitData: rowid:", row.rowid, "name:", row.name, "data:", JSON.stringify(row.data, undefined, 2), "feature", row.feature);

        var surveyPath = row.path;

        xformFeatureService.setRow(row);

        if (xformFeatureService.isReady(surveyPath)) {
            xformFeatureService.serviceReady();
        } else {
            getServiceInfo(surveyPath);
        }
    }

    //--------------------------------------------------------------------------

    function getServiceInfo(surveyPath) {

        function setFeatureService(serviceInfo) {
            console.log("setFeatureService serviceInfo:", JSON.stringify(serviceInfo, undefined, 2));

            var itemId = serviceInfo.id ? serviceInfo.id : serviceInfo.itemId;
            var url = serviceInfo.url;
            var urlInfo = AppFramework.urlInfo(url);

            if (portal.ssl) {
                urlInfo.scheme = "https";
            }

            console.log("setFeatureService url:", urlInfo.url);

            xformFeatureService.surveyPath = surveyPath;
            if (itemId) {
                xformFeatureService.featureServiceItemId = itemId;
            }
            xformFeatureService.featureServiceUrl = urlInfo.url;
        }

        function getSurveyServiceInfo() {
            var submissionUrl = getSubmissionUrl(surveyPath);
            if (submissionUrl > "") {
                return {
                    url: submissionUrl
                };
            }

            var surveyInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".info");

            return surveyInfo.serviceInfo;
        }

        var surveyFileInfo = AppFramework.fileInfo(surveyPath);
        var surveyItemInfo = surveyFileInfo.folder.readJsonFile(surveyFileInfo.baseName + ".itemInfo");

        progressPanel.title = qsTr("Getting service information");

        if (surveyItemInfo.id > "" && surveyItemInfo.type === "Form") {
            survey2ServiceRequest.requestUrl(surveyItemInfo.id, function(serviceItem) {
                //console.log("Survey2Service:", JSON.stringify(serviceItem, undefined, 2));

                if (serviceItem) {
                    setFeatureService(serviceItem);
                } else {
                    setFeatureService(getSurveyServiceInfo())
                }
            });
        } else {
            setFeatureService(getSurveyServiceInfo())
        }
    }

    //--------------------------------------------------------------------------

    function getSubmissionUrl(surveyPath) {
        var xml = AppFramework.userHomeFolder.readTextFile(surveyPath);
        var json = AppFramework.xmlToJson(xml);

        var submission = {};

        if (json.head && json.head.model && json.head.model.submission) {
            submission = json.head.model.submission;
        }

        console.log("submission:", JSON.stringify(submission, undefined, 2));

        return submission["@action"];
    }

    //--------------------------------------------------------------------------

    function deleteSubmitted() {
        if (autoDelete) {
            xformsDatabase.deleteSurveys(xformsDatabase.statusSubmitted);
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: survey2ServiceRequest

        property var callback

        portal: app.portal

        onSuccess: {
            // console.log("Survey2Service:", JSON.stringify(response, undefined, 2));

            if (response.total > 0) {
                var relatedItem = response.relatedItems[0];
                callback(relatedItem);
            } else {
                callback();
            }
        }

        onFailed: {
            callback();
        }

        onProgressChanged: {
        }

        function requestUrl(itemId, callback) {
            survey2ServiceRequest.callback = callback;
            url = portal.restUrl + "/content/items/" + itemId + "/relatedItems";

            sendRequest({
                            "relationshipType": "Survey2Service",
                            "direction": "forward"
                        });
        }
    }

    //--------------------------------------------------------------------------

    XFormFeatureService {
        id: xformFeatureService

        property string surveyPath
        property var rowId
        property string rowLabel
        property var rowFeatureData
        property var rowInstanceData
        property bool sentEnabled: true

        portal: app.portal
        schema: page.schema
        webhooks: _webhooks


        SurveyInfo {
            id: surveyInfo

            path: xformFeatureService.surveyPath

            onPathChanged: {
                readInfo();

                xformFeatureService.sentEnabled = XFormJS.toBoolean(sentInfo.enabled, true);
            }
        }

        XFormWebhooks {
            id: _webhooks

            portal: app.portal
            webhooks: surveyInfo.notificationsInfo.webhooks
        }

        onServiceReady: {
            console.log("Sending row:", rowId, rowLabel);

            progressPanel.title = qsTr("Sending %1").arg(rowLabel);
            applyData(rowFeatureData, rowInstanceData);
        }

        onApplied: {
            console.log("Feature service applied edits:", JSON.stringify(edits.summary, undefined, 2), "instanceData:", JSON.stringify(instanceData, undefined, 2));

            if (sentEnabled) {
                xformsDatabase.updateDataStatus(rowId, instanceData, xformsDatabase.statusSubmitted, JSON.stringify(edits.summary));
            } else {
                console.log("Deleting submitted survey:", rowId);
                xformsDatabase.deleteSurvey(rowId);
            }

            submitNext();
        }

        onFailed: {
            console.log("Feature service error:", JSON.stringify(error, undefined, 2));

            xformsDatabase.updateStatus(rowId, xformsDatabase.statusSubmitError, JSON.stringify(error));
            featureServiceUrl = "";
            submitNext();
        }

        function isReady(path) {
            return surveyPath === path && featureServiceUrl > "" && featureServiceInfo;
        }

        function setRow(row) {
            rowId = row.rowid;
            rowLabel = row.snippet > "" ? row.snippet : "";
            rowFeatureData = row.feature;
            rowInstanceData = row.data;
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        parent: app
        message: xformFeatureService.progressMessage
        progressBar.value: xformFeatureService.progress
        progressBar.visible: progressBar.value > 0

        z: 99999
    }

    //--------------------------------------------------------------------------
}
