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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "SurveyHelper.js" as Helper
import "../Portal"

ColumnLayout {
    readonly property string itemId: Helper.getPropertyValue(app.openParameters, "itemId", "")

    property alias itemInfo: portalItem.itemInfo
    readonly property url thumbnailUrl: itemInfo ? portalItem.contentUrl + "/info/" + itemInfo.thumbnail + (portal.signedIn ? "?token=" + portal.token : "") : ""
    property bool busy: false
    property bool accessDenied: false
    property bool notFound: false
    property bool isOnline: AppFramework.network.isOnline
    property bool signedIn: portal.signedIn
    property alias progressPanel: downloadSurvey.progressPanel
    property bool debug: false

    property color backgroundColor: "#f2f3ed"
    property color textColor: "#4c4c4c"
    property color accentColor: "#88c448"
    property color linkColor: "darkblue"
    property color titleTextColor: textColor

    signal downloaded()

    //--------------------------------------------------------------------------

    visible: !Helper.isEmpty(itemId) && !progressPanel.visible
    enabled: false

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: openParametersInfo.height + openParametersInfo.anchors.margins * 2

        color: backgroundColor
        radius: 3
        border {
            width: 1
            color: accentColor
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                //                showSignInOrDownloadPage();
            }

            onPressAndHold: {
                if (openParametersDiagInfo.visible) {
                    app.openParameters = null;
                    openParametersDiagInfo.visible = false;
                } else {
                    openParametersDiagInfo.visible = true;
                }
            }
        }

        ColumnLayout {
            id: openParametersInfo

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 5 * AppFramework.displayScaleFactor
            }

            AppBusyIndicator {
                Layout.alignment: Qt.AlignHCenter

                running: busy
                visible: running
            }

            ColumnLayout {
                Layout.fillWidth: true

                visible: !busy && Helper.isEmpty(itemInfo)

                Text {
                    Layout.fillWidth: true

                    text: qsTr("Survey not found")
                    color: titleTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 16
                        bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true

                    text: notFound
                          ? qsTr('Survey id <b>%1</b> does not exist or is inaccessible.').arg(itemId)
                          : qsTr('Survey id <a href="%2/home/item.html?id=%1"><b>%1</b></a> has not been downloaded').arg(itemId).arg(app.portal.owningSystemUrl)

                    color: textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    linkColor: isOnline ? linkColor: textColor
                    font {
                        pointSize: 14
                    }

                    onLinkActivated: {
                        if (isOnline) {
                            Qt.openUrlExternally(link);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    visible: accessDenied && portal.signedIn && isOnline

                    RoundedImage {
                        Layout.preferredHeight: 40 * AppFramework.displayScaleFactor
                        Layout.preferredWidth: Layout.preferredHeight

                        source: portal.userThumbnailUrl
                        border {
                            width: 1
                            color: "#40000000"
                        }
                        color: backgroundColor
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("<b>%1</b> (%2) does not have permission to download this survey.").arg(Helper.getPropertyValue(portal.user, "fullName")).arg(Helper.getPropertyValue(portal.user, "username"))
                        color: textColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                }

                ConfirmButton {
                    Layout.alignment: Qt.AlignHCenter

                    visible: accessDenied && isOnline

                    text: portal.signedIn ? qsTr("Sign in as different user") : qsTr("Sign in to download")

                    onClicked: {
                        if (portal.signedIn) {
                            portal.signOut();
                        }
                        portal.signInAction(qsTr("Please sign in to download survey"));
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                visible: !busy && !Helper.isEmpty(itemInfo) && isOnline

                RowLayout {
                    Layout.fillWidth: true

                    Image {
                        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 66 * AppFramework.displayScaleFactor

                        fillMode: Image.PreserveAspectFit
                        source: thumbnailUrl

                        Rectangle {
                            anchors.fill: parent

                            color: "transparent"

                            border {
                                width: 1
                                color: "#40000000"
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("The survey <b>%1</b> has not been downloaded.").arg(Helper.getPropertyValue(itemInfo, "title", itemId))
                        color: textColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    ImageButton {
                        Layout.preferredWidth: 44 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 44 * AppFramework.displayScaleFactor

                        source: "images/cloud-download.png"

                        onClicked: {
                            downloadSurvey.download(itemInfo);
                        }

                        onPressAndHold: {
                            app.openParameters = null;
                        }
                    }
                }
            }

            TextArea {
                id: openParametersDiagInfo

                Layout.fillWidth: true
                Layout.preferredHeight: 110 * AppFramework.displayScaleFactor

                visible: false
                text: app.openParameters ? JSON.stringify(app.openParameters, undefined, 2) : ""
                readOnly: true
            }

            Text {
                Layout.fillWidth: true

                visible: !isOnline

                text: qsTr("Your device is offline. Please connect to a network to download surveys.")
                color: textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Qt.AlignHCenter
                font {
                    bold: true
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    resources: [
        PortalItem {
            id: portalItem

            portal: app.portal

            onFailed: {
                accessDenied = error.code === 403 && error.messageCode === "GWM_0003";
                notFound = error.code === 400 && error.messageCode === "CONT_0001";
                busy = false;
            }

            onItemInfoDownloaded: {
                if (debug) {
                    console.log("itemInfo:", JSON.stringify(itemInfo, undefined, 2));
                }

                busy = false;

                var autoDownload = Helper.toBoolean(Helper.getPropertyValue(app.openParameters, "download", true));

                if (autoDownload) {
                    downloadSurvey.download(itemInfo);
                }
            }
        },

        DownloadSurvey {
            id: downloadSurvey

            portal: app.portal
            succeededPrompt: false
            debug: debug

            onSucceeded: {
                downloaded();
            }
        }
    ]

    //--------------------------------------------------------------------------

    onItemIdChanged: {
        portalItem.itemInfo = null;

        if (!isOnline) {
            return;
        }

        update();
    }

    //--------------------------------------------------------------------------

    onIsOnlineChanged: {
        if (!Helper.isEmpty(itemInfo)) {
            return;
        }

        update();
    }

    onSignedInChanged: {
        portalItem.itemInfo = null;

        update();
    }

    onEnabledChanged: {
        update();
    }

    //--------------------------------------------------------------------------

    function update() {
        if (Helper.isEmpty(itemId)) {
            return;
        }

        if (!enabled) {
            return;
        }

        busy = true;
        portalItem.itemId = itemId;
        portalItem.requestInfo();
    }

    //--------------------------------------------------------------------------
}
