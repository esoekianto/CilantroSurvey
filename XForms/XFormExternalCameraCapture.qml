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

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

Rectangle {
    id: page

    property string title: "Spike"
    property FileFolder imagesFolder
    property string imagePrefix: "Image"

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: AppFramework.alphaColor(accentColor, 0.75)

    property string appScheme: app.info.value("urlScheme")
    property FileInfo imageFileInfo

    property size resolution
    property string appearance
    property string referenceId: AppFramework.createUuidString(2)

    readonly property bool isSupported: Qt.platform.os === "ios" || Qt.platform.os === "android"

    //--------------------------------------------------------------------------

    signal captured(string path, url url)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var url = "spike-partner://capture-single?%1return-scheme=%2&return-reference=%3"
        .arg(XFormJS.contains(appearance, "spike-full-measure") ? "measure-mode=full-measure&" : "")
        .arg(appScheme)
        .arg(referenceId);

        if (!isSupported) {
            console.log("Spike app:", url);
            return;
        }

        console.log("Opening Spike app:", url);

        Qt.openUrlExternally(url);
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        onOpenUrl: {
            ///console.log("SurveyApp.onOpenUrl:", url);

            var urlInfo = AppFramework.urlInfo(url);

            if (urlInfo.host !== "capture-single" && urlInfo.host !== "full-measure") {
                console.log("Not an external camera app response:", url);
                console.log("Host:", urlInfo.host);

                return;
            }

            processResponse(url);
        }
    }

    //--------------------------------------------------------------------------

    function processResponse(url) {
        var urlInfo = AppFramework.urlInfo(url);

        console.log("Url:", url);
        var response = urlInfo.queryParameters;
        console.log("Parameters:", JSON.stringify(response, undefined, 2));

        if (!(referenceId === response["reference"])) {
            console.error("Reference mismatch:", referenceId, "!=", response["reference"]);
        }

        var imageId = response["image-identifier"];

        if (getImage(imageId)) {
            captured(imageFileInfo.filePath, imageFileInfo.url);
            closeControl();
        } else {
            errorDialog.show(imageId);
        }
    }

    //--------------------------------------------------------------------------

    Item {
        anchors.fill: parent

        z: 88

        Rectangle {
            anchors.fill: parent

            color: "black"

            ColumnLayout {
                anchors.fill: parent

                Rectangle {
                    id: titleBar

                    Layout.fillWidth: true

                    property int buttonHeight: 35 * AppFramework.displayScaleFactor

                    height: columnLayout.height + 5
                    //color: barBackgroundColor //"#80000000"
                    color: "transparent"

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

                                // source: "images/close.png"
                                source: "images/back.png"
                                pressedColor: "transparent"
                                hoverColor: "transparent"

                                ColorOverlay {
                                    anchors.fill: parent
                                    source: parent.image
                                    color: xform.style.titleTextColor
                                }

                                onClicked: {
                                    closeControl();
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                text: title
                                color: xform.style.titleTextColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                elide: Text.ElideRight

                                font {
                                    pixelSize: parent.height * 0.75
                                    family: xform.style.fontFamily
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                Layout.preferredHeight: titleBar.buttonHeight
                                Layout.preferredWidth: titleBar.buttonHeight
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    color: "#fffffd"

                    ColumnLayout {
                        anchors {
                            fill: parent
                            margins: 20 * AppFramework.displayScaleFactor
                        }

                        spacing: 10 * AppFramework.displayScaleFactor

                        Image {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            source: "images/spike.png"
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter

                            BusyIndicator {
                                anchors.centerIn: parent
                                running: isSupported
                            }
                        }

                        Text {
                            Layout.fillWidth: true

                            visible: !isSupported

                            text: qsTr("Spike not supported on this platform")

                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            color: "red"

                            font {
                                pointSize: 20
                                family: xform.style.fontFamily
                                bold: true
                            }
                        }

                        Text {
                            Layout.fillWidth: true

                            visible: isSupported

                            text: qsTr("Waiting for Spike app to complete")

                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter

                            font {
                                pointSize: 20
                                family: xform.style.fontFamily
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function closeControl() {
        parent.pop();
    }

    //--------------------------------------------------------------------------

    function getImage(imageId) {
        /*
        function zeroPad(num, places) {
            var zero = places - num.toString().length + 1;
            return new Array(+(zero > 0 && zero)).join("0") + num;
        }

        var imageDate = new Date();
        var imageName = imagePrefix + "-" +
                imageDate.getUTCFullYear().toString() +
                zeroPad(imageDate.getUTCMonth() + 1, 2) +
                zeroPad(imageDate.getUTCDate(), 2) +
                "-" +
                zeroPad(imageDate.getUTCHours(), 2) +
                zeroPad(imageDate.getUTCMinutes(), 2) +
                zeroPad(imageDate.getUTCSeconds(), 2) +
                ".jpg";
        */

        var imageFileName = imagePrefix + "-%1.jpg".arg(AppFramework.createUuidString(2));
        imageFileInfo = imagesFolder.fileInfo(imageFileName);

        imagesFolder.removeFile(imageFileName);

        console.log("Getting imageId:", imageId, "to:", imageFileInfo.filePath);

        switch (Qt.platform.os) {
        case "ios" :
            return getImage_iOS(imageId);

        case "android" :
            return getImage_Android(imageId);

        default:
            console.error("Unhandled OS:", Qt.platform.os);
            break;
        }
    }

    //--------------------------------------------------------------------------

    function getImage_iOS(imageId) {
        var fid = imageId.replace("/L0/001", "");
        var sourceUrl = "file:assets-library://asset/asset.JPG%3Fid=%1&ext=JPG".arg(fid);
        var sourceUrlInfo = AppFramework.urlInfo(sourceUrl);
        var sourcePath = sourceUrlInfo.localFile;

        console.log("Copying iOS image:", sourcePath);

        if (!imagesFolder.copyFile(sourcePath, imageFileInfo.filePath)) {
            console.error("Error copying iOS image:", sourcePath, "to:", imageFileInfo.filePath);
            return;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function getImage_Android(imageId) {
        var picturesPath = AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0];

        var sourcePath = "%1/spike/%2.jpg".arg(picturesPath).arg(imageId);

        console.log("Copying Android image:", sourcePath);

        if (!imagesFolder.copyFile(sourcePath, imageFileInfo.filePath)) {
            console.error("Error copying Android image:", sourcePath, "to:", imageFileInfo.filePath);
            return;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    MessageDialog {
        id: errorDialog

        icon: StandardIcon.Critical
        title: "Error"

        onAccepted: {
            closeControl();
        }

        function show(message) {
            text = message;
            visible = true;
        }
    }

    //--------------------------------------------------------------------------
}
