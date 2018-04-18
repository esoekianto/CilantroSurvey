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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Item {
    Component.onDestruction: {
        var paths = mapLibraryTextField.text.trim();

        if (paths.length <= 0) {
            paths = kDefaultMapLibraryPath;
        }

        app.mapLibraryPaths = paths;
        settings.setValue("mapLibraryPaths", paths, kDefaultMapLibraryPath);
    }

    GroupBox {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
            topMargin: 15 * AppFramework.displayScaleFactor
        }

        //--------------------------------------------------------------------------

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("Map Library Folder")
                color: app.textColor

                MouseArea {
                    anchors.fill: parent

                    onPressAndHold: {
                        storageComboBox.visible = !storageComboBox.visible;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                TextField {
                    id: mapLibraryTextField

                    Layout.fillWidth: true

                    text: app.mapLibraryPaths

                    style: TextFieldStyle {
                        renderType: Text.QtRendering
                        textColor: "black"
                        background: Rectangle {
                            implicitWidth: 100
                            implicitHeight: 24
                            color: "white"
                            radius: 2
                            border {
                                color: "#333"
                                width: 1
                            }
                        }
                    }
                }

                ImageButton {
                    Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                    source: "images/maps-folder.png"

                    onClicked: {
                        var folders = mapLibraryTextField.text.split(";");

                        if (folders.length > 0) {
                            var folder = AppFramework.fileFolder(folders[0]);
                            console.log("library:", folder.url);
                            mapLibraryDialog.folder = folder.url;
                        } else {
                            mapLibraryDialog.folder = mapLibraryDialog.shortcuts.home;
                        }

                        mapLibraryDialog.open();
                    }
                }
            }

            ComboBox {
                id: storageComboBox

                Layout.fillWidth: true

                visible: false
                model: storageInfo.mountedVolumes
                textRole: "displayName"

                onActivated: {
                    if (mapLibraryTextField.text.trim() > "") {
                        mapLibraryTextField.text += ";"
                    }

                    mapLibraryTextField.text += storageInfo.mountedVolumes[index].folder.filePath("Maps");
                }

                Component.onCompleted: {
                    currentIndex = -1;
                }

                StorageInfo {
                    id: storageInfo
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    FileDialog {
        id: mapLibraryDialog

        title: qsTr("Map Library Folder")
        selectFolder: true
        selectExisting: true

        onAccepted: {
            var urlInfo = AppFramework.urlInfo(folder);

            mapLibraryTextField.text = urlInfo.path;
        }
    }

    //--------------------------------------------------------------------------
}
