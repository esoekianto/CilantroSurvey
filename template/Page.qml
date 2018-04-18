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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import "../XForms"

//PageBackground {
Rectangle {
    id: page

    property alias backButton: backButton
    property alias actionButton: actionButton
    property Item contentItem
    property alias title: titleText.text
    property color accentColor: "#88c448"
    property color backgroundColor: app.backgroundColor
    property color textColor: app.textColor
    property real titlePointSize: 22
    property color headerBarColor: app.titleBarBackgroundColor
    property real headerBarHeight: 40 * AppFramework.displayScaleFactor
    property var backPage
    property real contentMargins: 5

    signal titleClicked()
    signal titlePressAndHold()


    color: backgroundColor

    Component.onCompleted: {
        if (contentItem) {
            contentItem.parent = page;
            contentItem.anchors.left = page.left;
            contentItem.anchors.right = page.right;
            contentItem.anchors.top = headerBar.bottom;
            contentItem.anchors.bottom = page.bottom;
            contentItem.anchors.margins = contentMargins;
        }
    }

    QtObject {
        id: internal

        property real buttonSize: 40 * AppFramework.displayScaleFactor
    }

    Rectangle {
        id: headerBar

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: headerBarHeight
        color: headerBarColor

        MouseArea {
            anchors.fill: parent

            onClicked: {
                titleClicked();
            }

            onPressAndHold: {
                titlePressAndHold();
            }
        }

        RowLayout {
            anchors.fill: parent

            Item {
                Layout.preferredWidth: internal.buttonSize
                Layout.preferredHeight: internal.buttonSize
                Layout.alignment: Qt.AlignVCenter

                height: width

                ImageButton {
                    id: backButton

                    anchors {
                        fill: parent
                        margins: 2
                    }

                    source: "images/back.png"
                    onClicked: {
                        closePage();
                    }
                }
            }

            AppText {
                id: titleText

                Layout.fillWidth: true
                Layout.fillHeight: true

                font {
                    pointSize: titlePointSize
                }

                fontSizeMode: Text.HorizontalFit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: app.titleBarTextColor
                elide: Text.ElideRight
            }

            Item {
                Layout.preferredWidth: internal.buttonSize
                Layout.preferredHeight: internal.buttonSize
                Layout.alignment: Qt.AlignVCenter

                height: width

                MenuButton {
                    id: actionButton

                    anchors {
                        fill: parent
                        margins: 2
                    }
                }
            }
        }
    }

    XFormMenuPanel {
        id: menuPanel

        menu: actionButton.menu
        backgroundColor: app.titleBarBackgroundColor
        textColor: app.titleBarTextColor
        fontFamily: app.fontFamily
    }

    //--------------------------------------------------------------------------

    function closePage() {
        console.log("backPage", backPage);
        if (backPage) {
            page.parent.pop(backPage);
        } else {
            page.parent.pop();
        }
    }

    //--------------------------------------------------------------------------
}
