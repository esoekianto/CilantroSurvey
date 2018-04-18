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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Item {
    property bool showLibraryIcon: true
    property var mapPackages

    ScrollView {
        anchors {
            fill: parent
        }
        
        ListView {
            model: mapPackages

            spacing: AppFramework.displayScaleFactor * 5
            
            delegate: mapPackageDelegate
        }
    }
    
    Component {
        id: mapPackageDelegate
        
        Rectangle {
            width: ListView.view.width
            height: layout.height + layout.anchors.margins * 2
            
            radius: 4
            color: "#08000000"
            border {
                width: 1
                color: "#30000000"
            }
            
            MapPackage {
                id: mapPackage
                portal: app.portal
                info: mapPackages.get(index)
                
                onProgressChanged: {
                    progressPanel.progressBar.value = progress;
                }
                
                onDownloaded: {
                    progressPanel.close();
                }
                
                onFailed: {
                    progressPanel.closeError(qsTr("Download Map Package Error"));
                }

                Connections {
                    target: mapPackage.portal

                    onSignedInChanged: {
                        if (portal.signedIn) {
                            mapPackage.requestItemInfo();
                        }
                    }
                }
            }
            
            ColumnLayout {
                id: layout
                
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 5 * AppFramework.displayScaleFactor
                }
                
                RowLayout {
                    id: rowLayout
                    
                    Layout.fillWidth: true
                    
                    Image {
                        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 66 * AppFramework.displayScaleFactor
                        
                        source: thumbnailUrl
                        fillMode: Image.PreserveAspectFit
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border {
                                width: 1
                                color: "#20000000"
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                margins: -3 * AppFramework.displayScaleFactor
                            }

                            width: 30 * AppFramework.displayScaleFactor
                            height: width

                            radius: 3
                            color: accentColor
                            border {
                                width: 1
                                color: "white"
                            }

                            visible: storeInLibrary && showLibraryIcon

                            Image {
                                id: libraryImage

                                anchors {
                                    fill: parent
                                    margins: 3
                                }

                                source: "images/maps-folder.png"
                            }

                            ColorOverlay {
                                anchors.fill: libraryImage
                                source: libraryImage
                                color: "white"
                            }
                        }

                    }
                    
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        
                        Text {
                            width: parent.width
                            
                            text: mapPackage.name > "" ? mapPackage.name : mapPackage.itemId
                            font {
                                bold: true
                                pointSize: 14
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                        }
                        
                        Text {
                            id: descriptionText
                            
                            width: parent.width
                            
                            text: mapPackage.description
                            font {
                                pointSize: 12
                            }
                            elide: Text.ElideRight
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                            visible: text > ""
                            
                            MouseArea {
                                anchors.fill: parent
                                
                                onClicked: {
                                    descriptionText.elide = descriptionText.elide == Text.ElideNone ? Text.ElideRight : Text.ElideNone
                                }
                            }
                        }
                        
                        Text {
                            width: parent.width
                            
                            text: qsTr("%1 mb").arg(mapPackage.localSize)
                            font {
                                pointSize: 12
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                            visible: mapPackage.isLocal
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#80000000"
                            visible: mapPackage.canDownload
                        }
                        
                        Text {
                            width: parent.width
                            
                            text: mapPackage.updateAvailable
                                  ? qsTr("Update available %1").arg(mapPackage.updateDate.toLocaleString(undefined, Locale.ShortFormat))
                                  : qsTr("Update not required")
                            font {
                                pointSize: 12
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                            visible: mapPackage.canDownload && mapPackage.isLocal
                        }
                        
                        Text {
                            width: parent.width
                            
                            text: qsTr("%1 mb").arg(mapPackage.updateSize)
                            font {
                                pointSize: 12
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                            visible: mapPackage.canDownload && (mapPackage.updateAvailable || !mapPackage.isLocal)
                        }
                        
                    }
                    
                    Column {
                        Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                        
                        spacing: 5 * AppFramework.displayScaleFactor
                        
                        ImageButton {
                            width: parent.width
                            height: width
                            
                            visible: mapPackage.isLocal
                            source: "images/trash_bin.png"
                            
                            onClicked: {
                                confirmPanel.clear();
                                confirmPanel.icon = "images/warning.png";
                                confirmPanel.title = qsTr("Delete Map Package");
                                confirmPanel.text = qsTr("This action will delete the map package <b>%1</b> from this device.").arg(mapPackage.name);
                                confirmPanel.question = qsTr("Are you sure want to delete the map package?");
                                
                                confirmPanel.show(mapPackage.deleteLocal);
                            }
                        }
                        
                        ImageButton {
                            width: parent.width
                            height: width
                            
                            visible: mapPackage.canDownload
                            source: mapPackage.isLocal
                                    ? "images/cloud-refresh.png"
                                    : "images/cloud-download.png"
                            
                            onClicked: {
                                progressPanel.title = qsTr("Downloading Map Package");
                                progressPanel.message = mapPackage.name;
                                progressPanel.open();
                                
                                mapPackage.requestDownload();
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true

                    text: mapPackage.errorText
                    visible: text > ""
                    color: "red"
                    font {
                        bold: true
                    }

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            Component.onCompleted: {
                if (AppFramework.network.isOnline) {
                    mapPackage.requestItemInfo();
                }
            }
        }
    }
}
