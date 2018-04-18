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
import QtLocation 5.3
import QtPositioning 5.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as JS

GroupBox {
    id: geopoly

    property XFormData formData

    property var formElement

    property var binding
    property bool polygon: false
    property var mapPoly


    property XFormMapSettings mapSettings: xform.mapSettings
    property int previewZoomLevel: mapSettings.previewZoomLevel

    readonly property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool readOnly: binding["@readonly"] === "true()"
    readonly property double accuracyThreshold: Number(formElement["@accuracyThreshold"])

    property var calculatedValue

    readonly property string coordsFormat: mapSettings.previewCoordinateFormat
    readonly property bool relevant: parent.relevant

    property bool isOnline: AppFramework.network.isOnline

    property bool isValid: true

    anchors {
        left: parent.left
        right: parent.right
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
//        if (isValid) {
//            previewMap.zoomLevel = previewZoomLevel;
//        } else {
//            previewMap.zoomLevel = 0;
//        }

        mapSettings.selectMapType(previewMap);

        if (polygon) {
            mapPoly = mapPolygon.createObject(previewMap);
        } else {
            mapPoly = mapPolyline.createObject(previewMap);
        }

        previewMap.addMapItem(mapPoly);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding) {
            setValue(calculatedValue.toString());
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: row

        width: parent.width
        //height: parent.height// 100 * AppFramework.displayScaleFactor
        layoutDirection: xform.languageDirection

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: (previewMap.hasMaps ? 150 : 50) * AppFramework.displayScaleFactor + coordsHeader.height

            color: "lightgrey"
            border {
                width: 1
                color: "#40000000"
            }

            Rectangle {
                id: coordsHeader
                anchors {
                    fill: coordsRow
                    margins: -coordsRow.anchors.margins
                }

                visible: coordsRow.visible
                color: coordsRow.backgroundColor
            }

            RowLayout {
                id: coordsRow

                property color textColor: "white"
                property color backgroundColor: isValid ? "#80000000" : "red"

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 5
                }

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true

                            visible: isValid

                            Flow {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignCenter

                                spacing: 5 * AppFramework.displayScaleFactor
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter

                            visible: !isValid
                            text: qsTr("No Location")
                            color: coordsRow.textColor
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter

                            visible: text > ""
                            text: positionSourceConnection.positionSourceManager.errorString
                            color: coordsRow.textColor
                            font {
                                bold: true
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        color: "#80FFFFFF"
                        radius: 5

                        visible: positionSourceConnection.valid && (!readOnly || !isValid)

                        ImageButton {
                            id: positionButton

                            anchors.fill: parent

                            source: positionSourceConnection.active ? "images/position-on.png" : "images/position-off.png"

                            onClicked: {
                                previewMap.fitViewportToMapItems();
                                if (positionSourceConnection.active) {
                                    positionSourceConnection.release();
                                } else {
                                    positionSourceConnection.activate();
                                    resetAverage();
                                }
                            }
                        }

                        ColorOverlay {
                            anchors.fill: positionButton
                            source: positionButton.image
                            //color: xform.style.textColor
                            color: coordsRow.textColor
                        }

                        BusyIndicator {
                            anchors.fill: parent
                            running: positionSourceConnection.active
                        }
                    }

                }
            }

            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: coordsHeader.bottom
                    bottom: parent.bottom
                    margins: 1
                }

                Map {
                    id: previewMap

                    property bool hasMaps: supportedMapTypes.length > 0

                    anchors.fill: parent

                    visible: hasMaps

                    plugin: XFormMapPlugin {
                        settings: mapSettings
                        offline: !isOnline
                    }

                    gesture {
                        enabled: false//isValid
                    }

                    //zoomLevel: isValid ? previewZoomLevel : 0

                    onCopyrightLinkActivated: Qt.openUrlExternally(link)

                    onActiveMapTypeChanged: { // Force update of min/max zoom levels
                        minimumZoomLevel = -1;
                        maximumZoomLevel = 9999;
                    }
                }

                Text {
                    anchors {
                        fill: parent
                        margins: 10
                    }

                    visible: isValid && !previewMap.hasMaps

                    text: isOnline
                          ? qsTr("Map preview not available")
                          : qsTr("Offline map preview not available")

                    color: "red"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    anchors.fill: parent

                    visible: pressText.visible

                    color: "#A0FFFFFF"
                }

                Text {
                    id: pressText

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    visible: !isValid && !readOnly && previewMap.hasMaps

                    text: qsTr("Press to capture location using a map")
                    color: "red"
                    font {
                        bold: true
                        pointSize: 15
                    }

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: !readOnly && previewMap.hasMaps

                    onWheel: {
                    }

                    onClicked: {
                        positionSourceConnection.release();
                        Qt.inputMethod.hide();
                        /*
                        xform.popoverStackView.push({
                                                        item: geopolyCapture,
                                                        properties: {
                                                            formElement: formElement,
                                                            editLatitude: latitude,
                                                            editLongitude: longitude,
                                                            editAltitude: altitude,
                                                            editHorizontalAccuracy: horizontalAccuracy,
                                                            editVerticalAccuracy: verticalAccuracy
                                                        }
                                                    });
                                                    */
                    }
                }
            }
        }

        XFormPositionSourceConnection {
            id: positionSourceConnection

            positionSourceManager: xform.positionSourceManager

            onNewPosition: {
                //console.log("Updating geopoly position:", JSON.stringify(position));
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapPolyline

        MapPolyline {
            line {
                color: "cyan"
                width: 2
            }
        }
    }

    Component {
        id: mapPolygon

        MapPolygon {
            color: "#40000000"

            border {
                color: "cyan"
                width: 2
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value) {

        //console.log("geopoly setValue:", JSON.stringify(value));

        positionSourceConnection.release();

        var doZoom = false;

        if (typeof value === "object") {
            doZoom = true;
        }
        else if (typeof value === "string") {
            var poly = JS.parsePoly(value);

            if (poly.length) {

                console.log("poly:", JSON.stringify(poly));

                mapPoly.path = poly;

                doZoom = true;
            }
        }
        else {
        }

        if (doZoom) {
            if (mapPoly.path && mapPoly.path.length) {
                zoomTimer.restart();
            } else {
                //previewMap.zoomLevel = previewZoomLevel;
            }
        }
    }

    Timer {
        id: zoomTimer

        repeat: false
        interval: 100
        triggeredOnStart: false

        onTriggered: {
            previewMap.fitViewportToMapItems();
        }
    }


    //--------------------------------------------------------------------------
}
