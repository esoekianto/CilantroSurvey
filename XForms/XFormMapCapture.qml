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
import QtQml 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtLocation 5.3
import QtPositioning 5.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as JS

Rectangle {
    id: mapCapture
    
    property alias map: map
    property XFormMapSettings mapSettings: xform.mapSettings
    property alias positionSourceManager: positionSourceConnection.positionSourceManager

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: AppFramework.alphaColor(accentColor, 0.9)
    property real coordinatePointSize: 12

    readonly property string kCaptureFileName: "mapcapture.png"

    //--------------------------------------------------------------------------

    signal accepted(ImageObject imageObject)
    signal rejected

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        map.positionMode = map.positionModeAutopan;
        positionSourceConnection.activate();

        map.addMapTypeMenuItems(mapMenu);

        mapSettings.selectMapType(map);
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: footer.top
        }

        spacing: 0

        Rectangle {
            id: titleBar

            Layout.fillWidth: true
            Layout.preferredHeight: columnLayout.height + 5

            property int buttonHeight: 35 * AppFramework.displayScaleFactor

            //height: columnLayout.height + 5
            color: barBackgroundColor //"#80000000"

            ColumnLayout {
                id: columnLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 2
                }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    ImageButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.buttonHeight
                        Layout.preferredWidth: titleBar.buttonHeight

                        source: "images/back.png"

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        onClicked: {
                            rejected();
                            mapCapture.parent.pop();
                        }
                    }

                    XFormText {
                        Layout.fillWidth: true

                        text: textValue(formElement.label, "", "long")
                        font {
                            pointSize: xform.style.titlePointSize
                            family: xform.style.titleFontFamily
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: barTextColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    XFormMenuButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.buttonHeight
                        Layout.preferredWidth: titleBar.buttonHeight

                        menuPanel: mapMenuPanel
                    }
                }

                XFormText {
                    Layout.fillWidth: true

                    text: textValue(formElement.hint, "", "long")
                    visible: text > ""
                    font {
                        pointSize: 12
                    }
                    horizontalAlignment: Text.AlignHCenter
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }
        }

        XFormMap {
            id: map

            Layout.fillWidth: true
            Layout.fillHeight: true

            property real positionZoomLevel: xform.mapSettings.positionZoomLevel

            positionSourceConnection: positionSourceConnection
            mapSettings: xform.mapSettings

            //        Behavior on zoomLevel {
            //            NumberAnimation {
            //                duration: 250
            //            }
            //        }

            MouseArea {
                anchors {
                    fill: parent
                }

                onClicked: {
                    map.center = map.toCoordinate(Qt.point(mouseX, mouseY));
                }
            }

            XFormMapMarker {
                zoomLevel: 0 //16

                coordinate: map.center
            }
        }
    }
    
    Rectangle {
        id: footer

        anchors {
            fill: footerRow
            margins: -footerRow.anchors.margins
        }

        color: barBackgroundColor //"#80000000"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                map.positionMode = map.positionModeOn;
                editingCoords = true;
            }

            onWheel: {

            }

            onDoubleClicked: {

            }
        }
    }

    RowLayout {
        id: footerRow

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor
        /*
        RowLayout {
            visible: !editingCoords

            ColumnLayout {
                spacing: 2 * AppFramework.displayScaleFactor

                RowLayout {
                    spacing: 2 * AppFramework.displayScaleFactor

                    Column {
                        spacing: 2 * AppFramework.displayScaleFactor

                        XFormText {
                            text: JS.formatLatitude(geopointMarker.coordinate.latitude, mapSettings.coordinateFormat)
                            font {
                                pointSize: coordinatePointSize
                            }
                            color: barTextColor
                        }

                        XFormText {
                            text: JS.formatLongitude(geopointMarker.coordinate.longitude, mapSettings.coordinateFormat)
                            font {
                                pointSize: coordinatePointSize
                            }
                            color: barTextColor
                        }
                    }

                    Column {
                        spacing: 2 * AppFramework.displayScaleFactor

                        XFormText {
                            visible: !isNaN(editHorizontalAccuracy)
                            text: qsTr("± %1 m").arg(editHorizontalAccuracy)
                            color: barTextColor
                            font {
                                pointSize: coordinatePointSize
                            }
                        }
                    }
                }

                Row {
                    visible: showAltitude && isFinite(editAltitude)
                    spacing: 2 * AppFramework.displayScaleFactor

                    XFormText {
                        text: qsTr("Alt")
                        color: barTextColor
                        font {
                            pointSize: coordinatePointSize
                        }
                    }

                    XFormText {
                        text: editAltitude.toFixed(1) + "m"
                        color: barTextColor
                        font {
                            pointSize: coordinatePointSize
                        }
                    }

                    XFormText {
                        visible: isFinite(editVerticalAccuracy)
                        text: qsTr("± %1 m").arg(editVerticalAccuracy)
                        color: barTextColor
                        font {
                            pointSize: coordinatePointSize
                        }
                    }
                }
            }
        }
*/
        ImageButton {
            Layout.fillHeight: true
            Layout.preferredHeight: titleBar.buttonHeight
            Layout.preferredWidth: titleBar.buttonHeight
            Layout.alignment: Qt.AlignRight

            source: "images/ok_button.png"

            ColorOverlay {
                anchors.fill: parent
                source: parent.image
                color: xform.style.titleTextColor
            }

            onClicked: {
                forceActiveFocus();
                snapMap()
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormMenuPanel {
        id: mapMenuPanel

        textColor: xform.style.titleTextColor
        backgroundColor: xform.style.titleBackgroundColor
        fontFamily: xform.style.menuFontFamily

        title: qsTr("Map Types")
        menu: Menu {
            id: mapMenu
        }
    }
    
    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection
        
        onNewPosition: {
            if (position.latitudeValid & position.longitudeValid) {
                //                if (isEditValid && wasValid != isEditValid) {
                //                    map.zoomLevel = previewZoomLevel;
                //                    map.center = position.coordinate;
                //                }

                if (map.zoomLevel < map.positionZoomLevel && map.positionMode == map.positionModeAutopan) {
                    map.zoomLevel = map.positionZoomLevel;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: folder
        path: AppFramework.standardPaths.writableLocation(StandardPaths.TempLocation)

        Component.onCompleted: {
            console.log("Map capture path:", path);
            //            makeFolder();
        }
    }

    ImageObject {
        id: imageObject
    }

    function snapMap() {
        console.log("Capturing map image");

        positionSourceConnection.active = false;
        map.mapControls.visible = false;

        map.grabToImage(function (result) {

            var path = folder.filePath(kCaptureFileName);

            console.log("Saving image:", path);
            var saved = result.saveToFile(path);

            console.log("Saved:", saved);

            imageObject.load(path);

            folder.removeFile(kCaptureFileName);

            accepted(imageObject)
            mapCapture.parent.pop();
        });
    }

    //--------------------------------------------------------------------------
}
