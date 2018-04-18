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
import QtGraphicalEffects 1.0
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../XForms"
import "../Controls"

Rectangle {
    id: page

    property alias surveyPath: surveyInfo.path

    property XForm xform
    property XFormsDatabase xformsDatabase: app.surveysModel
    property var rowid
    property var rowData
    property var parameters: null
    property var initialPosition: null
    property var initialValues: null
    property var favoriteData: null
    property bool isCurrentFavorite: false
    property bool newFavorite: false
    property bool reviewMode: !!rowid && !!rowData
    property SurveyInfoPage surveyInfoPage
    property bool asynchronous: false

    //--------------------------------------------------------------------------

    color: app.formBackgroundColor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (parameters) {
            initializeParameters();
        }

        beginTimer.start();
    }

    //--------------------------------------------------------------------------

    SurveyInfo {
        id: surveyInfo
    }

    //--------------------------------------------------------------------------

    Timer {
        id: beginTimer

        interval: 250

        onTriggered: {
            console.time("Survey Load");
            formLoader.active = true;
        }
    }

    Loader {
        id: formLoader

        anchors.fill: parent

        active: false
        sourceComponent: formComponent
        asynchronous: page.asynchronous

        onLoaded: {
            xform.visible = true;
            console.timeEnd("Survey Load");
        }
    }

    Loader {
        anchors.fill: parent
        asynchronous: true

        BusyPanel {
            visible: formLoader.status != Loader.Ready
            text: qsTr("Loading Survey")
        }
    }

    Component {
        id: formComponent

        Item {
            id: formItem

            anchors.fill: parent

            //--------------------------------------------------------------------------

            Component.onCompleted: {
                page.xform = xform;
            }

            //--------------------------------------------------------------------------

            Rectangle {
                id: titleBar

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: app.titleBarHeight
                color: xform.style.titleBackgroundColor //app.titleBarBackgroundColor

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 2
                    }

                    ImageButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.height - parent.anchors.margins
                        Layout.preferredWidth: titleBar.height - parent.anchors.margins

                        source: "images/close.png"
                        //source: "images/back.png"

                        onClicked: {
                            forceActiveFocus()
                            if (surveyInfo.isRapidSubmit && !xform.rapidSubmitCancelled) {
                                confirmPanel.clear();
                                confirmPanel.icon = "images/close-red.png";
                                confirmPanel.title = qsTr("Cancel Rapid Submission Session");
                                confirmPanel.question = qsTr("Do you want to close the rapid submit session?");
                                confirmPanel.button1Text = qsTr("<b>Yes</b> stop this rapid submission session.");
                                confirmPanel.button2Text = qsTr("<b>No</b> continue this rapid submission survey");
                                confirmPanel.verticalLayout = true;
                                confirmPanel.show(xform.cancelRapidSubmission, undefined);
                            }
                            else {
                                formItem.confirmClose();
                            }
                        }

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }
                    }

                    Text {
                        id: titleText

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: xform.title
                        font {
                            pointSize: xform.style.titlePointSize
                            family: xform.style.titleFontFamily
                        }
                        fontSizeMode: Text.HorizontalFit
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: xform.style.titleTextColor //app.titleBarTextColor
                        elide: Text.ElideRight
                    }

                    ImageButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.height - parent.anchors.margins
                        Layout.preferredWidth: titleBar.height - parent.anchors.margins

                        source: "images/actions.png"

                        onClicked: {
                            menuPanel.show();
                            //actionsMenu.popup();
                        }

                        visible: actionsMenu.items.length > 0

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        Menu {
                            id: actionsMenu

                            MenuItem {
                                property bool hideCheck: true

                                checkable: true
                                checked: newFavorite
                                visible: !isCurrentFavorite
                                iconSource: checked ? "images/favorite-off.png" : "images/favorite.png"
                                text: checked ? qsTr("Clear as favorite answers") : qsTr("Set as favorite answers")

                                onTriggered: {
                                    newFavorite = !newFavorite;
                                }
                            }

                            MenuItem {
                                iconSource: "images/favorite-add.png"
                                text: qsTr("Paste answers from favorite")
                                visible: !isCurrentFavorite && !newFavorite && favoriteData && typeof favoriteData.data === "object"

                                onTriggered: {
                                    forceActiveFocus();
                                    var values = favoriteData.data[xform.schema.schema.name];
                                    xform.pasteValues(values);
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: footer

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: app.titleBarHeight
                color: xform.style.titleBackgroundColor

                MouseArea {
                    anchors.fill: parent

                    enabled: pageField.visible

                    onClicked: {
                        pageField.visible = false;
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                    }

                    /*
            ImageButton {
                Layout.alignment: Qt.AlignLeft
                Layout.preferredHeight: footer.height
                Layout.preferredWidth: footer.height

                source: "images/save.png"
                visible: !xform.hasSaveIncomplete

                ColorOverlay {
                    anchors.fill: parent
                    source: parent.image
                    color: xform.style.titleTextColor
                }

                onClicked: {
                    forceActiveFocus()
                    xform.saveIncomplete();
                }
            }
*/
                    //            Item {
                    //                Layout.fillWidth: true
                    //            }

                    /*
            ImageButton {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter

                source: "images/back.png"

                onClicked: {
                    var item = xform.focusItem.nextItemInFocusChain(false);
                    console.log(item);
                    if (item) {
                        item.forceActiveFocus();
                        xform.currentItem.scrollView.ensureVisible(item);
                    }
                }
            }

            ImageButton {
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter

                source: "images/next.png"

                onClicked: {
                    var item = xform.focusItem.nextItemInFocusChain(true);
                    console.log(item);
                    if (item) {
                        item.forceActiveFocus();
                        xform.currentItem.scrollView.ensureVisible(item);
                    }
                }
            }
*/
                    //                    Item {
                    //                        Layout.fillWidth: true
                    //                    }

                    Item {
                        Layout.preferredHeight: footer.height
                        Layout.preferredWidth: footer.height

                        ImageButton {
                            anchors.fill: parent

                            source: "images/previous_button.png"
                            visible: xform.pageNavigator.canGotoPrevious

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent.image
                                color: xform.style.titleTextColor
                            }

                            onClicked: {
                                forceActiveFocus()
                                xform.pageNavigator.gotoPreviousPage();
                            }

                            onPressAndHold: {
                                forceActiveFocus()
                                xform.pageNavigator.gotoFirstPage();
                            }
                        }
                    }

                    ImageButton {
                        Layout.preferredHeight: footer.height
                        Layout.preferredWidth: footer.height

                        source: "images/send.png"
                        visible: xform.canPrint

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        onClicked: {
                            forceActiveFocus()
                            xform.printSend();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        AppText {
                            anchors.centerIn: parent

                            visible: xform.pageNavigator.canGoto && !pageField.visible
                            text: qsTr("%1 of %2").arg(xform.pageNavigator.currentIndex + 1).arg(xform.pageNavigator.count)
                            font {
                                pointSize: 14
                            }
                            color: xform.style.titleTextColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    pageField.text = xform.pageNavigator.currentIndex + 1;
                                    pageField.visible = true;
                                    pageField.forceActiveFocus();
                                }
                            }
                        }

                        XFormTextField {
                            id: pageField

                            anchors {
                                horizontalCenter: parent.horizontalCenter

                                top: parent.top
                                bottom: parent.bottom
                                margins: 2 * AppFramework.displayScaleFactor
                            }

                            visible: false
                            placeholderText: qsTr("Page")

                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator {
                                bottom: 1
                                top: xform.pageNavigator.count
                            }

                            onEditingFinished: {
                                visible = false;
                                Qt.inputMethod.hide();
                                if (length) {
                                    xform.pageNavigator.gotoPage(Number(text) - 1);
                                }
                            }
                        }
                    }

                    ImageButton {
                        Layout.preferredHeight: footer.height
                        Layout.preferredWidth: footer.height

                        source: "images/next_button.png"
                        visible: xform.pageNavigator.canGotoNext

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        onClicked: {
                            forceActiveFocus()
                            xform.pageNavigator.gotoNextPage();
                        }

                        onPressAndHold: {
                            forceActiveFocus()
                            xform.pageNavigator.gotoLastPage();
                        }
                    }

                    StyledImage {
                        Layout.preferredHeight: footer.height
                        Layout.preferredWidth: Layout.preferredHeight / 4

                        visible: okButton.visible && xform.formData.editMode > xform.formData.kEditModeAdd

                        source: "images/editMode.png"
                        color: xform.style.titleTextColor
                    }

                    ImageButton {
                        id: okButton

                        Layout.preferredHeight: footer.height
                        Layout.preferredWidth: footer.height

                        source: "images/ok_button.png"
                        visible: xform.pageNavigator.atLastPage

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        onClicked: {
                            forceActiveFocus()
                            xform.saveValidate();
                        }
                    }
                }
            }

            XForm {
                id: xform

                isRapidSubmit: surveyInfo.isRapidSubmit

                onRapidSubmit: {
                    xform.saveValidate();
                }

                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: footer.top
                }

                //        source: AppFramework.resolvedPath(surveyPath)
                source: AppFramework.resolvedPathUrl(surveyPath)
                popoverStackView: mainStackView
                positionSourceManager: app.positionSourceManager
                reviewMode: page.reviewMode

                mapSettings {
                    libraryPath: app.mapLibraryPaths
                }

                style {
                    textScaleFactor: app.textScaleFactor
                    fontFamily: app.fontFamily
                    titleBackgroundColor: app.titleBarBackgroundColor
                    titleTextColor: app.titleBarTextColor
                }

                extensionsEnabled: false

                Component.onCompleted: {
                    if (app.userInfo && surveyInfo.itemInfo) {
                        //console.log("userInfo.orgId:", userInfo.orgId);
                        //console.log("itemInfo.orgId:", surveyInfo.itemInfo.orgId, JSON.stringify(surveyInfo.itemInfo));
                        extensionsEnabled = userInfo.orgId > "" &&
                                surveyInfo.itemInfo.orgId > "" &&
                                userInfo.orgId === surveyInfo.itemInfo.orgId;
                    }
                }

                Component {
                    id: languageItem

                    MenuItem {
                        property string language

                        checkable: true
                        checked: language === xform.language
                        onTriggered: {
                            xform.language = language;
                        }
                    }
                }


                onStatusChanged: {
                    switch (status) {
                    case statusReady:
                        onReady();
                        break;
                    }
                }

                onCloseAction: {
                    forceActiveFocus()
                    formItem.confirmClose();
                }

                onSaveAction: {
                    saveIncomplete();
                }

                onValidationError: {
                    showValidationError(error);
                }

                Timer {
                    id: focusTimer

                    property var nodeset

                    interval: 2
                    repeat: false

                    onTriggered: {
                        xform.setControlFocus(nodeset);
                    }

                    function setControlFocus(nodeset) {
                        focusTimer.nodeset = nodeset;
                        restart();
                    }
                }

                function onReady() {
                    favoriteData = xformsDatabase.getFavorite(sourceInfo.filePath);

                    enumerateLanguages(function (language, languageText, locale) {
                        var menuItem = languageItem.createObject(actionsMenu, {
                                                                     language: language,
                                                                     text: languageText
                                                                 });

                        actionsMenu.insertItem(actionsMenu.items.length, menuItem);
                    });

                    console.log("Review mode:", reviewMode, "rowid:", rowid, "rowData:", rowData);

                    if (reviewMode) {
                        initializeValues(rowData);
                    } else {
                        if (initialPosition) {
                            setPosition(initialPosition);
                        }

                        if (initialValues) {
                            setValues(undefined, initialValues);
                        }
                    }
                }

                function cancelRapidSubmission(){
                    xform.rapidSubmitCancelled = true;
                    page.surveyInfoPage.rapidSubmissionCancelled = true;
                    closeSurvey();
                }

                function closeSurvey() {
                    console.log("Closing survey");

                    app.deleteAutoSave();

                    page.Stack.view.pop();
                }

                function submitSurvey() {
                    page.Stack.view.submitSurveys(surveyPath, true, surveyInfo.isPublic);
                }

                function collectNew() {
                    page.Stack.view.restartSurvey();
                }

                function saveDraft() {
                    console.log("Saving draft");
                    save(xformsDatabase.statusDraft);
                    closeSurvey();
                    app.deleteAutoSave();
                }

                //--------------------------------------------------------------

                function saveValidate() {
                    xform.finalize();
                    var error = xform.formData.validate();

                    if (error) {
                        showValidationError(error);
                    } else {
                        saveCompleted();
                    }
                }

                function showValidationError(error) {
                    focusTimer.setControlFocus(error.field.nodeset);
                    //xform.setControlFocus(error.field.nodeset);

                    confirmPanel.clear();
                    confirmPanel.icon = "images/warning.png";
                    confirmPanel.title = error.message;
                    confirmPanel.button1Text = qsTr("Ok");
                    confirmPanel.button2Text = "";
                    confirmPanel.show();
                }

                function saveCompleted() {
                    function _closeSurvey() {
                        save(xformsDatabase.statusComplete);
                        closeSurvey();
                        app.deleteAutoSave();
                    }

                    function _submitSurvey() {
                        save(xformsDatabase.statusComplete);
                        submitSurvey();
                        app.deleteAutoSave();
                    }

                    if (xform.isRapidSubmit) {
                        _submitSurvey();
                        return;
                    }
                    confirmPanel.clear();
                    confirmPanel.icon = "images/survey-completed.png";
                    confirmPanel.iconColor = "#a9d04d";
                    confirmPanel.title = qsTr("Survey Completed");

                    if (AppFramework.network.isOnline) {
                        confirmPanel.text = qsTr("Your device is <b>online</b>");
                        confirmPanel.question = qsTr("Would you like to send the survey now?");
                        confirmPanel.button1Text = qsTr("Send Later");
                        confirmPanel.button2Text = qsTr("Send <b>Now</b>");
                        confirmPanel.button3Text = qsTr("<b>Continue</b> this survey");
                        confirmPanel.show(_closeSurvey, _submitSurvey, undefined);
                        confirmPanel.verticalLayout = true;
                    } else {
                        confirmPanel.text = qsTr("Your device is <b>offline</b>");
                        confirmPanel.informativeText = qsTr("The survey has been saved in the outbox.");
                        confirmPanel.button1Text = qsTr("Ok");
                        confirmPanel.button2Text = "";
                        confirmPanel.show(_closeSurvey);
                        confirmPanel.verticalLayout = false;
                    }
                }

                function save(status, statusText) {
                    xform.finalize();

                    var rowData = {
                        "name": name,
                        "path": sourceInfo.filePath,
                        "data": xform.formData.instance,
                        "feature": JSON.stringify(xform.formData.toFeatureData()),
                        "snippet": xform.formData.snippet(),
                        "status": status,
                        "statusText": statusText,
                        "favorite": newFavorite
                    };

                    if (rowid > 0) {
                        rowData.rowid = rowid;
                        xformsDatabase.updateRow(rowData, true);
                    } else {
                        xformsDatabase.addRow(rowData);
                        rowid = rowData.rowid;
                        console.log("row added:", rowid)
                    }
                }

                //--------------------------------------------------------------

                function saveIncomplete() {
                    console.log("Saving incomplete draft");

                    xform.finalize();

                    var data = {
                        "name": name,
                        "path": sourceInfo.filePath,
                        "data": xform.formData.instance,
                        "feature": null, //JSON.stringify(xform.formData.toFeatureData()),
                        "snippet": xform.formData.snippet(),
                        "rowid": rowid
                    };

                    app.writeAutoSave(data);
                }

                //--------------------------------------------------------------

                function printSend() {
                    xform.finalize();
                    var error = xform.formData.validate();

                    if (error) {
                        showValidationError(error);
                    } else {
                        page.Stack.view.push({
                                                 item: surveyPrintPage,
                                                 properties: {
                                                     xform: xform
                                                 }
                                             });
                    }
                }

                //--------------------------------------------------------------
            }

            XFormMenuPanel {
                id: menuPanel

                textColor: xform.style.titleTextColor
                backgroundColor: xform.style.titleBackgroundColor
                fontFamily: xform.style.menuFontFamily

                menu: actionsMenu
            }

            //------------------------------------------------------------------

            ConfirmPanel {
                id: confirmPanel
            }

            function confirmClose() {
                confirmPanel.clear();
                confirmPanel.icon = "images/close-red.png";
                confirmPanel.title = qsTr("Confirm Close");
                confirmPanel.question = qsTr("What would you like to do?");
                confirmPanel.button1Text = qsTr("<b>Close</b> this survey and <font color=\"#ff0000\"><b>lose changes</b></font>");
                confirmPanel.button2Text = qsTr("<b>Continue</b> this survey");
                confirmPanel.button3Text = qsTr("<b>Save</b> this survey in <b>Drafts</b>");
                confirmPanel.verticalLayout = true;

                confirmPanel.show(xform.closeSurvey, undefined, xform.saveDraft);
            }

            //------------------------------------------------------------------

            Component {
                id: surveyPrintPage

                SurveyPrintPage {

                }
            }

            //------------------------------------------------------------------
        }
    }

    //--------------------------------------------------------------------------

    function initializeParameters() {
        console.log("Survey parameters:", JSON.stringify(parameters, undefined, 2));

        var values = null;

        var keys = Object.keys(parameters);

        keys.forEach(function (key) {
            if (key.substr(0, 6) === "field:") {
                var field = key.substr(6);
                if (!values) {
                    values = {};
                }

                values[field] = parameters[key];
            }
        });

        initialValues = values;
        console.log("initialValues:", JSON.stringify(rowData, undefined, 2));

        if (parameters.center) {
            var tokens = parameters.center.toString().split(',');

            if (tokens.length >= 2) {
                var latitude = Number(tokens[0]);
                var longitude = Number(tokens[1]);

                initialPosition = QtPositioning.coordinate(latitude, longitude);
            }
        }
    }

    //--------------------------------------------------------------------------
}
