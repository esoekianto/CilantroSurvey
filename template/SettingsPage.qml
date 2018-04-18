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
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../Portal"

Page {
    id: page

    title: qsTr("Settings")
    contentMargins: 0

    property real referenceDpi: Qt.platform.os === "windows" ? 96 : 72
    property real referenceScaleFactor: (Screen.logicalPixelDensity * 25.4) / (Qt.platform.os === "windows" ? 96 : 72)

    actionButton {
        visible: true

        menu: Menu {
            /*
            MenuItem {
                text: qsTr("Reinitialize Database")

                onTriggered: {
                    surveysDatabase.reinitialize();
                }
            }

            MenuItem {
                text: qsTr("Delete Submitted Surveys")

                onTriggered: {
                    surveysDatabase.deleteSurveys(surveysDatabase.statusSubmitted);
                }
            }
            */

            MenuItem {
                text: qsTr("Map Library")
                iconSource: "images/maps-folder.png"

                onTriggered: {
                    if (AppFramework.network.isOnline) {
                        showSignInOrMapsPage();
                    } else {
                        showMapsPage();
                    }
                }

                function showSignInOrMapsPage() {
                    portal.signInAction(qsTr("Please sign in to manage the maps library"), showMapsPage);
                }

                function showMapsPage() {
                    page.Stack.view.push(mapLibraryPage);
                }

            }
        }
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (Qt.platform.os !== "ios") {
            settingsTab.insertTab(1, qsTr("Map"), mapTab);
        }

        settingsTab.addTab(qsTr("Diagnostics"), diagnosticsTab);
    }

    contentItem: ColumnLayout {
        spacing: 15 * AppFramework.displayScaleFactor

        AppTabView {
            id: settingsTab

            Layout.fillWidth: true
            Layout.fillHeight: true

            tabPosition: Qt.BottomEdge
            frameVisible: false
/*
            tabsTextColor: "#c0c0c0"
            //tabsBackgroundColor:
            tabsSelectedTextColor: "#ffffff"
            tabsSelectedBackgroundColor: "transparent"
            tabsBorderColor: "transparent"
            showImages: true
*/
            SettingsTabText {
            }

            SettingsTabPortal {
            }

            /*
            SettingsTabImages {
            }
            */

            SettingsTabAdvanced {
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTab

        SettingsTabMap {
        }
    }

    Component {
        id: diagnosticsTab

        SettingsTabDiagnostics {
        }
    }

    Component {
        id: mapLibraryPage

        MapLibraryPage {

        }
    }

    ConfirmPanel {
        id: confirmPanel
    }

    //--------------------------------------------------------------------------
}
