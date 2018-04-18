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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0


Page {
    id: surveyPage

    property alias surveyPath: surveyInfo.path

    property bool deleted: false

    property real imageScaleFactor: 0.75
    property int actionHeight: 70 * AppFramework.displayScaleFactor

    property bool rapidSubmissionCancelled: false

    Stack.onStatusChanged: {
        if (Stack.status === Stack.Active){
            console.log('-------surveyinfo stack', surveyInfo.isRapidSubmit)
            if (surveyInfo.isRapidSubmit && !rapidSubmissionCancelled) {
                collectAction.trigger();
            }
        }
    }


    actionButton {
        visible: true

        menu: Menu {
            MenuItem {
                text: qsTr("Delete Survey")
                iconSource: "images/survey-delete.png"

                onTriggered: {
                    confirmPanel.clear();
                    confirmPanel.icon = "images/warning.png";
                    confirmPanel.title = text;
                    confirmPanel.text = qsTr("This action will delete the <b>%1</b> survey and all data collected on this device that has not been submitted.").arg(title);
                    confirmPanel.question = qsTr("Are you sure want to delete the survey?");

                    confirmPanel.show(deleteSurvey);
                }
            }

            MenuItem {
                text: qsTr("Download Maps")
                iconSource: "images/cloud-download.png"
                visible: AppFramework.network.isOnline && surveyInfo.mapPackages.count > 0
                enabled: visible

                onTriggered: {
                    showSignInOrDownloadPage();
                }

                function showSignInOrDownloadPage() {
                    portal.signInAction(qsTr("Please sign in to download maps"), showDownloadPage);
                }

                function showDownloadPage() {
                    surveyPage.Stack.view.push({
                                                   item: downloadMaps,
                                                   properties: {
                                                       surveyPath: surveyPath,
                                                       surveyInfoPage: surveyPage
                                                   }
                                               });
                }
            }
        }
    }

    title: surveyInfo.title
    //    hint: surveyItemInfo.snippet > "" ? surveyItemInfo.snippet : ""

    //--------------------------------------------------------------------------

    function restartSurvey() {
        var surveyPath = surveyPage.surveyPath;

        surveyPage.Stack.view.push({
                                       item: surveyView,
                                       replace: true,
                                       properties: {
                                           surveyPath: surveyPath,
                                           surveyInfoPage: surveyPage,
                                           rowid: null
                                       }
                                   });
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        if (deleted) {
            surveysFolder.update();
        }
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo
    }

    //--------------------------------------------------------------------------

    contentItem: ColumnLayout {
        spacing: 10 * AppFramework.displayScaleFactor

        Image {
            Layout.alignment: Qt.AlignHCenter
            //                Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 200 * AppFramework.displayScaleFactor * imageScaleFactor
            Layout.preferredHeight: 133 * AppFramework.displayScaleFactor * imageScaleFactor
            Layout.maximumWidth: 200 * AppFramework.displayScaleFactor * imageScaleFactor
            Layout.maximumHeight: 133 * AppFramework.displayScaleFactor * imageScaleFactor

            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
            source: surveyInfo.thumbnail

            Rectangle {
                anchors.fill: parent

                color: "transparent"
                border {
                    width: 1
                    color: "#40000000"
                }
            }
        }

        AppText {
            Layout.fillWidth: true

            text: surveyInfo.snippet
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            color: "#323232" //textColor
            horizontalAlignment: Text.AlignHCenter
            visible: text > ""
            font {
                pointSize: 16
            }

            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }


        //        Rectangle {
        //            Layout.fillWidth: true
        //            height: 1
        //            color: "#40000000"
        //        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: scrollView

                anchors {
                    fill: parent
                    //margins: 10 * AppFramework.displayScaleFactor
                }

                AppText {
                    width: scrollView.width
                    text: surveyInfo.description
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor

                    font {
                        pointSize: 12
                    }

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }
            }
        }

        ListView {
            property int maxHeight: enabledCount() * (actionHeight + spacing)
            Layout.fillWidth: true
            //            Layout.fillHeight: true
            Layout.preferredHeight: maxHeight

            model: actions.resources
            spacing: 0//5 * AppFramework.displayScaleFactor
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            //interactive: height < maxHeight


            delegate: actionDelegate

            function enabledCount() {
                var count = 0;
                for (var i = 0; i < model.length; i++) {
                    if (model[i].enabled) {
                        count++;
                    }
                }
                return count;
            }
        }
    }

    Component {
        id: reviewSurveys

        ReviewSurveysPage {
            // add surveyInfo reference to all of these SurveyListPage objects
        }
    }

    Component {
        id: sentSurveys

        SentSurveysPage {
        }
    }

    Component {
        id: editSurveys

        EditSurveysPage {
        }
    }

    Component {
        id: downloadMaps

        DownloadMapsPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: actionDelegate

        Rectangle {
            id: actionBackgound

            width: parent.width
            height: visible ? actionHeight : 0
            color: mouseArea.containsMouse ? mouseArea.pressed ? indicatorColor : "#e1f0fb" : "#fefefe" //"#20000000" : "transparent"
            radius: height / 2 //4 * AppFramework.displayScaleFactor
            visible: modelData.enabled
            border {
                width: 1
                color: "#e5e6e7"
            }

            RowLayout {
                id: actionLayout

                anchors {
                    fill: parent
                    leftMargin: actionBackgound.radius / 2
                    rightMargin: actionBackgound.radius / 2
                    topMargin: actionBackgound.radius / 4
                    bottomMargin: actionBackgound.radius / 4
                }

                Item {
                    readonly property int iconMargin: 4 * AppFramework.displayScaleFactor

                    Layout.preferredWidth: actionBackgound.height - iconMargin * 2
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.leftMargin: -actionLayout.anchors.leftMargin + iconMargin
                    Layout.topMargin: -actionLayout.anchors.topMargin + iconMargin
                    //Layout.bottomMargin: -actionLayout.anchors.bottomMargin * 2// + iconMargin

                    Rectangle {
                        anchors {
                            fill: parent
                        }

                        radius: height / 2
                        color: indicatorColor

                        Image {
                            id: actionImage

                            anchors {
                                fill: parent
                                margins: 12 * AppFramework.displayScaleFactor
                                leftMargin: 14 * AppFramework.displayScaleFactor
                            }

                            source: modelData.iconSource
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                        }

                        ColorOverlay {
                            anchors.fill: actionImage

                            source: actionImage
                            color: "white"
                        }

                        Column {
                            anchors {
                                left: parent.left
                                top: parent.top
                                leftMargin: 8 * AppFramework.displayScaleFactor
                                topMargin: 8 * AppFramework.displayScaleFactor
                            }

                            spacing: 2 * AppFramework.displayScaleFactor

                            CountIndicator {
                                count: modelData.count
                                color: modelData.indicatorColor
                                textSize: 13
                            }

                            CountIndicator {
                                count: modelData.errorCount
                                textSize: 13
                            }
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.maximumHeight: actionLayout.height
//                    Layout.fillHeight: true

                    spacing: 2

                    AppText {
                        width: parent.width
                        text: modelData.text
                        color: textColor
                        //style: mouseArea.pressed ? Text.Sunken : Text.Normal
                        //styleColor: "grey"

                        horizontalAlignment: Text.AlignLeft
                        font {
                            bold: true
                            pointSize: 16
                        }

                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    AppText {
                        width: parent.width
                        text: modelData.tooltip
                        horizontalAlignment: Text.AlignLeft
                        font {
                            pointSize: 12
                        }
                        color: textColor

                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 20 * AppFramework.displayScaleFactor

                    Image {
                        id: nextImage

                        anchors.fill: parent
                        source: "images/next.png"
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                    }

                    ColorOverlay {
                        anchors.fill: nextImage
                        color: app.titleBarBackgroundColor
                        source: nextImage
                    }
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                hoverEnabled: true

                onClicked: {
                    modelData.triggered();
                }

                onDoubleClicked: {
                }
            }
        }
    }

    Item {
        id: actions

        SurveyAction {
            id: collectAction

            indicatorColor: "#3e78b3"
            iconSource: "images/survey-collect.png"
            text: qsTr("Collect")
            tooltip: qsTr("Start collecting data")

            onTriggered: {
                surveyPage.Stack.view.push({
                                               item: surveyView,
                                               properties: {
                                                   surveyPath: surveyPath,
                                                   surveyInfoPage: surveyPage,
                                                   rowid: null
                                               }
                                           });
            }
        }

        SurveyAction {
            count: surveysDatabase.statusCount(surveyPath, surveysDatabase.statusInbox, surveysDatabase.changed)
            indicatorColor: "#00aeef"

            text: qsTr("Inbox")
            tooltip: qsTr("Edit existing survey data")
            iconSource: "images/survey-inbox.png"
            enabled: count > 0 || (surveyInfo.queryInfo.mode > "" && AppFramework.network.isOnline)

            onTriggered: {
                surveyPage.Stack.view.push({
                                               item: editSurveys,
                                               properties: {
                                                   surveyPath: surveyPath,
                                                   surveyInfoPage: surveyPage,
                                                   actionColor: indicatorColor
                                               }
                                           });
            }
        }

        SurveyAction {
            id: editAction

            count: surveysDatabase.statusCount(surveyPath, surveysDatabase.statusDraft, surveysDatabase.changed)
            indicatorColor: "#ff7e00"

            text: qsTr("Drafts")
            tooltip: qsTr("Check draft collected data")
            iconSource: "images/survey-review.png"
            enabled: count > 0

            onTriggered: {
                surveyPage.Stack.view.push({
                                               item: reviewSurveys,
                                               properties: {
                                                   surveyPath: surveyPath,
                                                   surveyInfoPage: surveyPage,
                                                   actionColor: indicatorColor
                                               }
                                           });
            }
        }

        SurveyAction {
            count: surveysDatabase.statusCount(surveyPath, surveysDatabase.statusComplete, surveysDatabase.changed)
            errorCount: surveysDatabase.statusCount(surveyPath, surveysDatabase.statusSubmitError, surveysDatabase.changed)
            indicatorColor: "#56ad89"

            text: qsTr("Outbox")
            tooltip: qsTr("Send your completed survey data")
            iconSource: "images/survey-submit.png"
            enabled: count > 0 || errorCount > 0

            onTriggered: {
                surveyPage.Stack.view.submitSurveys(surveyPath, false, surveyInfo.isPublic);
            }
        }

        SurveyAction {
            count: surveysDatabase.statusCount(surveyPath, surveysDatabase.statusSubmitted, surveysDatabase.changed)
            indicatorColor: "#818181"

            text: qsTr("Sent")
            tooltip: qsTr("Review sent survey data")
            iconSource: "images/survey-sent.png"
            enabled: count > 0

            onTriggered: {
                surveyPage.Stack.view.push({
                                               item: sentSurveys,
                                               properties: {
                                                   surveyPath: surveyPath,
                                                   surveyInfoPage: surveyPage,
                                                   actionColor: indicatorColor
                                               }
                                           });
            }
        }
    }

    //--------------------------------------------------------------------------

    /*
    Item {
        id: footerActions

        Action {
            text: qsTr("Delete")
            tooltip: qsTr("Remove this survey and any collected data")
            iconSource: "images/survey-delete.png"

            onTriggered: {
                confirmPanel.clear();
                confirmPanel.icon = "images/warning.png";
                confirmPanel.title = text;
                confirmPanel.text = qsTr("This action will delete the survey <b>%1</b> and all data collected on this device that has not been submitted.").arg(title);
                confirmPanel.question = qsTr("Are you sure want to delete the survey?");

                confirmPanel.show(deleteSurvey);
            }
        }
    }
    */

    //--------------------------------------------------------------------------

    Connections {
        id: signinConnections

        property Component showPage
        property var showProperties

        target: portal

        onSignedInChanged: {
            if (portal.signedIn && signinConnections.showPage) {
                surveyPage.Stack.view.push({
                                               item: signinConnections.showPage,
                                               properties: signinConnections.showProperties
                                           });
            }
        }
    }

    //--------------------------------------------------------------------------

    ConfirmPanel {
        id: confirmPanel
    }

    //--------------------------------------------------------------------------

    function deleteSurvey() {
        var surveyFolder = surveyInfo.fileInfo.folder;

        if (surveyFolder.folderName === "esriinfo") {
            surveyFolder.cdUp();
        }

        console.log("Delete Survey:", surveyFolder.path);

        surveysDatabase.deleteSurveyData(surveyPath);
        surveyFolder.removeFolder();

        deleted = true;
        parent.pop();
    }

    //--------------------------------------------------------------------------
}
