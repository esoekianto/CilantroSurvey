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

import QtQuick 2.4
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../XForms"
import "../Controls"

ListView {
    id: surveysList
    
    signal clicked(var survey)
    signal deleted(var survey);
    signal pressAndHold(var survey);

    //--------------------------------------------------------------------------

    property var currentSurvey: currentIndex >= 0 ? model.getSurvey(currentIndex) : null
    property XFormsDatabase xformsDatabase: app.surveysModel
    property bool debug: false
    property bool showDelete: true
    property alias refreshHeader: refreshHeader
    property color actionColor: "#90cdf2"

    //--------------------------------------------------------------------------

    clip: true
    model: filteredSurveysModel.visualModel //xformsDatabase
    spacing: 0//1 * AppFramework.displayScaleFactor

    delegate: Rectangle {
        property var formStatus: status
        property real iconSize: 40 * AppFramework.displayScaleFactor
        
        width: ListView.view.width
        height: viewRow.height + viewRow.anchors.margins * 2
        //radius: 4 * AppFramework.displayScaleFactor
        color: mouseArea.containsMouse ? mouseArea.pressed ? actionColor : "#e1f0fb" : "#fefefe"
        border {
            width: 1
            color: "#e5e6e7"
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            
            hoverEnabled: true
            onClicked: {
                surveysList.currentIndex = index;
                surveysList.clicked(surveysList.model.getSurvey(index));
            }

            onPressAndHold: {
                surveysList.currentIndex = index;
                surveysList.pressAndHold(surveysList.model.getSurvey(index));
            }
        }
        
        RowLayout {
            id: viewRow

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 4 * AppFramework.displayScaleFactor
            }
            
            AppText {
                Layout.preferredWidth: 25 * AppFramework.displayScaleFactor

                visible: debug
                text: rowid
                horizontalAlignment: Text.AlignRight
                color: textColor
            }
            
            Image {
                Layout.preferredWidth: iconSize * 0.75
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignTop

                fillMode: Image.PreserveAspectFit
                source: statusIcon(formStatus)
            }

            Column {
                Layout.fillWidth: true

                spacing: 3 * AppFramework.displayScaleFactor

                AppText {
                    width: parent.width
                    text: snippet || ""
                    font {
                        pointSize: 16 * app.textScaleFactor
                    }
                    color: textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                AppText {
                    width: parent.width
                    text: updated > "" ? qsTr("Modified %1").arg(new Date(updated).toLocaleString(undefined, Locale.ShortFormat)) : ""
                    font {
                        pointSize: 11 * app.textScaleFactor
                    }
                    color: "#7f8183"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    visible:  text > ""
                }
            }

            StyledImage {
                Layout.preferredWidth: iconSize
                Layout.preferredHeight: iconSize

                visible: favorite > 0 ? true : false
                source: "images/favorite.png"
            }

            StyledImageButton {
                Layout.preferredHeight: iconSize
                Layout.preferredWidth: iconSize

                visible: showDelete
                source: "images/trash_bin.png"
                color: actionColor

                onClicked: {
                    surveysList.currentIndex = index;
                    confirmDelete(surveysList.model.getSurvey(index));
                }
            }
        }

        function statusIcon(status) {
            switch(status) {
            case xformsDatabase.statusDraft:
                return "images/survey-review.png";

            case xformsDatabase.statusComplete:
                return "images/survey-submit.png";

            case xformsDatabase.statusSubmitted:
                return "images/survey-sent.png";

            case xformsDatabase.statusSubmitError:
                return "images/survey-error.png";

            case xformsDatabase.statusInbox:
                return "images/survey-inbox.png";

            default:
                return "images/survey.png";
            }
        }
    }

    function confirmDelete(survey) {
        confirmPanel.survey = survey;
        confirmPanel.clear();
        confirmPanel.icon = "images/warning.png";
        confirmPanel.title = qsTr("Delete");
        confirmPanel.text = qsTr("This action will delete the selected survey");
        confirmPanel.question = qsTr("Are you sure want to delete the survey?");

        confirmPanel.show(deleteSurvey);
    }

    function deleteSurvey() {
        var survey = confirmPanel.survey;
        var rowid = survey.rowid;
        console.log("delete rowid", rowid);
        xformsDatabase.deleteSurvey(rowid);
        xformsDatabase.refresh(surveyPath);

        deleted(survey);
    }

    ConfirmPanel {
        id: confirmPanel

        parent: app

        property var survey
    }

    //--------------------------------------------------------------------------

    RefreshHeader {
        id: refreshHeader
    }

    //--------------------------------------------------------------------------
}
