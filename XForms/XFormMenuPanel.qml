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

Rectangle {
    id: sideBar

    property bool autoHide: false
    property int autoHideTimeout: 3000
    property int animationDuration: 250
    property color lineColor: "#80A0A0A0"
    property int lineWidth: 1
    property color textColor: "white" //#E0E0E0"
    property color backgroundColor: "darkgrey" //"#C0000000"
    property color highlightTextColor: backgroundColor
    property color highlightBackgroundColor: textColor
    property color separatorColor: "#20ffffff"
    property int titleBarHeight: 40 * AppFramework.displayScaleFactor
    property string title
    property string fontFamily

    property Menu menu

    property var menuModel

    anchors {
        top: parent.top
        topMargin: title > "" ? titleBarHeight : 0
        //topMargin: (internal.buttonMargin + 10) * AppFramework.displayScaleFactor
        bottom: parent.bottom
    }

    Rectangle {
        anchors {
            right: parent.right
            bottom: parent.top
            bottomMargin: title > "" ? 0 : -titleBarHeight
        }

        width: parent.parent.width * 2
        height: titleBarHeight

        color: backgroundColor
        opacity: sideBar.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: animationDuration
            }
        }

        Text {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            width: parent.parent.width

            text: title
            font {
                pointSize: 20
                family: fontFamily
            }

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            color: textColor
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }

            visible: title > ""
            height: 1
            color: lineColor
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
            }
        }

        ImageButton {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: parent.parent.width + 5 * AppFramework.displayScaleFactor
            }

            source: "images/actions.png" //images/arrow_right.png"
            height: 36 * AppFramework.displayScaleFactor
            width: height

            ColorOverlay {
                anchors.fill: parent
                source: parent.image
                color: textColor
            }

            onClicked: {
                hide();
            }
        }
    }

    z: 9999

    visible: false
    width: 220 * AppFramework.displayScaleFactor

    x: parent.width

    color: backgroundColor
    
    function toggle() {
        if (visible) {
            hide();
        } else {
            show();
        }
    }

    function show() {
        updateMenuModel();
        showSideBarAnimation.start();
    }
    
    function hide() {
        hideSideBarAnimation.start();
    }

    function startTimer() {
        sideBarTimer.restart();
    }

    function stopTimer() {
        sideBarTimer.stop();
    }

    function updateMenuModel() {
        if (menu) {
            menuModel = [];

            for (var i = 0; i < menu.items.length; i++) {
                var menuItem = menu.items[i];

                if (menuItem.visible) {
                    menuModel.push(menuItem);
                }
            }

            menuListView.model = null;
            menuListView.model = menuModel;
        }
    }


    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        onExited: {
            if (autoHide && autoHideTimeout > 0) {
                sideBarTimer.start();
            }
        }
        onEntered: {
            sideBarTimer.stop();
        }
        onClicked: {
            hide();
        }
    }
    
    Rectangle {
        width: lineWidth
        color: lineColor
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
    }
    
    PropertyAnimation {
        id: showSideBarAnimation

        target: sideBar
        property: "x"
        to: parent.width - width
        easing {
            type: Easing.InCubic
        }
        duration: animationDuration
        onStarted: {
            sideBar.visible = true;
        }
        onStopped: {
            if (autoHide && autoHideTimeout > 0) {
                sideBarTimer.start();
            }
        }
    }
    
    PropertyAnimation {
        id: hideSideBarAnimation
        target: sideBar
        property: "x"
        to: parent.width

        duration: animationDuration
        easing {
            type: Easing.OutCubic
        }

        onStopped: {
            sideBar.visible = false;
            sideBarTimer.stop();
        }
    }
    
    Timer {
        id: sideBarTimer
        repeat: false
        interval: autoHideTimeout
        
        onTriggered: {
            parent.hide();
        }
    }

    ListView {
        id: menuListView

        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        model: menuModel //menu ? menuModel : null
        spacing: 5 * AppFramework.displayScaleFactor
        clip: true

        delegate: menuItemDelegate
    }

    Component {
        id: menuItemDelegate

        Rectangle {
            property MenuItem menuItem: menuListView.model[index];

            width: menuListView.width
            height: menuRow.height + 10 * AppFramework.displayScaleFactor

            color: (itemMouseArea.containsMouse || itemMouseArea.pressed) ? highlightBackgroundColor : "transparent"

            RowLayout {
                id: menuRow

                anchors {
                    top: parent.top
                    topMargin: 5 * AppFramework.displayScaleFactor
                    left: parent.left
                    right: parent.right
                }

                opacity: menuItem.enabled ? 1 : 0.5


                Item {
                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: 30 * AppFramework.displayScaleFactor

                    visible: menuItem.checkable && !menuItem.hideCheck

                    Image {
                        id: checkImage

                        anchors.fill: parent

                        source: menuItem.checked ? "images/check.png" : ""
                        visible: menuItem.checkable && !menuItem.hideCheck

                    }

                    ColorOverlay {
                        anchors.fill: checkImage

                        visible: checkImage.visible && checkImage.source > ""
                        source: checkImage
                        color: menuText.color
                        cached: true
                    }
                }


                Item {
                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: 30 * AppFramework.displayScaleFactor

                    visible: menuItem.iconSource > ""

                    Image {
                        id: menuImage

                        anchors.fill: parent

                        source: menuItem.iconSource
                        visible: source > ""
                        fillMode: Image.PreserveAspectFit
                    }

                    ColorOverlay {
                        anchors.fill: menuImage

                        visible: menuImage.visible && !menuItem.noColorOverlay
                        source: menuImage
                        color: menuText.color
                    }
                }

                Text {
                    id: menuText

                    Layout.fillWidth: true

                    text: menuItem.text
                    color: (itemMouseArea.containsMouse || itemMouseArea.pressed) ? highlightTextColor: textColor
                    font {
                        pointSize: 18
                        family: fontFamily
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.bottom
                }

                height: 1
                color: separatorColor
            }

            MouseArea {
                id: itemMouseArea

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (menuItem.enabled) {
                        hide();
                        menuItem.triggered();
                    }
                }
            }
        }
    }

    Rectangle {
        parent: sideBar.parent
        anchors {
            fill: parent
            topMargin: titleBarHeight
        }

        visible: sideBar.visible
        color: AppFramework.alphaColor(backgroundColor, 0.1)

        MouseArea {
            anchors.fill: parent


            onClicked: {
                sideBar.hide();
            }

            onWheel: {
            }
        }

        z: sideBar.z - 1
    }
}
