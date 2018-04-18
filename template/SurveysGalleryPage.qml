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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "SurveyHelper.js" as Helper

Page {
    id: page

    signal selected(string surveyPath, bool pressAndHold, int indicator, var parameters)

    backButton {
        visible: false
    }

    actionButton {
        //        visible: AppFramework.network.isOnline
        //        source: "images/cloud-download.png"

        //        onClicked: {
        //            showDownloadPage();
        //        }

        visible: true

        menu: Menu {
            MenuItem {
                text: qsTr("Download Surveys")
                iconSource: "images/cloud-download.png"
                visible: AppFramework.network.isOnline
                enabled: visible
                onTriggered: {
                    showSignInOrDownloadPage();
                }
            }

            MenuItem {
                text: qsTr("Settings")
                iconSource: "images/gear.png"

                onTriggered: {
                    page.Stack.view.push(settingsPage);
                }
            }

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

            MenuItem {
                text: qsTr("About")
                iconSource: "images/info.png"

                onTriggered: {
                    page.Stack.view.push(aboutPage);
                }
            }
        }
    }

    title: qsTr("My Surveys")

    contentItem: Item {
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: galleryView.model.count

                SurveysGalleryView {
                    id: galleryView

                    model: surveysModel

                    delegate: galleryDelegateComponent

                    onClicked: {
                        if (currentSurvey) {
                            selected(app.surveysFolder.filePath(currentSurvey), false, -1, null);
                        }
                    }

                    onPressAndHold: {
                        if (currentSurvey) {
                            selected(app.surveysFolder.filePath(currentSurvey), true, -1, null);
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: !galleryView.model.count && !app.openParameters
                spacing: 20 * AppFramework.displayScaleFactor

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true

                    font {
                        pointSize: 20
                    }
                    color: app.textColor
                    text: qsTr("No surveys on device")
                    textFormat: Text.RichText
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                Text {
                    Layout.fillWidth: true

                    visible: !AppFramework.network.isOnline && !app.openParameters
                    font {
                        pointSize: 20
                    }
                    color: app.textColor
                    text: qsTr("Please connect to a network to download surveys")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                ConfirmButton {
                    Layout.alignment: Qt.AlignHCenter

                    visible: AppFramework.network.isOnline && !app.openParameters
                    text: qsTr("Get Surveys")

                    onClicked: {
                        showSignInOrDownloadPage();
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            OpenParametersPanel {
                id: openParametersPanel

                Layout.fillWidth: true
                Layout.margins: 5 * AppFramework.displayScaleFactor

                progressPanel: progressPanel

                onDownloaded: {
                    surveysFolder.update();
                    checkOpenParameters();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        formsFolder: surveysFolder

        onUpdated: {
            checkOpenParameters();
        }
    }

    //--------------------------------------------------------------------------

    function showSignInOrDownloadPage() {
        portal.signInAction(qsTr("Please sign in to download surveys"), showDownloadPage);
    }

    function showDownloadPage() {
        page.Stack.view.push({
                                 item: downloadSurveysPage
                             });
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        onOpenParametersChanged: {
            checkOpenParameters();
        }
    }

    function checkOpenParameters() {
        console.log("Checking openParameters", JSON.stringify(app.openParameters, undefined, 2));

        if (app.openParameters) {
            var parameters = app.openParameters;
            var surveyItem = findSurveyItem(parameters);
            if (surveyItem) {
                app.openParameters = null;
                selected(app.surveysFolder.filePath(surveyItem.survey), true, -1, parameters);
            } else {
                openParametersPanel.enabled = true;
            }
        }
    }

    function findSurveyItem(parameters) {
        var itemId = Helper.getPropertyValue(parameters, "itemId");
        if (!itemId) {
            return undefined;
        }

        console.log("Searching for survey itemId:", itemId);

        for (var i = 0; i < galleryView.model.count; i++) {
            var surveyItem = galleryView.getSurveyItem(i);
            if (surveyItem.itemId === itemId) {
                return surveyItem;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    Component {
        id: aboutPage

        AboutPage {
        }
    }

    Component {
        id: settingsPage

        SettingsPage {
        }
    }

    Component {
        id: galleryDelegateComponent

        GalleryDelegate {
            id: galleryDelegate

            Rectangle {
                anchors {
                    fill: indicatorsRow
                    margins: -2
                }

                visible: false
                radius: height / 2
                color: "#30000000"
            }

            Row {
                id: indicatorsRow
                anchors {
                    right: parent.right
                    top: parent.top
                    topMargin: 2
                }

                spacing: 4 * AppFramework.displayScaleFactor

                CountIndicator {
                    color: red
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusSubmitError, surveysDatabase.changed)

                    onClicked: {
                        indicatorsRow.indicatorClicked(0);
                    }
                }

                CountIndicator {
                    color: cyan
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusInbox, surveysDatabase.changed)

                    onClicked: {
                        indicatorsRow.indicatorClicked(3);
                    }
                }

                CountIndicator {
                    color: amber
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusDraft, surveysDatabase.changed)

                    onClicked: {
                        indicatorsRow.indicatorClicked(1);
                    }
                }

                CountIndicator {
                    color: green
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusComplete, surveysDatabase.changed)

                    onClicked: {
                        indicatorsRow.indicatorClicked(2);
                    }
                }
                /*
                CountIndicator {
                    color: blue
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusSubmitted, surveysDatabase.changed)
                }
*/
                function indicatorClicked(indicator) {
                    var view = galleryDelegate.GridView.view;

                    view.currentIndex = index;
                    if (view.currentSurvey) {
                        selected(app.surveysFolder.filePath(view.currentSurvey), false, indicator, null);
                    }
                }
            }

            onClicked: {
                GridView.view.currentIndex = index;
                GridView.view.clicked();
            }

            onPressAndHold: {
                GridView.view.currentIndex = index;
                GridView.view.pressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        progressBar.visible: progressBar.value > 0
    }

    //--------------------------------------------------------------------------
}
