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
import QtQuick.Layouts 1.1
import QtLocation 5.9
import QtPositioning 5.8
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Networking 1.0

import "XForm.js" as JS
import "MapControls"

Rectangle {
    id: geopointCapture
    
    property var formElement

    property real editLatitude
    property real editLongitude
    property real editAltitude
    property real editHorizontalAccuracy: Number.NaN
    property real editVerticalAccuracy: Number.NaN
    property var editLocation
    property bool showAltitude: false

    property alias map: map
    property XFormMapSettings mapSettings: xform.mapSettings
    property alias positionSourceManager: positionSourceConnection.positionSourceManager

    property bool initializing: true
    property bool editingCoords: false

    readonly property bool isEditValid: editLatitude != 0 && editLongitude != 0 &&
                                        !isNaN(editLatitude) && !isNaN(editLongitude)

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: accentColor//AppFramework.alphaColor(accentColor, 0.9)
    property real coordinatePointSize: 12
    property real locationZoomLevel: 16

    property int buttonHeight: 35 * AppFramework.displayScaleFactor

    property bool isOnline: Networking.isOnline
    property bool reverseGeocodeEnabled: true
    readonly property bool canReverseGeocode: isOnline && reverseGeocodeEnabled


    property var mgrsOptions: {
        "precision": 10,
        "spaces": true
    }

    property var parseOptions: {
        "mgrs": {
            "spaces": true
        }
    }

    property bool enableGeocoder: app.settings.boolValue("enableGeocoder", false);

    //--------------------------------------------------------------------------

    signal accepted
    signal rejected

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        map.zoomLevel = previewMap.zoomLevel;
        //                    console.log(zoomLevel, JSON.stringify(supportedMapTypes, undefined, 2));

        if (isEditValid) {
            //            geopointMarker.coordinate.latitude = geopointCapture.editLatitude;
            //            geopointMarker.coordinate.longitude = geopointCapture.editLongitude;

            console.log("edit:", editLatitude, editLongitude, editAltitude, editHorizontalAccuracy, editVerticalAccuracy);

            map.center.latitude = editLatitude;
            map.center.longitude = editLongitude;
            map.centerHorizontalAccuracy = editHorizontalAccuracy;
            map.centerVerticalAccuracy = editVerticalAccuracy;

            if (map.zoomLevel < map.positionZoomLevel) {
                map.zoomLevel = map.positionZoomLevel;
            }
        } else {
            map.positionMode = map.positionModeAutopan;
            positionSourceConnection.activate();
        }

        map.addMapTypeMenuItems(mapMenu);

        mapSettings.selectMapType(map);

        initializing = false;
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: header

        anchors {
            fill: headerLayout
            margins: -headerLayout.anchors.margins
        }

        color: barBackgroundColor //"#80000000"
    }

    ColumnLayout {
        id: headerLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: 0 //5 * AppFramework.displayScaleFactor

        ColumnLayout {
            id: columnLayout

            Layout.fillWidth: true
            Layout.margins: 2 * AppFramework.displayScaleFactor

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                ImageButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    source: "images/back.png"

                    ColorOverlay {
                        anchors.fill: parent
                        source: parent.image
                        color: xform.style.titleTextColor
                    }

                    onClicked: {
                        rejected();
                        geopointCapture.parent.pop();
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

                    MouseArea {
                        anchors.fill: parent

                        onPressAndHold: {
                            enableGeocoder = !enableGeocoder;
                            app.settings.setValue("enableGeocoder", enableGeocoder, false);
                        }
                    }
                }

                XFormMenuButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

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


        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor
            //Layout.preferredHeight: 30 * AppFramework.displayScaleFactor\

            visible: enableGeocoder

            spacing: 5 * AppFramework.displayScaleFactor

            LocationSearchField {
                id: searchField

                Layout.fillWidth: true

                parseOptions: geopointCapture.parseOptions
                map: geopointCapture.map
                referenceCoordinate: map.center
                textField.textColor: xform.style.inputTextColor
                fontFamily: app.fontFamily
                centerImage: geopointMarker.image.source

                onMapCoordinate: {
                    if (!coordinateInfo.coordinate.isValid) {
                        return;
                    }

                    console.log("coordInfo:", JSON.stringify(coordinateInfo, undefined, 2));

                    panTo(coordinateInfo.coordinate);
                }

                onLocationClicked: {
                    zoomToLocation(location);
                    if (currentIndex == index) {
                        selectLocation(location);
                    } else {
                        currentIndex = index;
                    }
                }

                onLocationDoubleClicked: {
                    zoomToLocation(location);
                    selectLocation(location);
                }

                onLocationPressAndHold: {
                    zoomToLocation(location);
                    selectLocation(location);
                }

                onLocationIndicatorClicked: {
                    zoomToLocation(location);
                    selectLocation(location);
                }

                geocodeModel.onLocationsChanged: {
                    if (!geocodeModel.count && !searchField.hasCoordinate) {
                        textField.textColor = xform.style.inputErrorTextColor;
                        errorText.text = qsTr("No locations found");
                    } else {
                        textField.textColor = xform.style.inputTextColor;
                        errorText.text = "";
                    }
                }

                onTextChanged: {
                    textField.textColor = xform.style.inputTextColor;
                    errorText.text  = "";
                }
            }

            LocationPasteButton {
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: searchField.textField.height
                Layout.preferredWidth: Layout.preferredHeight

                field: searchField
                parseOptions: searchField.parseOptions
            }
        }

        Text {
            id: errorText

            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor

            visible: text > "" && !searchField.busy
            wrapMode: Text.WrapAnywhere
            horizontalAlignment: Text.AlignHCenter

            color: barTextColor
            font {
                bold: true
            }
        }
    }

    //--------------------------------------------------------------------------

    Map {
        id: mapCalc

        anchors.fill: map
        plugin: Plugin { name: "itemsoverlay" }
        gesture.enabled: false
        color: 'transparent'
    }

    //--------------------------------------------------------------------------
    
    XFormMap {
        id: map

        property real positionZoomLevel: xform.mapSettings.positionZoomLevel
        property real centerHorizontalAccuracy: Number.NaN
        property real centerVerticalAccuracy: Number.NaN

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: footer.top
        }

        positionSourceConnection: positionSourceConnection
        gesture.enabled: !editingCoords
        mapSettings: parent.mapSettings

        //        center {
        //            latitude: geopointCapture.editLatitude
        //            longitude: geopointCapture.editLongitude
        //        }

        onCenterChanged: {
            if (!initializing) {
                editLatitude = map.center.latitude;
                editLongitude = map.center.longitude;
                editHorizontalAccuracy = map.centerHorizontalAccuracy;
                if (!editingCoords) {
                    editAltitude = Number.NaN;
                }
                editVerticalAccuracy = map.centerVerticalAccuracy;
            }
        }

        gesture.onPanStarted: {
            editLocation = undefined;
        }

        //        Behavior on zoomLevel {
        //            NumberAnimation {
        //                duration: 250
        //            }
        //        }

        function clearAccuracy() {
            centerHorizontalAccuracy = Number.NaN;
            centerVerticalAccuracy = Number.NaN;
        }

        MouseArea {
            anchors {
                fill: parent
            }

            onPressed: {
                map.clearAccuracy();
            }

            onClicked: {
                panTo(map.toCoordinate(Qt.point(mouseX, mouseY)));
            }

            onWheel: {
                wheel.accepted = false;
                map.clearAccuracy();
            }

            onPressAndHold: {
                reverseGeocode(map.toCoordinate(Qt.point(mouseX, mouseY)));
            }
        }

        MapItemView {
            id: geocodeModelView

            //autoFitViewport: true
            model: searchField.geocodeModel
            delegate: LocationMarker {
                selected: searchField.currentIndex === index
                z: selected ? searchField.geocodeModel.count : index
                visible: !selected

                onClicked: {
                    searchField.showLocation(index, true);
                    var location = searchField.getLocation(index);
                    zoomToLocation(location);
                }
            }
        }


        MapCircle {
            visible: isFinite(map.centerHorizontalAccuracy) && map.centerHorizontalAccuracy > 0

            radius: map.centerHorizontalAccuracy
            center: geopointMarker.coordinate
            color: "#4000B2FF"
            border {
                width: 1
                color: "#8000B2FF"
            }

            z: 1000
        }

        XFormMapMarker {
            id: geopointMarker

            zoomLevel: 0 //16

            coordinate {
                latitude: geopointCapture.editLatitude
                longitude: geopointCapture.editLongitude
            }

            z: 1001
        }
    }

    //--------------------------------------------------------------------------
/* Requires AppStudio 2.2
    Map {
        id: mapOverlay
        anchors.fill: map
        plugin: Plugin { name: "itemsoverlay" }
        gesture.enabled: false
        center: map.center
        color: 'transparent'
        minimumFieldOfView: map.minimumFieldOfView
        maximumFieldOfView: map.maximumFieldOfView
        minimumTilt: map.minimumTilt
        maximumTilt: map.maximumTilt
        minimumZoomLevel: map.minimumZoomLevel
        maximumZoomLevel: map.maximumZoomLevel
        zoomLevel: map.zoomLevel
        tilt: map.tilt;
        bearing: map.bearing
        fieldOfView: map.fieldOfView
        z: map.z + 1

        MapCircle {
            visible: isFinite(map.centerHorizontalAccuracy) && map.centerHorizontalAccuracy > 0

            radius: map.centerHorizontalAccuracy
            center: geopointMarker.coordinate
            color: "#4000B2FF"
            border {
                width: 1
                color: "#8000B2FF"
            }
        }

        XFormMapMarker {
            id: geopointMarker

            zoomLevel: 0 //16

            coordinate {
                latitude: geopointCapture.editLatitude
                longitude: geopointCapture.editLongitude
            }
        }
    }
*/

    //--------------------------------------------------------------------------

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

            onPressAndHold: {
                reverseGeocode(map.center);
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
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        /*
        XFormText {
            text: map.zoomLevel
        }
        */

        RowLayout {
            visible: !editingCoords

            ColumnLayout {
                spacing: 2 * AppFramework.displayScaleFactor

                XFormText {
                    id: addressText

                    Layout.fillWidth: true

                    visible: text > ""
                    text: editLocation ? editLocation.address.text : ""
                    font {
                        pointSize: coordinatePointSize
                    }
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                Rectangle {
                    Layout.fillWidth: true

                    visible: addressText.visible
                    height: 1
                    color: barTextColor
                    opacity: 0.5
                }

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

            /*
            Column {
                id: speedColumn

                visible: positionSourceConnection.active
                spacing: 2

                property Position position: positionSourceConnection.positionSourceManager.positionSource.position

                XFormText {
                    visible: speedColumn.position.speedValid
                    text: qsTr("%1 km/h").arg(Math.round(speedColumn.position.speed))
                    color: barTextColor
                    font {
                        pointSize: coordinatePointSize
                    }
                }

                XFormText {
                    visible: speedColumn.position.verticalSpeedValid
                    text: qsTr("↕ %1 m/s").arg(Math.round(speedColumn.position.verticalSpeed))
                    color: barTextColor
                    font {
                        pointSize: coordinatePointSize
                    }
                }
            }
            */
        }

        ColumnLayout {
            Layout.fillWidth: true

            //width: 200 * AppFramework.displayScaleFactor
            visible: editingCoords
            spacing: 5 * AppFramework.displayScaleFactor

            XFormText {
                Layout.fillWidth: true

                text: qsTr("Latitude")
                color: barTextColor
                font {
                    pointSize: 13
                }
            }

            XFormTextField {
                Layout.fillWidth: true

                //text: editLatitude.toString()
                text: Number(editLatitude).toLocaleString(xform.locale, "f", 7)
                inputMethodHints: Qt.platform.os === "ios" ? Qt.ImhPreferNumbers : Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {
                    locale: xform.locale.name
                    bottom: -90
                    top: 90
                    notation: DoubleValidator.StandardNotation
                }

                onEditingFinished: {
                    editLatitude = Number.fromLocaleString(xform.locale, text);
                    editHorizontalAccuracy = Number.NaN;
                    map.zoomLevel = Math.max(previewZoomLevel, map.zoomLevel);
                    map.center.latitude = editLatitude;
                    map.clearAccuracy();
                }

                onAction: {
                    text = "";
                    editingFinished();
                }
            }

            XFormText {
                Layout.fillWidth: true

                text: qsTr("Longitude")
                color: barTextColor
                font {
                    pointSize: 13
                }
            }

            XFormTextField {
                Layout.fillWidth: true

                //text: editLongitude.toString()
                text: Number(editLongitude).toLocaleString(xform.locale, "f", 7)
                inputMethodHints: Qt.platform.os === "ios" ? Qt.ImhPreferNumbers : Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {
                    locale: xform.locale.name
                    bottom: -180
                    top: 180
                    notation: DoubleValidator.StandardNotation
                }

                onEditingFinished: {
                    editLongitude = Number.fromLocaleString(xform.locale, text);
                    editHorizontalAccuracy = Number.NaN;
                    map.zoomLevel = Math.max(previewZoomLevel, map.zoomLevel);
                    map.center.longitude = editLongitude;
                    map.clearAccuracy();
                }

                onAction: {
                    text = "";
                    editingFinished();
                }
            }

            XFormText {
                Layout.fillWidth: true

                visible: showAltitude
                text: qsTr("Altitude")
                color: barTextColor
                font {
                    pointSize: 13
                }
            }

            XFormTextField {
                Layout.fillWidth: true

                visible: showAltitude
                text: isFinite(editAltitude) ? Number(editAltitude).toLocaleString(xform.locale, "f", 7) : ""
                inputMethodHints: Qt.platform.os === "ios" ? Qt.ImhPreferNumbers : Qt.ImhFormattedNumbersOnly

                onEditingFinished: {
                    if (length > 0) {
                        editAltitude = Number.fromLocaleString(xform.locale, text);
                    } else {
                        editAltitude = Number.NaN;
                    }
                }

                onAction: {
                    text = "";
                    editingFinished();
                }
            }
        }

        ImageButton {
            Layout.fillHeight: true
            Layout.preferredHeight: buttonHeight
            Layout.preferredWidth: buttonHeight
            Layout.alignment: Qt.AlignRight

            source: "images/ok_button.png"
            enabled: isEditValid
            visible: isEditValid

            ColorOverlay {
                anchors.fill: parent
                source: parent.image
                color: xform.style.titleTextColor
            }

            onClicked: {
                forceActiveFocus();

                if (editingCoords) {
                    console.log("edit", editLatitude, editLongitude, editAltitude, editHorizontalAccuracy, editVerticalAccuracy);

                    initializing = true;
                    editHorizontalAccuracy = Number.NaN;
                    editVerticalAccuracy = Number.NaN;

                    map.center.latitude = editLatitude;
                    map.center.longitude = editLongitude;
                    map.centerHorizontalAccuracy = editHorizontalAccuracy;
                    map.centerVerticalAccuracy = editVerticalAccuracy;

                    editingCoords = false;
                    initializing = false;
                    Qt.inputMethod.hide();
                } else {
                    positionSourceConnection.active = false;
                    accepted();
                    geopointCapture.parent.pop();
                }
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
                var wasValid = isEditValid
                //                editLatitude = position.coordinate.latitude;
                //                editLongitude = position.coordinate.longitude;

                if (map.positionMode > 0) {
                    if (position.horizontalAccuracyValid) {
                        map.centerHorizontalAccuracy = position.horizontalAccuracy;
                    } else {
                        map.centerHorizontalAccuracy = Number.NaN;
                    }

                    if (position.verticalAccuracyValid) {
                        map.centerVerticalAccuracy = position.verticalAccuracy;
                    } else {
                        map.centerVerticalAccuracy = Number.NaN;
                    }
                }

                if (isEditValid && wasValid != isEditValid) {
                    map.zoomLevel = previewZoomLevel;
                    map.center = position.coordinate;
                }

                if (map.zoomLevel < map.positionZoomLevel && map.positionMode == map.positionModeAutopan) {
                    map.zoomLevel = map.positionZoomLevel;
                }
            }
            
            //            if (position.altitudeValid) {
            //                editAltitude = position.coordinate.altitude;
            //            }
        }
    }

    //--------------------------------------------------------------------------

    function selectLocation(location) {

        if (!location.coordinate.isValid) {
            return;
        }

        setEditLocation(location);

        searchField.text = location.address.text;

        searchField.reset();
    }

    //--------------------------------------------------------------------------

    function panTo(coord) {
        var wasValid = isEditValid;

        editLatitude = coord.latitude;
        editLongitude = coord.longitude;
        editHorizontalAccuracy = Number.NaN;
        if (!editingCoords) {
            editAltitude = Number.NaN;
        }
        editVerticalAccuracy = Number.NaN;
        map.clearAccuracy();

        if (isEditValid && (wasValid != isEditValid || map.zoomLevel < map.positionZoomLevel)) {
            if (map.zoomLevel < map.positionZoomLevel) {
                map.zoomLevel = map.positionZoomLevel;
            }
        }

        map.center = coord;
    }

    //--------------------------------------------------------------------------

    function zoomToLocation(location) {
        console.log("location:", JSON.stringify(location, undefined, 2));

        if (location.boundingBox.isValid) {
            mapCalc.visibleRegion = location.boundingBox;
            map.zoomLevel = mapCalc.zoomLevel;
        } else {
            if (map.zoomLevel < locationZoomLevel) {
                map.zoomLevel = locationZoomLevel;
            }
        }

        editHorizontalAccuracy = Number.NaN;
        editVerticalAccuracy = Number.NaN;
        map.clearAccuracy();

        var coord = location.coordinate;

        map.center = coord;

        editLatitude = coord.latitude;
        editLongitude = coord.longitude;
        if (!editingCoords) {
            editAltitude = Number.NaN;
        }

        setEditLocation(location);
    }

    //--------------------------------------------------------------------------

    function setEditLocation(location) {
        editLocation = JSON.parse(JSON.stringify(location));
    }

    //--------------------------------------------------------------------------

    function reverseGeocode(coord) {
        if (!canReverseGeocode) {
            console.warn("Reverse geocoding not available");
            return;
        }

        panTo(coord);
        //searchField.geocodeModel.reverseGeocode(coord);
        editLocation = false;
        reverseGeocodeModel.query = coord;
        reverseGeocodeModel.update();
    }

    //--------------------------------------------------------------------------

    GeocodeModel {
        id: reverseGeocodeModel

        autoUpdate: false
        limit: -1

        plugin: Plugin {
            preferred: ["AppStudio"]

            PluginParameter {
                name: "ArcGIS.debug"
                value: false
            }
        }

        onLocationsChanged: {
            console.log("reverseGeocode locationsChanged:", count);
            if (count > 0) {
                var location = get(0);
                console.log("reverseGeocode:", query, JSON.stringify(location, undefined, 2));
                if (typeof editLocation === "boolean") {
                    setEditLocation(location);
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
