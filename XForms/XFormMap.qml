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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtLocation 5.3
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Map {
    id: map

    property XFormPositionSourceConnection positionSourceConnection
    property int positionMode

    readonly property int positionModeOff: -1
    readonly property int positionModeOn: 0
    readonly property int positionModeAutopan: 1

    property alias positionIndicator: positionIndicator
    property alias mapControls: mapControls

    property XFormMapSettings mapSettings

    //--------------------------------------------------------------------------

    gesture {
        //activeGestures: MapGestureArea.ZoomGesture | MapGestureArea.PanGesture
        enabled: true
    }
    
    activeMapType: supportedMapTypes[0]

    //--------------------------------------------------------------------------

    gesture.onPinchStarted: {
        positionMode = positionModeOn;
    }

    gesture.onPanStarted: {
        positionMode = positionModeOn;
    }

    gesture.onFlickStarted: {
        positionMode = positionModeOn;
    }

    //--------------------------------------------------------------------------

    onCopyrightLinkActivated: Qt.openUrlExternally(link)

    //--------------------------------------------------------------------------

    onActiveMapTypeChanged: { // Force update of min/max zoom levels
        minimumZoomLevel = -1;
        maximumZoomLevel = 9999;
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceConnection

        onNewPosition: {
            if (positionMode == positionModeAutopan) { // !positionIndicator.visible) {
                map.center = position.coordinate;
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormMapControls {
        id: mapControls
        
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        
        map: parent
        mapSettings: parent.mapSettings
        positionSourceConnection: map.positionSourceConnection
        z: 9999
    }
    
    XFormMapPositionIndicator {
        id: positionIndicator

        positionSourceConnection: map.positionSourceConnection
    }

    MapCircle {
        property real s: 40075000 * Math.cos(center.latitude * Math.PI / 180 ) / Math.pow(2, map.zoomLevel + 8)   // S=C*cos(y)/2^(z+8) Pixels per meter
        property real m: s * 10 * AppFramework.displayScaleFactor
        visible: positionIndicator.visible
        center: positionIndicator.center
        color: "transparent"
        radius: Math.max(positionIndicator.horizontalAccuracy, m)
        border {
            color: "#00b2ff"
            width: 3 * AppFramework.displayScaleFactor
        }

        ScaleAnimator on scale {
            loops: Animation.Infinite
            from: 0.0
            to: 1.1
            duration: 2000
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapTypeItem

        MenuItem {
            property Map map
            property var mapType

            checkable: true
            checked: map.activeMapType === mapType

            onTriggered: {
                map.activeMapType = mapType;
            }
        }
    }

    function addMapTypeMenuItems(menu) {
        console.log("Adding map types menu items");

        var mapTypes = map.supportedMapTypes

        for (var i = 0; i < mapTypes.length; i++) {
            var mapType = mapTypes[i];

            console.log("mapType", JSON.stringify(mapType, undefined, 2));

            if (map.mapSettings.mobileOnly && !mapType.mobile) {
                console.log("Not a mobile map");
                continue;
            }

            var menuItem = mapTypeItem.createObject(menu, {
                                                        map: map,
                                                        mapType: mapType,
                                                        text: mapType.name
                                                    });

            menu.insertItem(menu.items.length, menuItem);
        }
    }

    //--------------------------------------------------------------------------

    function zoomToDefault() {
        if (mapSettings.zoomLevel > 0) {
            console.log("Zoom to level:", mapSettings.zoomLevel);
            map.zoomLevel = mapSettings.zoomLevel;
        } else if (map.zoomLevel < mapSettings.defaultZoomLevel) {
            console.log("Zoom to default level:", mapSettings.defaultPreviewZoomLevel);
            map.zoomLevel = mapSettings.defaultZoomLevel;
        }

        var coord = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);
        if (coord.isValid) {
            console.log("Zoom to:", coord);
            map.center = coord;
        }
    }

    //--------------------------------------------------------------------------
    // @FIXME : Workaround for crash by using timer

    function zoomToRectangle(rectangle, centerZoomLevel) {
        function doZoom() {
            if (rectangle.width > 0 && rectangle.height > 0) {
                // console.log("zoomToRectangle:", rectangle);

                rectangle.width *= 1.1;
                rectangle.height *= 1.1;

                visibleRegion = rectangle;
            } else {
                // console.log("zoomToRectangle:", rectangle.center, centerZoomLevel);

                center = rectangle.center;
                map.zoomLevel = centerZoomLevel;
            }
        }

        delayTimer.callback = doZoom;
        delayTimer.restart();
    }

    //--------------------------------------------------------------------------

    function zoomToCoordinate(coordinate, zoomLevel) {

        if (typeof zoomLevel === "undefined") {
            zoomLevel = 14;
        }

        function doZoom() {
            center = coordinate;
            map.zoomLevel = zoomLevel;
        }

        delayTimer.callback = doZoom;
        delayTimer.restart();
    }

    Timer {
        id: delayTimer

        property var callback

        interval: 5
        triggeredOnStart: false
        repeat: false

        onTriggered: {
            callback();
        }
    }

    //--------------------------------------------------------------------------
}
