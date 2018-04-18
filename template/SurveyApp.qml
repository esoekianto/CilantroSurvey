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
import QtQuick.Dialogs 1.2
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../Portal"
import "../Controls"

App {
    id: app

    readonly property real windowScaleFactor: !(Qt.platform.os === "windows" || Qt.platform.os === "unix" || Qt.application.os === "linux") ? 1 : AppFramework.displayScaleFactor

    width: 400 * windowScaleFactor
    height: 650 * windowScaleFactor

    property alias surveysFolder: surveysFolder
    property alias portal: portal
    property var userInfo

    readonly property color textColor: app.info.propertyValue("textColor", "black")
    property color backgroundColor: app.info.propertyValue("backgroundColor", "lightgrey")
    property string backgroundImage: app.folder.fileUrl(app.info.propertyValue("backgroundTextureImage", "images/texture.jpg"))
    property string fontFamily: ""

    readonly property color titleBarTextColor: app.info.propertyValue("titleBarTextColor", "grey")
    readonly property color titleBarBackgroundColor: app.info.propertyValue("titleBarBackgroundColor", "white")
    readonly property real titleBarHeight: 40 * AppFramework.displayScaleFactor

    readonly property color formBackgroundColor: app.info.propertyValue("formBackgroundColor", "#f7f8f8")

    property alias surveysModel: surveysDatabase
    property alias positionSourceManager: positionSourceManager

    property bool busy: false

    readonly property string kDefaultMapLibraryPath: "~/ArcGIS/My Surveys/Maps"
    property string mapLibraryPaths: settings.value("mapLibraryPaths", kDefaultMapLibraryPath)
    property real textScaleFactor: settings.value("textScaleFactor", 1)
    property int captureResolution: settings.numberValue("Camera/captureResolution", 0)

    property StackView activeStackView: mainStackView
    property int popoverStackDepth
    property var openParameters: null

    property alias metrics: metrics

    property var objectCache: ({})

    readonly property string kAutoSaveFileName: "autosave.json"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        fontManager.loadFonts();

        fontFamily = app.info.propertyValue("fontFamily", "");

        console.log("Setting font family:", fontFamily);

        readUserInfo();

        app.portal.autoSignIn();
    }

    //--------------------------------------------------------------------------

    onOpenUrl: {
        ///console.log("SurveyApp.onOpenUrl:", url);

        var urlInfo = AppFramework.urlInfo(url);

        if (!urlInfo.host.length) {
            openParameters = urlInfo.queryParameters;

            console.log("onOpenUrl parameters:", JSON.stringify(openParameters, undefined, 2));
        }
    }

    //--------------------------------------------------------------------------

    backButtonAction: mainStackView.depth == 1 ? App.BackButtonQuit : App.BackButtonSignal

    onBackButtonClicked: {
        goBack();
    }

    /*
    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            event.accepted = true;
            goBack();
        }
    }
    */

    /*
      // Debug only back button on non-Android devices

    Button {
        anchors.centerIn: parent
        z: 999999
        text: "Back"
        onClicked: {
            goBack();
        }
    }
    */

    //--------------------------------------------------------------------------

    function goBack() {
        var stackView = activeStackView;

        if (!stackView) {
            console.log("goBack: No stackView");
            return false;
        }

        if (stackView.popoverStackView) {
            if (stackView.popoverStackView.depth > popoverStackDepth) {
                stackView = stackView.popoverStackView;
            }
        }

        if (stackView.depth <= 1) {
            console.log("goBack: At top of stackView closeAction:", typeof stackView.currentItem.closeAction);

            var closeAction = stackView.currentItem.closeAction;
            if (typeof closeAction === "function") {
                closeAction();
                return true;
            }

            return false;
        }

        var canGoBack = stackView.currentItem.canGoBack;

        var doPop;

        switch (typeof canGoBack) {
        case 'boolean' :
            doPop = canGoBack;
            break;

        case 'function' :
            doPop = canGoBack();
            break;

        default:
            doPop = true;
            break;
        }

        // console.log("stackView:", stackView.depth, "canGoBack:", typeof canGoBack, doPop);

        if (doPop) {
            stackView.pop(); //stackView.currentItem.id);
            return true;
        }

        return false;
    }

    //--------------------------------------------------------------------------

    Metrics {
        id: metrics
    }

    //--------------------------------------------------------------------------

    FontManager {
        id: fontManager
    }

    //--------------------------------------------------------------------------

    StackView {
        id: mainStackView

        property var galleryItem

        anchors {
            fill: parent
        }

        delegate: PageViewDelegate {}

        //        initialItem: galleryPage

        Component.onCompleted: {
            galleryItem = push(galleryPage);

            surveysFolder.update();
            var surveysCount = surveysFolder.forms.length;

            if (!surveysCount && !openParameters) {
                console.log("0 surveys: Opening startPage");

                push({
                         item: startPage,
                         immediate: true
                     });
            }
        }

        function restartSurvey() {
            var surveyPath = currentItem.surveyPath;

            push({
                     item: surveyView,
                     replace: true,
                     properties: {
                         surveyPath: surveyPath,
                         rowid: null
                     }
                 });
        }

        function submitSurveys(surveyPath, autoSubmit, isPublic) {
            push({
                     item: submitSurveysPage,
                     properties: {
                         surveyPath: surveyPath,
                         autoSubmit: autoSubmit,
                         isPublic: isPublic,
                         actionColor: "#56ad89"
                     },
                     replace: autoSubmit
                 });
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: startPage

        StartPage {
            onSignedIn: {
                mainStackView.pop();

                /*
                var surveysCount = surveysFolder.forms.length;
                if (surveysCount) {
                    mainStackView.pop();
                } else {
//                    if (!app.openParameters) {
//                        mainStackView.push({
//                                               item: downloadSurveysPage,
//                                               properties: {
//                                                   hasSurveysPage: mainStackView.galleryItem
//                                               }
//                                           });
//                    }
                }
            */
            }

            Connections {
                target: app

                onOpenParametersChanged: {
                    if (openParameters) {
                        mainStackView.pop();
                    }
                }
            }
        }
    }

    Component {
        id: galleryPage

        SurveysGalleryPage {
            onSelected: {
                var count = surveysDatabase.surveyCount(surveyPath);


                if (pressAndHold) {
                    var surveyViewPage = {
                        item: surveyView,
                        properties: {
                            surveyPath: surveyPath,
                            rowid: null,
                            parameters: parameters
                        }
                    }

                    mainStackView.push(surveyViewPage);
                    //                    mainStackView.push([
                    //                                           surveyInfoPage,
                    //                                           surveyViewPage
                    //                                       ]);
                } else {
                    var surveyInfoPage = {
                        item: surveyPage,
                        properties: {
                            surveyPath: surveyPath
                        }
                    };

                    mainStackView.push(surveyInfoPage);
                }
            }


            Component.onCompleted: {
                if (!surveysModel.validateSchema()) {
                    invalidSchemaDialog.open();
                }

                checkAutoSave();
            }

            MessageDialog {
                id: invalidSchemaDialog

                icon: StandardIcon.Critical
                text: qsTr("The survey database is out of date and must to be reinitialized before survey data can be collected.\n\nWARNING: Please ensure any survey data already collected has been sucessfully submitted before reinitializing the database.")
            }
        }
    }

    Component {
        id: downloadSurveysPage

        DownloadSurveysPage {
        }
    }

    Component {
        id: surveyPage

        SurveyInfoPage {
        }
    }

    Component {
        id: surveyView

        SurveyView {
            onXformChanged: {
                if (xform) {
                    popoverStackDepth = mainStackView.depth;
                    activeStackView = xform;
                } else {
                    activeStackView = mainStackView;
                }
            }

            Component.onDestruction: {
                activeStackView = mainStackView;
            }
        }
    }

    Component {
        id: submitSurveysPage

        SubmitSurveysPage {
            objectCache: app.objectCache
        }
    }

    XFormsFolder {
        id: surveysFolder

        path: "~/ArcGIS/My Surveys"

        Component.onCompleted: {
            if (!exists) {
                makeFolder();
            }

            AppFramework.offlineStoragePath = path;

            surveysDatabase.initialize();
        }
    }

    XFormsDatabase {
        id: surveysDatabase
    }

    FileFolder {
        id: workFolder

        path: AppFramework.standardPaths.writableLocation(StandardPaths.TempLocation)

        Component.onCompleted: {
            console.log("workFolder", path);
        }
    }

    //--------------------------------------------------------------------------

    Portal {
        id: portal

        property bool staySignedIn: settings.value(settingsGroup + "/staySignedIn", app.info.propertyValue("staySignedIn", true))
        property var actionCallback: null

        app: app
        settings: app.settings
        clientId: app.info.value("deployment").clientId
        defaultUserThumbnail: app.folder.fileUrl("template/images/user.png")

        onCredentialsRequest: {
            console.log("Show sign in page");
            mainStackView.push({
                                   item: portalSignInPage,
                                   immediate: false,
                                   properties: {
                                   }
                               });
        }

        function signInAction(reason, callback) {
            validateToken();

            if (signedIn) {
                actionCallback = null;
                callback();
                return;
            }

            actionCallback = callback;
            signIn(reason);
        }

        onSignedInChanged: {
            var callback = actionCallback;
            actionCallback = null;

            if (signedIn) {
                if (staySignedIn) {
                    writeSignedInState();
                } else {
                    clearSignedInState();
                }
            } else {
                clearSignedInState();
            }

            if (signedIn) {
                userInfo = portal.user;
                writeUserInfo();
            } else {
                clearUserInfo();
            }

            if (signedIn && mainStackView.currentItem.isPortalSignInView) {
                if(user.orgId>"") {
                    //only pop login screen when user is not using free public account
                    mainStackView.pop();
                }
            }

            if (signedIn && callback) {
                callback();
            }
        }
    }

    Component {
        id: portalSignInPage

        PortalSignInView {
            property bool isPortalSignInView: true

            portal: app.portal
            bannerColor: app.titleBarBackgroundColor

            onRejected: {
                portal.actionCallback = null;
                mainStackView.pop();
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceManager {
        id: positionSourceManager
    }

    Rectangle {
        anchors.fill: parent

        visible: busy //|| portalSignInDialog.visible
        color: "#80000000"

        AppBusyIndicator {
            anchors.centerIn: parent
            running: busy
        }
    }

    //--------------------------------------------------------------------------

    readonly property string kGroupInfo: "Info"
    readonly property string kKeyUserInfo: kGroupInfo + "/user"

    function readUserInfo() {
        var info;

        try {
            info = JSON.parse(settings.value(kKeyUserInfo, ""));
        } catch (e) {
            info = {};
        }

        if (!info || typeof info !== "object") {
            info = {};
        }

        userInfo = info;

        console.log("read userInfo:", JSON.stringify(userInfo, undefined, 2));
    }

    function writeUserInfo() {
        if (!userInfo || typeof userInfo !== "object") {
            settings.remove(kKeyUserInfo);
            return;
        }

        var info = {
            username: userInfo.username,
            firstName: userInfo.firstName,
            lastName: userInfo.lastName,
            fullName: userInfo.fullName,
            email: userInfo.email,
            orgId: userInfo.orgId
        };

        console.log("write userInfo:", JSON.stringify(info, undefined, 2));

        settings.setValue(kKeyUserInfo, JSON.stringify(info));
    }

    function clearUserInfo() {
        userInfo = undefined;
        settings.remove(kKeyUserInfo);
    }

    //--------------------------------------------------------------------------

    function readAutoSave() {
        if (!surveysFolder.fileExists(kAutoSaveFileName)) {
            return;
        }

        var data = surveysFolder.readJsonFile(kAutoSaveFileName);
        if (!data) {
            return;
        }

        if (!Object.keys(data).length) {
            return;
        }

        return data;
    }

    function writeAutoSave(data) {
        surveysFolder.writeJsonFile(kAutoSaveFileName, data);
    }

    function deleteAutoSave() {
        surveysFolder.removeFile(kAutoSaveFileName);
    }

    //--------------------------------------------------------------------------

    Component {
        id: recoveryPanel

        ConfirmPanel {
            property var data

            icon: "images/survey-autosave.png"
            title: qsTr("Survey Recovered")
            text: qsTr("Data for the survey <b>%1</b> has been recovered. (%2)").arg(data.name).arg(data.snippet)
            question: qsTr("What would you like to do with the recovered survey?")
            button1Text: qsTr("Discard survey")
            button2Text: qsTr("Continue survey")
        }
    }

    //--------------------------------------------------------------------------

    function checkAutoSave() {
        var data = app.readAutoSave();

        if (!data) {
            return;
        }

        console.log("autosave data:", JSON.stringify(data, undefined, 2));

        var panel = recoveryPanel.createObject(app, {
                                                   data: data
                                               });

        function _continueSurvey() {
            var surveyViewPage = {
                item: surveyView,
                properties: {
                    surveyPath: data.path,
                    rowid: data.rowid > 0 ? data.rowid : -1,
                    rowData: data.data,
                    parameters: null
                }
            }

            mainStackView.push(surveyViewPage);
        }

        panel.show(deleteAutoSave, _continueSurvey);
    }

    //--------------------------------------------------------------------------
}
