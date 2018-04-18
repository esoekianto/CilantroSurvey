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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"

Item {
    //--------------------------------------------------------------------------

    Component.onCompleted: {
        AppFramework.logging.userData = app.settings.value("Logging/userData", "");
    }

    //--------------------------------------------------------------------------

    Connections {
        target: AppFramework.logging

        onOutputLocationChanged: {
            outputTextField.text = Qt.binding(function () {
                return AppFramework.logging.outputLocation;
            });
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 5 * AppFramework.displayScaleFactor

        RowLayout {
            Layout.fillWidth: true

            StyledSwitch {
                checked: AppFramework.logging.enabled
                enabled: AppFramework.logging || outputTextField.text > ""

                onCheckedChanged: {
                    forceActiveFocus();
                    AppFramework.logging.enabled = checked;
                }
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("Logging")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            AppText {
                Layout.fillWidth: true
                text: qsTr("Log output location")
            }

            StyledTextField {
                id: outputTextField

                Layout.fillWidth: true

                text: AppFramework.logging.outputLocation
                readOnly: AppFramework.logging.enabled

                onEditingFinished: {
                    AppFramework.logging.outputLocation = text;
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: !AppFramework.logging.enabled

                AppText {
                    Layout.fillWidth: true
                    text: qsTr("Searching for AppStudio consoles")
                    visible: syslogDiscoveryAgent.model.count == 0
                }

                AppText {
                    Layout.fillWidth: true
                    text: qsTr("Select an AppStudio console")
                    visible: syslogDiscoveryAgent.model.count > 0
                }

                ListView {
                    id: consolesListView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: syslogDiscoveryAgent.model
                    clip: true
                    spacing: 5 * AppFramework.displayScaleFactor
                    delegate: consoleItem

                    AppBusyIndicator {
                        anchors.centerIn: parent

                        running: syslogDiscoveryAgent.model.count == 0
                        visible: running
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: AppFramework.logging.enabled
            }

            Rectangle {
                Layout.fillWidth: true

                height: 1
                color: "black"
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("User data")
            }

            StyledTextField {
                Layout.fillWidth: true

                text: AppFramework.logging.userData

                onEditingFinished: {
                    AppFramework.logging.userData = text;
                    app.settings.setValue("Logging/userData", text);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: consoleItem

        Rectangle {
            width: ListView.view.width
            height: consoleItemLayout.height + consoleItemLayout.anchors.margins * 2
            color: "white"
            border {
                width: 1
                color: "#80000000"
            }
            radius: 4 * AppFramework.displayScaleFactor


            RowLayout {
                id: consoleItemLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top : parent.top

                    margins: 5 * AppFramework.displayScaleFactor
                }

                Image {
                    Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    source: "images/AppConsole.png"
                    fillMode: Image.PreserveAspectFit
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    AppText {
                        Layout.fillWidth: true
                        text: displayName
                    }
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    AppFramework.logging.outputLocation = consolesListView.model.get(index).outputLocation;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    SyslogDiscoveryAgent {
        id: syslogDiscoveryAgent

        Component.onCompleted: {
            start();
        }
    }

    //--------------------------------------------------------------------------
}
