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
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../Portal"
import "../XForms"
import "../Controls"
import "../Models"

import "../template/SurveyHelper.js" as Helper


Page {
    id: page

    property bool downloaded: false
    property int updatesCount: 0

    property var hasSurveysPage
    property Component noSurveysPage
    property bool debug: false

    property Settings settings: app.settings

    readonly property string kSettingsGroup: "DownloadSurveys/"
    readonly property string kSettingSortProperty: kSettingsGroup + "sortProperty"
    readonly property string kSettingSortOrder: kSettingsGroup + "sortOrder"

    //--------------------------------------------------------------------------

    backPage: surveysFolder.forms.length > 0 ? hasSurveysPage : noSurveysPage
    title: qsTr("Download Surveys")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        readSettings();

        if (portal.signedIn) {
            searchModel.update();
        }
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        writeSettings();

        if (downloaded) {
            surveysFolder.update();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        onSignedInChanged: {
            if (portal.signedIn) {
                searchModel.update();
            }
        }
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        listView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Rectangle {
            id: listArea

            anchors.fill: parent

            color: "transparent" //"#40ffffff"
            radius: 10

            Column {
                anchors {
                    fill: parent
                    margins: 10 * AppFramework.displayScaleFactor
                }

                spacing: 10 * AppFramework.displayScaleFactor
                visible: searchModel.count == 0 && !searchRequest.busy

                AppText {
                    width: parent.width
                    color: textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: qsTr('<center>There are no surveys shared with <b>%2</b>, username <b>%1</b>.<br><hr>Please visit <a href="http://survey123.esri.com">http://survey123.esri.com</a> to create a survey or see your system admininstrator.</center>').arg(portal.user.username).arg(portal.user.fullName)
                    textFormat: Text.RichText

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                ConfirmButton {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: qsTr("Refresh")

                    onClicked: {
                        search();
                    }
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                visible: portal.signedIn && searchModel.count > 0

                XFormProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6 * AppFramework.displayScaleFactor

                    visible: searchRequest.busy && searchRequest.total > 0
                    value: searchRequest.count
                    minimumValue: 0
                    maximumValue: searchRequest.total
                }

                RowLayout {
                    id: toolsLayout

                    Layout.fillWidth: true

                    visible: !searchRequest.busy
                    spacing: 5 * AppFramework.displayScaleFactor

                    StyledImageButton {
                        Layout.preferredHeight: toolsLayout.height
                        Layout.preferredWidth: Layout.preferredHeight

                        checkable: true
                        checked: searchModel.sortProperty === searchModel.kPropertyDate
                        checkedColor: page.headerBarColor

                        source: "images/sort-time-" + searchModel.sortOrder + ".png"

                        onClicked: {
                            if (checked) {
                                searchModel.toggleSortOrder();
                            } else {
                                searchModel.sortProperty = searchModel.kPropertyDate;
                                searchModel.sortOrder = searchModel.kSortOrderDesc;
                            }
                            filteredGalleryModel.visualModel.sortItems();
                        }
                    }

                    StyledImageButton {
                        Layout.preferredHeight: toolsLayout.height
                        Layout.preferredWidth: Layout.preferredHeight

                        checkable: true
                        checked: searchModel.sortProperty === searchModel.kPropertyTitle
                        checkedColor: page.headerBarColor

                        source: "images/sort-text-" + searchModel.sortOrder + ".png"

                        onClicked: {
                            if (checked) {
                                searchModel.toggleSortOrder();
                            } else {
                                searchModel.sortProperty = searchModel.kPropertyTitle;
                                searchModel.sortOrder = searchModel.kSortOrderAsc;
                            }
                            filteredGalleryModel.visualModel.sortItems();
                        }
                    }

                    SearchField {
                        id: searchField

                        Layout.fillWidth: true

                        onEditingFinished: {
                            filteredGalleryModel.filterText = text;
                        }
                    }
                }

                ListView {
                    id: listView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: filteredGalleryModel.visualModel
                    spacing: 5 * AppFramework.displayScaleFactor
                    clip: true

                    delegate: Rectangle {
                        id: surveyDelegate

                        width: ListView.view.width
                        height: rowLayout.height + rowLayout.anchors.margins * 2
                        radius: 4
                        property var surveyPath: index >= 0 ? listView.model.get(index).path : ""
                        property var localSurvey: index >= 0 ? listView.model.get(index).isLocal : false

                        color: surveyMouseArea.containsMouse ? surveyMouseArea.pressed ? "#90cdf2" : "#e1f0fb" : "#fefefe"
                        border {
                            width: 1
                            color: "#e5e6e7"
                        }

                        MouseArea {
                            id: surveyMouseArea

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {
                                if (surveyDelegate.localSurvey) {
                                    page.Stack.view.push([
                                                             {
                                                                 item: surveyPage,
                                                                 replace: true,
                                                                 properties: {
                                                                     surveyPath: surveyDelegate.surveyPath
                                                                 }
                                                             },

                                                             {
                                                                 item: surveyView,
                                                                 replace: true,
                                                                 properties: {
                                                                     surveyPath: surveyDelegate.surveyPath,
                                                                     rowid: null
                                                                 }
                                                             }
                                                         ]);
                                } else {
                                    downloadSurvey.download(filteredGalleryModel.visualModel.get(index));
                                }
                            }
                        }

                        RowLayout {
                            id: rowLayout

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 5
                            }

                            Image {
                                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                                Layout.preferredHeight: 66 * AppFramework.displayScaleFactor
                                source: portal.restUrl + "/content/items/" + id + "/info/" + thumbnail + "?token=" + portal.token
                                fillMode: Image.PreserveAspectFit

                                Rectangle {
                                    anchors.fill: parent

                                    visible: surveyDelegate.localSurvey && surveyDelegate.surveyPath > ""
                                    color: surveyMouseArea.containsMouse ? "#10000000" : "transparent"
                                    border {
                                        width: 1
                                        color: "#30000000"
                                    }
                                }
                            }

                            Column {
                                Layout.fillWidth: true

                                spacing: 3 * AppFramework.displayScaleFactor

                                AppText {
                                    width: parent.width
                                    text: title
                                    font {
                                        pointSize: 16 * app.textScaleFactor
                                    }
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    color: "#323232"
                                }

                                //                                Text {
                                //                                    width: parent.width
                                //                                    text: modelData.snippet > "" ? modelData.snippet : ""
                                //                                    font {
                                //                                        pointSize: 12
                                //                                    }
                                //                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                //                                    color: textColor
                                //                                    visible: text > ""
                                //                                }

                                AppText {
                                    width: parent.width
                                    text: qsTr("Updated %1").arg(new Date(modified).toLocaleString(undefined, Locale.ShortFormat))
                                    font {
                                        pointSize: 11 * app.textScaleFactor
                                    }
                                    textFormat: Text.AutoText
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    color: "#7f8183"
                                }
                            }

                            ImageButton {
                                Layout.preferredWidth: 44 * AppFramework.displayScaleFactor
                                Layout.preferredHeight: 44 * AppFramework.displayScaleFactor

                                source: isLocal
                                        ? "images/cloud-refresh.png"
                                        : "images/cloud-download.png"

                                onClicked: {
                                    downloadSurvey.download(listView.model.get(index));
                                }
                            }
                        }
                    }

                    RefreshHeader {
                        refreshing: searchRequest.busy

                        onRefresh: {
                            search();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: false //portal.signedIn

                    Button {
                        Layout.alignment: Qt.AlignHCenter

                        text: qsTr("Update all %1 surveys").arg(updatesCount)
                        iconSource: "images/cloud-refresh.png"
                        enabled: false //updatesCount > 0

                        onClicked: {
                        }
                    }
                }
            }

        }

        Rectangle {
            anchors.fill: parent

            visible: searchRequest.busy && searchModel.count == 0
            color: page.backgroundColor

            AppText {
                id: searchingText

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                text: qsTr("Searching for surveys")
                color: "darkgrey"
                font {
                    pointSize: 18
                }
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            AppBusyIndicator {
                anchors {
                    top: searchingText.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: 10 * AppFramework.displayScaleFactor
                }

                running: parent.visible
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function search() {
        searchModel.update();
    }

    SortedListModel {
        id: searchModel

        signal updated()

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyDate: "modified"

        sortProperty: kPropertyTitle
        sortOrder: "asc"
        sortCaseSensitivity: Qt.CaseInsensitive

        function update() {
            updatesCount = 0;
            updateLocalPaths();
            searchRequest.start();
        }

        function updateLocalPaths() {
            for (var i = 0; i < searchModel.count; i++) {
                var item = searchModel.get(i);
                updateLocalPath(item);
            }
        }

        function updateLocalPath(item) {
            item.isLocal = surveysFolder.fileExists(item.id);

            if (item.isLocal) {
                item.path = searchModel.findForm(surveysFolder.folder(item.id));
            }
        }

        function findForm(folder) {
            var path;

            var files = folder.fileNames("*", true);
            files.forEach(function(fileName) {
                if (folder.fileInfo(fileName).suffix === "xml") {
                    path = folder.filePath(fileName);
                }
            });

            return path;
        }

        function sortItems() {
            sort();
        }

        onUpdated: {
            filteredGalleryModel.update();
        }
    }

    FilteredListModel {
        id: filteredGalleryModel

        sourceModel: searchModel
    }


    PortalSearch {
        id: searchRequest

        property bool busy: false

        portal: app.portal
        sortField: searchModel.sortProperty
        sortOrder: searchModel.sortOrder
        num: 25

        Component.onCompleted: {

            var query = portal.user.orgId > ""
                    ? '((NOT access:public) OR orgid:%1)'.arg(portal.user.orgId)
                    : 'NOT access:public';

            query += ' AND ((type:Form AND NOT tags:"draft" AND NOT typekeywords:draft) OR (type:"Code Sample" AND typekeywords:XForms AND tags:"xform"))';

            q = query;
        }

        onSuccess: {
            if (response.start === 1) {
                searchModel.clear();
            }

            response.results.forEach(function (result) {
                result.isLocal = surveysFolder.fileExists(result.id);

                if (result.isLocal) {
                    updatesCount++;

                    result.path = searchModel.findForm(surveysFolder.folder(result.id));
                }

                searchModel.append(Helper.removeArrayProperties(result));
            });

            if (response.nextStart > 0) {
                search(response.nextStart);
            } else {
                searchModel.sortItems();
                searchModel.updated();

                searchRequest.busy = false;
            }
        }

        function start() {
            searchRequest.busy = true;
            search();
        }
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        var value = settings.value(kSettingSortProperty, searchModel.kPropertyTitle);
        if ([searchModel.kPropertyTitle, searchModel.kPropertyDate].indexOf(value) < 0) {
            value = searchModel.kPropertyTitle;
        }
        searchModel.sortProperty = value;

        value = settings.value(kSettingSortOrder, searchModel.kSortOrderAsc);
        if ([searchModel.kSortOrderAsc, searchModel.kSortOrderDesc].indexOf(value) < 0) {
            value = searchModel.kSortOrderAsc;
        }
        searchModel.sortOrder = value;
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        settings.setValue(kSettingSortProperty, searchModel.sortProperty);
        settings.setValue(kSettingSortOrder, searchModel.sortOrder);
    }

    //--------------------------------------------------------------------------

    DownloadSurvey {
        id: downloadSurvey

        portal: app.portal
        progressPanel: progressPanel
        debug: debug

        onSucceeded: {
            page.downloaded = true;
            //surveysFolder.update();
            searchModel.update();
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        progressBar.visible: progressBar.value > 0
    }

    //--------------------------------------------------------------------------
}
