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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Page {
    id: page

    title: qsTr("About %1").arg(app.info.title)

    property bool debug: false

    contentItem: ScrollView {
        id: scrollView

        Column {
            width: scrollView.width
            spacing: 10 * AppFramework.displayScaleFactor

            AboutText {
                text: qsTr("Version %1").arg(app.info.version)
                font {
                    pointSize: 14
                }
                horizontalAlignment: Text.AlignHCenter
            }

            AboutText {
                text: app.info.description
                textFormat: Text.RichText
            }

            AboutSeparator {
            }

            Image {
                width: parent.width
                height: 50 * AppFramework.displayScaleFactor

                source: app.folder.fileUrl(app.info.propertyValue("companyLogo", ""))
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally(app.info.propertyValue("companyUrl", ""))
                    }
                }
            }

            AboutSeparator {
            }

            AboutText {
                text: qsTr("License Agreement")
                font {
                    pointSize: 15
                    bold: true
                }
                horizontalAlignment: Text.AlignHCenter
            }

            AboutText {
                text: app.info.licenseInfo
            }

            Column {
                id: footer

                anchors {
                    left: parent.left
                    right: parent.right
//                    margins: 10 * AppFramework.displayScaleFactor
                }

                spacing: 5 * AppFramework.displayScaleFactor

                AboutSeparator {
                }

                Item {
                    width: parent.width
                    height: 20 * AppFramework.displayScaleFactor

                    AboutLabelValue {
                        label: qsTr("AppFramework version:")
                        value: AppFramework.version
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressAndHold: {
                             debug = !debug;
                        }
                    }
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Device Architecture:")
                    value: AppFramework.systemInformation.unixMachine !== undefined
                           ? AppFramework.systemInformation.unixMachine
                           : ""
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Qt version:")
                    value: AppFramework.qtVersion
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Operating system version:")
                    value: AppFramework.osVersion
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Kernel version:")
                    value: AppFramework.kernelVersion
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("SSL library version:")
                    value: AppFramework.sslLibraryVersion
                }

                AboutLabelValue {
                    property var locale: Qt.locale()

                    visible: debug
                    label: qsTr("Locale:")
                    value: "%1 %2".arg(locale.name).arg(locale.nativeLanguageName)
                }

                AboutSeparator {
                    visible: debug
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("User home path:")
                    value: AppFramework.userHomePath

                    onClicked: {
                        Qt.openUrlExternally(AppFramework.userHomeFolder.url);
                    }
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Surveys folder:")
                    value: surveysFolder.path

                    onClicked: {
                        Qt.openUrlExternally(surveysFolder.url);
                    }
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Maps library:")
                    value: surveysFolder.filePath("Maps")

                    onClicked: {
                        Qt.openUrlExternally(surveysFolder.fileUrl("Maps"));
                    }
                }

                AboutLabelValue {
                    visible: debug && portal.signedIn
                    label: "Token expiry:"
                    value: portal.expires.toLocaleString()
                }

                /*
            AboutText {
                text: qsTr("Attchments folder: %1").arg(surveysFolder.path)
            }
*/

            }
        }
    }
}
