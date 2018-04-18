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
import QtLocation 5.3
import QtPositioning 5.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as JS

GroupBox {
    property XFormData formData

    property var formElement

    property var binding

    property alias horizontalAccuracy: geoposition.horizontalAccuracy

    property alias isValid: geoposition.isValid

    XFormGeoposition {
        id: geoposition

        onChanged: {
            updateValue();
        }
    }

    property XFormMapSettings mapSettings: xform.mapSettings
    property int previewZoomLevel: mapSettings.previewZoomLevel

    readonly property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool readOnly: binding["@readonly"] === "true()"
    readonly property double accuracyThreshold: Number(formElement["@accuracyThreshold"])
    readonly property bool isAccurate: accuracyThreshold <= 0 || !isFinite(accuracyThreshold) || !geoposition.horizontalAccuracyValid ? true : geoposition.horizontalAccuracy <= accuracyThreshold
    property bool showAccuracy: true
    property color accurateFillColor: "#4000B2FF"
    property color accurateBorderColor: "#8000B2FF"
    property color inaccurateFillColor: "#40FF0000"
    property color inaccurateBorderColor: "#A0FF0000"

    property var calculatedValue

    readonly property string coordsFormat: mapSettings.previewCoordinateFormat
    readonly property bool relevant: parent.relevant

    property bool isOnline: AppFramework.network.isOnline

    property bool autoActivatePositionSource: true
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated, 4=Position source

    readonly property bool supportsZ: JS.geometryTypeHasZ(binding["@esri:fieldType"])

    property int averageSeconds: 0
    property int averageTotalCount: 0


    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    flat: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (isValid) {
            previewMap.zoomLevel = previewZoomLevel;
        } else {
            previewMap.zoomLevel = 0;
        }

        mapSettings.selectMapType(previewMap);

        if (autoActivatePositionSource) {
            positionSourceConnection.activate();
        }
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
        if (relevant && changeReason !== 1) {
            setValue(calculatedValue.toString(), 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    //    onLatitudeChanged: {
    //        updateValue();
    //    }

    //    onLongitudeChanged: {
    //        updateValue();
    //    }

    //    onAltitudeChanged: {
    //        updateValue();
    //    }

    RowLayout {
        id: row

        width: parent.width
        //height: parent.height// 100 * AppFramework.displayScaleFactor
        layoutDirection: xform.languageDirection

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: (previewMap.hasMaps ? 100 : 50) * AppFramework.displayScaleFactor + coordsHeader.height

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
                property color backgroundColor: isAccurate && isValid ? "#80000000" : "red"

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

                                XFormText {
                                    text: JS.formatLatitude(geoposition.latitude, coordsFormat)
                                    color: coordsRow.textColor
                                    font.bold: true
                                }

                                XFormText {
                                    text: JS.formatLongitude(geoposition.longitude, coordsFormat)
                                    color: coordsRow.textColor
                                    font.bold: true
                                }

                                XFormText {
                                    visible: geoposition.horizontalAccuracyValid
                                    text: qsTr("± %1 m").arg(geoposition.horizontalAccuracy)
                                    color: coordsRow.textColor
                                    font.bold: true
                                }

                                Row {
                                    visible: supportsZ && geoposition.altitudeValid
                                    spacing: 3 * AppFramework.displayScaleFactor

                                    XFormText {
                                        text: qsTr("Alt")
                                        color: coordsRow.textColor
                                    }

                                    XFormText {
                                        text: geoposition.altitude.toFixed(1) + "m"
                                        color: coordsRow.textColor
                                        font.bold: true
                                    }

                                    XFormText {
                                        visible: geoposition.verticalAccuracyValid
                                        text: qsTr("± %1 m").arg(geoposition.verticalAccuracy)
                                        color: coordsRow.textColor
                                        font.bold: true
                                    }
                                }
                            }

                            XFormText {
                                Layout.fillWidth: true

                                visible: (positionSourceConnection.active && geoposition.averaging) || geoposition.averageCount > 0
                                text: qsTr("Averaged %1 of %2 positions (%3 seconds)").arg(geoposition.averageCount).arg(averageTotalCount).arg(averageSeconds)
                                color: coordsRow.textColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            XFormText {
                                Layout.fillWidth: true

                                visible: !isAccurate
                                text: qsTr("Coordinates are not within the accuracy threshold of %1 m").arg(accuracyThreshold)
                                color: coordsRow.textColor
                                font {
                                    bold: true
                                }
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }

                        XFormText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter

                            visible: !isValid
                            text: qsTr("No Location")
                            color: coordsRow.textColor
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        XFormText {
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
                                if (positionSourceConnection.active) {
                                    positionSourceConnection.release();
                                    geoposition.averageEnd();
                                } else {
                                    geoposition.averageClear();
                                    positionSourceConnection.activate();
                                }
                            }

                            onPressAndHold: {
                                if (!geoposition.averaging || !positionSourceConnection.active) {
                                    averageTotalCount = 0;
                                    averageSeconds = 0;
                                    geoposition.averageBegin();
                                }
                                positionSourceConnection.activate();
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

                        Timer {
                            interval: 1000
                            running: positionSourceConnection.active && geoposition.averaging
                            repeat: true
                            triggeredOnStart: false

                            onTriggered: {
                                averageSeconds++;
                            }
                        }
                    }

                    Loader {
                        id: calculateButtonLoader

                        Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        sourceComponent: calculateButtonComponent
                        active: false
                        visible: (changeReason === 1 || changeReason === 4) && active
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

                    zoomLevel: isValid ? previewZoomLevel : 0
                    center {
                        latitude: geoposition.latitude
                        longitude: geoposition.longitude
                    }

                    //activeMapType: supportedMapTypes[0]

                    /*
                Component.onCompleted: {
                    console.log("previewMap # maps:", previewMap.supportedMapTypes.length, mapSettings.appendMapTypes);

                    for (var i = 0; i < previewMap.supportedMapTypes.length; i++) {
                        var mapType = previewMap.supportedMapTypes[i];
                        console.log("mapType", i, mapType.name, mapType.description);
                    }
                }
                */

                    onCopyrightLinkActivated: Qt.openUrlExternally(link)

                    onActiveMapTypeChanged: { // Force update of min/max zoom levels
                        minimumZoomLevel = -1;
                        maximumZoomLevel = 9999;
                    }

                    MapCircle {
                        visible: showAccuracy && geoposition.horizontalAccuracyValid && geoposition.horizontalAccuracy > 0

                        radius: horizontalAccuracy
                        center: mapMarker.coordinate
                        color: isAccurate ? accurateFillColor : inaccurateFillColor
                        border {
                            width: 1
                            color: isAccurate ? accurateBorderColor : inaccurateBorderColor
                        }
                    }

                    XFormMapMarker {
                        id: mapMarker

                        visible: isValid
                        coordinate {
                            latitude: geoposition.latitude
                            longitude: geoposition.longitude
                        }
                    }
                }

                XFormText {
                    anchors {
                        fill: parent
                        margins: 10 * AppFramework.displayScaleFactor
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

                XFormText {
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
                        xform.popoverStackView.push({
                                                        item: geopointCapture,
                                                        properties: {
                                                            formElement: formElement,
                                                            editLatitude: geoposition.latitude,
                                                            editLongitude: geoposition.longitude,
                                                            editAltitude: geoposition.altitude,
                                                            editHorizontalAccuracy: geoposition.horizontalAccuracy,
                                                            editVerticalAccuracy: geoposition.verticalAccuracy,
                                                            showAltitude: supportsZ
                                                        }
                                                    });
                    }
                }
            }
        }

        XFormPositionSourceConnection {
            id: positionSourceConnection

            positionSourceManager: xform.positionSourceManager

            onNewPosition: {
                //console.log("Updating geopoint position:", JSON.stringify(position));
                updatePosition(position);
            }
        }

        Component {
            id: geopointCapture

            XFormGeopointCapture {
                positionSourceManager: positionSourceConnection.positionSourceManager
                map.plugin: previewMap.plugin

                onAccepted: {
                    var coordinate = {
                        latitude: editLatitude,
                        longitude: editLongitude,
                        altitude: editAltitude,
                        horizontalAccuracy: editHorizontalAccuracy,
                        verticalAccuracy: editVerticalAccuracy
                    };

                    if (editLocation && editLocation.address) {
                        var address = editLocation.address;

                        address.objectName = undefined;

                        coordinate.address = address;
                    }

                    console.log("edited coordinate:", JSON.stringify(coordinate, undefined, 2));

                    geoposition.fromObject(coordinate);

                    previewMap.zoomLevel = map.zoomLevel

                    changeReason = 1;
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculateButtonComponent

        Rectangle {
            color: "#80FFFFFF"
            radius: 5

            ImageButton {
                id: calculateButton

                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                source: "images/refresh_update.png"

                onClicked: {
                    if (positionSourceConnection.active) {
                        positionSourceConnection.release();
                    }
                    formData.expressionsList.triggerExpression(binding, "calculate");
                    setValue(calculatedValue.toString(), 3);
                }
            }

            ColorOverlay {
                anchors.fill: calculateButton
                source: calculateButton.image
                color: coordsRow.textColor
            }
        }
    }

    //--------------------------------------------------------------------------

    function updatePosition(position) {
        var accuracy = position.horizontalAccuracyValid ? position.horizontalAccuracy : Number.NaN;
        var withinThreshold = accuracyThreshold <= 0 || isNaN(accuracyThreshold) || isNaN(accuracy) ? true : accuracy <= accuracyThreshold;

        //console.log("withinThreshold", withinThreshold, JSON.stringify(position));

        if (geoposition.averaging) {
            if (withinThreshold) {
                geoposition.averagePosition(position);
            }

            averageTotalCount++;
        } else {
            if (withinThreshold) {
                positionSourceConnection.release();
            }

            geoposition.fromPosition(position);
        }

        previewMap.zoomLevel = previewZoomLevel;
        changeReason = 4;
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        formData.setValue(binding, geoposition.toObject());

        if (previewMap.zoomLevel < previewZoomLevel) {
            previewMap.zoomLevel = previewZoomLevel;
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

        //console.log("geopoint setValue:", JSON.stringify(value));

        positionSourceConnection.release();

        var doZoom = false;

        if (typeof value === "object") {
            geoposition.fromObject(value);

            doZoom = true;
        } else if (typeof value === "string") {
            var coordinate = JS.parseCoordinate(value);

            if (coordinate.isValid) {
                geoposition.fromObject(coordinate);

                doZoom = true;
            }
        } else {
            geoposition.clear();
        }

        if (doZoom) {
            previewMap.zoomLevel = previewZoomLevel;
        }
    }

    //--------------------------------------------------------------------------
}
