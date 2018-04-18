/* Copyright 2017 Esri
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

import QtQml 2.2
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtPositioning 5.8
import QtLocation 5.9

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Sql 1.0

//import "../Controls"

//------------------------------------------------------------------------------

Item {
    id: control

    readonly property bool clearVisible: text > ""
    property alias textField: textField
    property alias text: textField.text
    property alias geocodeTimer: geocodeTimer
    property alias geocodeModel: geocodeModel
    readonly property bool busy: geocodeModel.status === GeocodeModel.Loading
    property alias textChangedTimeout: geocodeTimer.interval
    property alias bounds: geocodeModel.bounds
    property alias limit: geocodeModel.limit

    property Component locationDelegate: locationDelegate
    property int minimumLocationDelegateHeight: 40 * AppFramework.displayScaleFactor
    property int viewLimit: 4
    property var referenceCoordinate: QtPositioning.coordinate()
    property var locale: Qt.locale()

    property var worldBounds: QtPositioning.rectangle(QtPositioning.coordinate(0,0), 360, 180)
    property Map map
    property string fontFamily: Qt.application.font.family

    property int currentIndex: -1
    property string locationPinImage: "images/location-pin.png"
    property string selectedPinImage: "images/selected-location-pin.png"
    property color locationPinTextColor: "white"
    property color selectedPinTextColor: "black"
    property url arrowImage: "images/direction_arrow.png"
    property url centerImage: "images/position-cursor.png"

    property bool searchEnabled: true
    property bool isOnline: Networking.isOnline
    readonly property bool canSearch: isOnline && searchEnabled
    property bool hasCoordinate
    property var parseOptions

    property bool debug: false

    //--------------------------------------------------------------------------

    property int searchMode: kSearchModeGlobalExtents
    readonly property int activeSearchMode: canSearch ? searchMode : kSearchModeCoordinates

    readonly property var kSearchModeImages: [
        "coordinates.png",
        "globe.png",
        "map.png",
    ]

    readonly property var kSearchModePlaceholderText: [
        qsTr("Map coordinate"),
        qsTr("Search location or map coordinate"),
        qsTr("Search location on map or coordinate"),
    ]

    readonly property int kSearchModeCoordinates: 0
    readonly property int kSearchModeGlobalExtents: 1
    readonly property int kSearchModeMapExtents: 2

    //--------------------------------------------------------------------------

    signal locationClicked(int index, Location location, real distance)
    signal locationDoubleClicked(int index, Location location, real distance)
    signal locationPressAndHold(int index, Location location, real distance)
    signal locationIndicatorClicked(int index, Location location, real distance)

    signal cleared()
    signal mapCoordinate(var coordinateInfo)

    //--------------------------------------------------------------------------

    implicitHeight: layout.height
    height: layout.height

    //--------------------------------------------------------------------------

    Connections {
        target: map

        onZoomLevelChanged: {
            //geocodeTimer.restart();
        }

        onCenterChanged: {
            //geocodeTimer.restart();
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        width: parent.width

        TextField {
            id: textField

            Layout.fillWidth: true

            placeholderText: kSearchModePlaceholderText[activeSearchMode]

            style: TextFieldStyle {
                id: textFieldStyle

                renderType: Text.QtRendering
                //textColor: "black"
                placeholderTextColor: "lightgrey"
                font {
                    pointSize: 20
                    bold: false
                    family: fontFamily
                }
            }

            //--------------------------------------------------------------------------

            Component.onCompleted: {
                if (clearVisible) {
                    clearButtonLoader.active = true;
                }

                __panel.leftMargin = searchButton.width + searchButton.anchors.margins * 1.5;
            }

            //--------------------------------------------------------------------------

            //            Rectangle {
            //                anchors.fill: searchButton
            //                radius: 2 * AppFramework.displayScaleFactor
            //                color: "#00b2ff"
            //                visible: useMapBounds
            //            }

            StyledImageButton {
                id: searchButton

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: 4 * AppFramework.displayScaleFactor
                }

                visible: true
                width: height
                checkable: true
                checkedColor: "grey"
                uncheckedColor: "grey"
                checked: true
                //visible: canSearch
                //checked: useMapBounds
                //width: canSearch ? height : 0
                source: "images/%1".arg(kSearchModeImages[activeSearchMode])

                onClicked: {
                    searchTypePopup.open();
                }

                onPressAndHold: {
                    if (debug) {
                        isOnline = !isOnline;
                    }
                }

                ActionPopup {
                    id: searchTypePopup

                    x: searchButton.width
                    y: searchButton.height / 2

                    ColumnLayout {

                        spacing: searchTypePopup.padding

                        Text {
                            Layout.fillWidth: true

                            visible: !canSearch

                            text: qsTr("Only map coordinate input available when offline")
                            font.family: control.fontFamily
                        }

                        ActionButton {
                            Layout.fillWidth: true

                            visible: canSearch
                            text: qsTr("Search anywhere in the world")
                            iconSource: "images/globe.png"
                            font.family: control.fontFamily
                            checkable: true
                            checked: activeSearchMode === kSearchModeGlobalExtents

                            onClicked: {
                                searchTypePopup.setSearchMode(kSearchModeGlobalExtents);
                            }
                        }

                        ActionButton {
                            Layout.fillWidth: true

                            visible: canSearch
                            text: qsTr("Search within the visible map extents")
                            iconSource: "images/map.png"
                            font.family: control.fontFamily
                            checkable: true
                            checked: activeSearchMode === kSearchModeMapExtents

                            onClicked: {
                                searchTypePopup.setSearchMode(kSearchModeMapExtents);
                            }
                        }

                        ActionButton {
                            Layout.fillWidth: true

                            visible: canSearch
                            text: qsTr("Map coordinate input only")
                            iconSource: "images/coordinates.png"
                            font.family: control.fontFamily
                            checkable: true
                            checked: activeSearchMode === kSearchModeCoordinates

                            onClicked: {
                                searchTypePopup.setSearchMode(kSearchModeCoordinates);
                            }
                        }
                    }

                    function setSearchMode(mode) {
                        searchMode = mode;

                        if (activeSearchMode > kSearchModeCoordinates) {
                            geocodeModel.startSearch(text);
                        }

                        close();
                    }
                }
            }

            //--------------------------------------------------------------------------

            onLengthChanged: {
                if (length > 0) {
                    clearButtonLoader.active = true;
                }
            }

            onTextChanged: {
                if (canSearch) {
                    geocodeTimer.restart();
                }
            }

            onEditingFinished: {
                hasCoordinate = parseCoordinate(text.trim());
                if (!hasCoordinate) {
                    if (canSearch && activeSearchMode > kSearchModeCoordinates) {
                        geocodeModel.startSearch(text);
                    }
                }
            }

            //--------------------------------------------------------------------------

            Loader {
                id: clearButtonLoader

                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 2 * AppFramework.displayScaleFactor
                }

                visible: clearVisible
                width: height
                active: false

                sourceComponent: StyledImageButton {
                    source: "images/clear.png"

                    onClicked: {
                        clear();
                    }

                    BusyIndicator {
                        anchors.fill: parent
                        running: busy
                    }
                }

                onVisibleChanged: {
                    if (parent.__panel) {
                        parent.__panel.rightMargin = visible ? clearButtonLoader.width + clearButtonLoader.anchors.margins * 1.5 : 0;
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(geocodeModel.count, viewLimit) * (minimumLocationDelegateHeight + resultsView.spacing)
            //Layout.leftMargin: searchButton.width + 2 * AppFramework.displayScaleFactor
            Layout.topMargin: -parent.spacing

            visible: geocodeModel.count > 0

            radius: scrollView.anchors.margins / 2
            border {
                width: 1
                color: "#20000000"
            }

            ScrollView {
                id: scrollView
                anchors {
                    fill: parent
                    margins: 3 * AppFramework.displayScaleFactor
                }

                ListView {
                    id: resultsView

                    model: geocodeModel
                    spacing: 2 * AppFramework.displayScaleFactor
                    delegate: locationDelegate
                    clip: true
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: locationDelegate

        Rectangle {
            id: locationItem

            property Location location: index >= 0 ? ListView.view.model.get(index) : null
            property double distance: location ? referenceCoordinate.distanceTo(location.coordinate) : 0
            property double azimuth: location ? referenceCoordinate.azimuthTo(location.coordinate) : 0
            readonly property bool selected: currentIndex === index

            width: ListView.view.width
            height: locationLayout.height + locationLayout.anchors.margins * 2
            color: mouseArea.containsMouse ? "#F0F0F0" : "white"
            radius: 2 * AppFramework.displayScaleFactor


            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    locationClicked(index, location, distance);
                }

                onPressAndHold: {
                    locationPressAndHold(index, location, distance);
                }

                onDoubleClicked: {
                    locationDoubleClicked(index, location, distance);
                }
            }

            RowLayout {
                id: locationLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 2 * AppFramework.displayScaleFactor
                }

                Item {
                    Layout.preferredHeight: minimumLocationDelegateHeight
                    Layout.preferredWidth: Layout.preferredHeight

                    Image {
                        id: pinImage

                        anchors {
                            fill: parent
                        }

                        source: selected ? selectedPinImage : locationPinImage
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                    }

                    Item {
                        anchors {
                            centerIn: parent
                        }

                        width: pinImage.width / 2
                        height: width

                        Text {
                            id: indexText

                            anchors {
                                fill: parent
                                margins: 2 * AppFramework.displayScaleFactor
                            }

                            text: "%1".arg(index + 1)

                            color: locationItem.selected ? selectedPinTextColor : locationPinTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            fontSizeMode: Text.HorizontalFit

                            minimumPointSize: 10
                            font {
                                pointSize: 13
                                bold: selected
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumHeight: minimumLocationDelegateHeight

                    text: location ? location.address.text : ""
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    fontSizeMode: Text.HorizontalFit
                    maximumLineCount: 2
                    minimumPointSize: 11
                    font {
                        pointSize: 13
                        family: fontFamily
                        bold: selected
                    }
                }

                Text {
                    visible: Math.round(distance) > 0
                    text: displayDistance(distance)

                    font {
                        pointSize: 12
                        family: fontFamily
                    }
                }

                Image {
                    Layout.preferredHeight: minimumLocationDelegateHeight * 0.75
                    Layout.preferredWidth: Layout.preferredHeight

                    //opacity: Math.round(distance) > 1 ? 1 : 0
                    fillMode: Image.PreserveAspectFit
                    rotation: azimuth
                    source: distance > 0 ? arrowImage: centerImage

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            locationIndicatorClicked(index, location, distance);
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 1
                color: "#10000000"
            }
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        id: geocodeTimer

        interval: 1000
        repeat: false

        onTriggered: {
            var coordInfo = Coordinate.parse(textField.text, parseOptions);
            hasCoordinate = coordInfo.coordinateValid;
            if (hasCoordinate) {
                geocodeModel.reset();
            } else if (canSearch && activeSearchMode > kSearchModeCoordinates){
                geocodeModel.startSearch(textField.text);
            }
        }
    }

    GeocodeModel {
        id: geocodeModel

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
            console.log("locationsChanged:", count);
            currentIndex = -1;
        }

        function startSearch(text) {
            cancel();

            var radius = 0;

            if (activeSearchMode == kSearchModeMapExtents) {
                var rect = QtPositioning.shapeToRectangle(map.visibleRegion);
                radius = rect.center.distanceTo(rect.topLeft);
            }

            bounds = QtPositioning.circle(map.center, radius); //worldBounds

            if (text.trim() > "" && text.substr(0, 1) !== '@') {
                query = text.trim();
                update();
            }
        }

        function reverseGeocode(coord) {
            cancel();
            query = coord;
            update();
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        geocodeTimer.stop();
        geocodeModel.reset();
        text = "";
        currentIndex = -1;
        cleared();
    }

    //--------------------------------------------------------------------------

    function reset() {
        geocodeTimer.stop();
        geocodeModel.reset();
        currentIndex = -1;
    }

    //--------------------------------------------------------------------------

    function getLocation(index) {
        var location = searchField.geocodeModel.get(index);

        console.log("Location:", JSON.stringify(location, undefined, 2));

        return location;
    }

    //--------------------------------------------------------------------------

    function showLocation(index, select) {
        if (select) {
            currentIndex = index;
        }

        if (index >= 0) {
            resultsView.positionViewAtIndex(index, ListView.Center);
        }
    }

    //--------------------------------------------------------------------------

    function displayDistance(distance) {
        switch (locale.measurementSystem) {
        case Locale.ImperialUSSystem:
        case Locale.ImperialUKSystem:
            var distanceFt = distance * 3.28084;
            if (distanceFt < 1000) {
                return "%1 ft".arg(Math.round(distanceFt).toLocaleString(locale, "f", 0))
            } else {
                var distanceMiles = distance * 0.000621371;
                return "%1 mi".arg(Math.round(distanceMiles).toLocaleString(locale, "f", distanceMiles < 10 ? 1 : 0))
            }

        default:
            if (distance < 1000) {
                return "%1 m".arg(Math.round(distance).toLocaleString(locale, "f", 0))
            } else {
                var distanceKm = distance / 1000;
                return "%1 km".arg(Math.round(distanceKm).toLocaleString(locale, "f", distanceKm < 10 ? 1 : 0))
            }
        }
    }

    //--------------------------------------------------------------------------

    function parseCoordinate(text) {
        if (!(text > "")) {
            return false;
        }

        var coordInfo = Coordinate.parse(text, parseOptions);
        if (!coordInfo.coordinate) {
            return false;
        }

        mapCoordinate(coordInfo);

        return true;
    }

    //--------------------------------------------------------------------------
}
