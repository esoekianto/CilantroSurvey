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

Tab {
    title: qsTr("Advanced")

    property color hoveredColor: "#ff8082"
    property color pressedColor: "#ff4a4d"
    
    Item {
        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 20 * AppFramework.displayScaleFactor

            Item {
                Layout.fillHeight: true
            }

            AppButton {
                //            Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                text: qsTr("Reinitialize Database")
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor

                onClicked: {
                    confirmPanel.clear();
                    confirmPanel.icon = "images/warning.png";
                    confirmPanel.title = text;
                    confirmPanel.text = qsTr("This action will reinitialize the survey database and delete all collected survey data.");
                    confirmPanel.question = qsTr("Are you sure want to reinitialize the database?");

                    confirmPanel.show(function () {
                        surveysDatabase.reinitialize();
                    });
                }
            }

            AppButton {
                Layout.fillWidth: true

                text: qsTr("Fix Database")
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor

                onClicked: {
                    surveysDatabase.fixSurveysPath();
                }
            }

            AppButton {
                //            Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true


                text: qsTr("Delete Submitted Surveys")
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor

                onClicked: {
                    confirmPanel.clear();
                    confirmPanel.icon = "images/warning.png";
                    confirmPanel.title = text;
                    confirmPanel.text = qsTr("This action will delete any surveys that have been submitted.");
                    confirmPanel.question = qsTr("Are you sure want to delete the submitted surveys?");

                    confirmPanel.show(function () {
                        surveysDatabase.deleteSurveys(surveysDatabase.statusSubmitted);
                    });
                }
            }

            AppButton {
                //            Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true


                property FileFolder cacheFolder: AppFramework.standardPaths.writableFolder(StandardPaths.GenericCacheLocation).folder("QtLocation/ArcGIS")

                visible: cacheFolder.exists
                text: qsTr("Clear Map Cache (%1 Mb)").arg(mb(cacheFolder.size))
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor
                activateDelay: 1500
                activateColor: "#90cdf2"

                onClicked: {
                    if (checked) {
                        checked = false;
                    } else {
                        console.log("Removing cache folder:", cacheFolder.path);
                        cacheFolder.removeFolder();
                    }
                }

                onActivated: {
                    checked = false;
                    Qt.openUrlExternally(cacheFolder.url);
                }

                function mb(bytes) {
                    var mb = bytes / 1048576;

                    return mb.toFixed(2);
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.fillWidth: true

                height: 1
                color: "#40000000"
            }

            AppText {
                Layout.fillWidth: true

                visible: positionSourceManager.valid
                text: qsTr("Position Source: <b>%1</b>").arg(positionSourceManager.positionSource.name)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font {
                    pointSize: 12
                }

                color: app.textColor
                textFormat: Text.RichText
            }
        }

    }
}
