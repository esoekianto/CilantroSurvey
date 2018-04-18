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

import ArcGIS.AppFramework 1.0

import "../XForms"
import "SurveyHelper.js" as Helper
import "../Models"

Item {
    id: mapView

    property XFormsDatabase xformsDatabase: app.surveysModel
    property bool debug: false
    property bool showDelete: true
    property var surveysModel: filteredSurveysModel.visualModel //xformsDatabase
    property XFormSchema schema
    property XFormMapSettings mapSettings

    property alias map: map
    property var extent

    signal clicked(var survey)

    property real detailedZoomLevel: 13
    property real labelsZoomLevel: 15
    property color labelTextColor: "black"
    property color labelStyleColor: "white"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("SurveysMapView.onCompleted");

        map.mapSettings.selectMapType(map);

        if (updateExtent()) {
            map.zoomToRectangle(extent, map.mapSettings.previewZoomLevel);
        }
        else {
            map.zoomToDefault();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: filteredSurveysModel

        onUpdating: {
            console.log("Surveys updating");
        }

        onUpdated: {
            refresh();
            console.log("Surveys updated");
        }
    }

    //--------------------------------------------------------------------------

    XFormMap {
        id: map

        anchors {
            fill: parent
        }

        mapSettings: mapView.mapSettings

        positionSourceConnection: XFormPositionSourceConnection {
            positionSourceManager: app.positionSourceManager
        }

        plugin: XFormMapPlugin {
            settings: map.mapSettings
            offline: !AppFramework.network.isOnline
        }

        MapItemView {
            model: map.zoomLevel < detailedZoomLevel ? clustersModel : null
            delegate: geopointClusterComponent
        }

        MapItemView {
            model: map.zoomLevel >= labelsZoomLevel ? surveysModel : null
            delegate: geopointLabelComponent
        }

        MapItemView {
            model: map.zoomLevel >= detailedZoomLevel ? surveysModel : null
            delegate: geopointMarkerComponent
        }

        onPositionModeChanged: {
            if (positionMode > positionModeOff) {
                zoomLevel = mapSettings.defaultPreviewZoomLevel;
            }
        }

        onZoomLevelChanged: {
            if (zoomLevel < detailedZoomLevel) {
                clustersModel.update();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointClusterComponent

        MapQuickItem {
            id: mapItem

            anchorPoint {
                x: mapMarker.width/2
                y: mapMarker.height/2
            }

            coordinate: QtPositioning.coordinate(cy, cx)
            sourceItem: Rectangle {
                id: mapMarker

                property int size: Math.max(countText.paintedHeight + 8 * AppFramework.displayScaleFactor, countText.paintedWidth + 16 * AppFramework.displayScaleFactor)
                height: size
                width: size
                color: actionColor
                border {
                    color: "white"
                    width: 1
                }
                radius: height / 2

                Text {
                    id: countText
                    anchors.centerIn: parent

                    text: count
                    color: "white"
                }

                MouseArea {
                    anchors {
                        fill: parent
                    }

                    onClicked: {
                        var clusterExtent = QtPositioning.rectangle(QtPositioning.coordinate(yMax, xMin), QtPositioning.coordinate(yMin, xMax));
                        map.zoomToRectangle(clusterExtent, labelsZoomLevel);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointMarkerComponent

        MapQuickItem {
            id: mapItem

            property var rowIndex: index
            property var rowData: surveysModel.getSurvey(rowIndex);
            property int rowStatus: rowData ? rowData.status : 0

            anchorPoint {
                x: mapMarker.width/2
                y: mapMarker.height
            }

            visible: false
            sourceItem: Image {
                id: mapMarker

                width: 40 * AppFramework.displayScaleFactor
                height: width
                source: "../XForms/images/pin-%1.png".arg(rowStatus)
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors {
                        fill: parent
                    }

                    onClicked: {
                        mapView.clicked(rowData);
                    }
                }
            }

            Component.onCompleted: {
                var coordinate = getCoordinate(rowData);
                if (coordinate) {
                    mapItem.coordinate = coordinate;
                    mapItem.visible = mapItem.coordinate.isValid;
                    if (!mapItem.visible) {
                        console.error("Map geometry error:", JSON.stringify(geometry, undefined, 2));
                    }

                    // console.log("mapItem:", snippet, mapItem.coordinate);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointLabelComponent

        MapQuickItem {
            id: mapItem

            property var rowIndex: index
            property var rowData: surveysModel.getSurvey(rowIndex);

            anchorPoint {
                x: mapText.width/2
                y: 0
            }

            visible: false
            sourceItem: Text {
                id: mapText

                width: 100 * AppFramework.displayScaleFactor
                text: rowData ? rowData.snippet || "" : ""
                color: labelTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: app.fontFamily
                    pointSize: 11
                    bold: true
                }
                //styleColor: labelStyleColor
                //style: Text.Outline

                Rectangle {
                    anchors {
                        centerIn: parent
                    }

                    width: parent.paintedWidth + parent.paintedHeight / 2
                    height: parent.paintedHeight + 6
                    radius: parent.paintedHeight / 2
                    border {
                        color: "lightgrey"
                        width: 1
                    }

                    opacity: 0.5
                    z: parent.z - 1
                }

                MouseArea {
                    anchors {
                        fill: parent
                    }

                    onClicked: {
                        mapView.clicked(rowData);
                    }
                }
            }

            Component.onCompleted: {
                var coordinate = getCoordinate(rowData);
                if (coordinate) {
                    mapItem.coordinate = coordinate;
                    mapItem.visible = mapItem.coordinate.isValid;
                    if (!mapItem.visible) {
                        console.error("Map geometry error:", JSON.stringify(geometry, undefined, 2));
                    }

                    // console.log("mapItem:", snippet, mapItem.coordinate);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function getCoordinate(rowData) {
        if (!rowData) {
            return QtPositioning.coordinate();
        }

        var coordinate;

        if (rowData && rowData.data && schema.schema.geometryFieldName) {
            var geometry = rowData.data[schema.instanceName][schema.schema.geometryFieldName];

            if (geometry && geometry.x && geometry.y) {
                coordinate = QtPositioning.coordinate(geometry.y, geometry.x);
            }
        }

        return coordinate;
    }

    //--------------------------------------------------------------------------

    function updateExtent() {

        var xMin;
        var yMin;
        var xMax;
        var yMax;

        if (surveysModel.count <= 0) {
            return false;
        }

        for (var i = 0; i < surveysModel.count; i++) {
            var coordinate = getCoordinate(surveysModel.getSurvey(i));
            if (coordinate && coordinate.isValid) {
                if (i) {
                    xMin = Math.min(xMin, coordinate.longitude);
                    xMax = Math.max(xMax, coordinate.longitude);
                    yMin = Math.min(yMin, coordinate.latitude);
                    yMax = Math.max(yMax, coordinate.latitude);
                } else {
                    xMin = coordinate.longitude;
                    yMin = coordinate.latitude;
                    xMax = xMin;
                    yMax = yMin;
                }
            }
        }

        extent = QtPositioning.rectangle(QtPositioning.coordinate(yMax, xMin), QtPositioning.coordinate(yMin, xMax));

        console.log("Surveys extent:", extent);

        return true;
    }

    //--------------------------------------------------------------------------

    ClustersModel {
        id: clustersModel

        function update() {
            if (Math.round(map.zoomLevel) == level) {
                return;
            }

            initialize(Math.round(map.zoomLevel));

            for (var i = 0; i < surveysModel.count; i++) {
                addPoint(getCoordinate(surveysModel.getSurvey(i)));
            }

            finalize();
        }
    }

    //--------------------------------------------------------------------------

    function refresh() {
        console.log("Refreshing map view");
        updateExtent();
        clustersModel.reset();
        if (map.zoomLevel < detailedZoomLevel) {
            clustersModel.update();
        }
    }

    //--------------------------------------------------------------------------

    //    MapCircle {
    //        id: mapCircle

    //        color: "red"
    //        radius: 10
    //        border {
    //            color: "#e5e6e7"
    //            width: 1
    //        }

    //    }
}
