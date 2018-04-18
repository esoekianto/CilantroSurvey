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
import QtMultimedia 5.5
import QtQuick.Window 2.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Networking 1.0

import "SketchControl"

Rectangle {
    id: page

    //--------------------------------------------------------------------------

    property string title
    property url imageUrl
    property url temporaryAttachmentUrl
    property FileFolder imagesFolder
    property string imagePrefix: "Sketch"

    property color titleTextColor: "white"
    property color toolColor: xform.style.titleTextColor
    property bool annotate: false

    property alias defaultImageUrl: sketchCanvas.defaultImageUrl
    property bool useExternalCamera: false
    property url externalCameraIcon

    property string appearance

    property bool betaMode: false

    //--------------------------------------------------------------------------

    signal saved(string path, url url)

    //--------------------------------------------------------------------------

    color: "#777"//"#0000000"

    Component.onCompleted: {
        var fileInfo = AppFramework.fileInfo(imageUrl);
        if (fileInfo.exists) {
            sketchCanvas.load(fileInfo.filePath);
        }
    }

    //--------------------------------------------------------------------------

    Screen.onPrimaryOrientationChanged : {
        // 1: portrait
        // 2: landscape
        // if the orientation changes then need to reset everything and redraw the canvas as the dimensions.
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
        }

        //----------------------------------------------------------------------

        RowLayout {
            Layout.fillWidth: true

            XFormImageButton {
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor

                source: "images/back.png"
                color: titleTextColor

                onClicked: {
                    page.parent.pop();
                }
            }

            XFormText {
                Layout.fillWidth: true

                text: title
                font {
                    pointSize: xform.style.titlePointSize
                    family: xform.style.titleFontFamily
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: titleTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                MouseArea {
                    anchors.fill: parent

                    onPressAndHold: {
                        betaMode = !betaMode;
                    }
                }
            }

            XFormMenuButton {
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor

                color: titleTextColor
                menuPanel: menuPanel
            }
        }

        //----------------------------------------------------------------------

        XFormSketchCanvas {
            id: sketchCanvas

            Layout.fillWidth: true
            Layout.fillHeight: true

            color: xform.style.signatureBackgroundColor

            workFolder: imagesFolder
        }

        //----------------------------------------------------------------------

        RowLayout {
            id: toolsLayout

            Layout.fillWidth: true
            Layout.leftMargin: 5 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin
            Layout.bottomMargin: 5 * AppFramework.displayScaleFactor

            spacing: 10 * AppFramework.displayScaleFactor


            XFormImageButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                source: "SketchControl/images/undo.png"
                color: toolColor

                onClicked: {
                    sketchCanvas.canvas.deleteLastSketch();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                id: cameraButton

                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
                Layout.alignment: Qt.AlignLeft


                visible: QtMultimedia.availableCameras.length > 0 && canAnnotate
                source: useExternalCamera ? externalCameraIcon : "images/camera.png"
                color: useExternalCamera ? "transparent" : toolColor

                onClicked: {
                    xform.popoverStackView.push({
                                                    item: useExternalCamera ? externalCameraPageComponent: cameraPageComponent,
                                                    properties: {
                                                        resolution: Qt.size(sketchCanvas.width, sketchCanvas.height)
                                                    }
                                                });
                }
            }

            Item {
                Layout.fillWidth: true
                visible: cameraButton.visible
            }

            XFormImageButton {
                id: folderButton

                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                visible: canAnnotate /* && betaMode*/
                source: "images/folder.png"
                color: toolColor

                onClicked: {
                    pictureChooser.open();
                }
            }

            Item {
                Layout.fillWidth: true
                visible: folderButton.visible
            }

            XFormImageButton {
                id: mapButton

                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                source: "images/globe.png"
                color: toolColor
                visible: Networking.isOnline && canAnnotate && betaMode

                onClicked: {
                    Qt.inputMethod.hide();
                    xform.popoverStackView.push({
                                                    item: mapCapture,
                                                    properties: {
                                                    }
                                                });
                }
            }

            Item {
                Layout.fillWidth: true
                visible: mapButton.visible
            }

            SketchPenButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                canvas: sketchCanvas.canvas
            }

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                Layout.preferredHeight: 35 * AppFramework.displayScaleFactor
                Layout.alignment: Qt.AlignRight

                source: "images/ok_button.png"
                //enabled: !sketchCanvas.isNull
                visible: enabled

                color: toolColor

                onClicked: {
                    save();
                    page.parent.pop();
                }
            }
        }

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------

    XFormMenuPanel {
        id: menuPanel

        textColor: xform.style.titleTextColor
        backgroundColor: page.color //xform.style.titleBackgroundColor
        fontFamily: xform.style.menuFontFamily

        //title: ""
        menu: Menu {
            MenuItem {
                text: qsTr("Clear sketch")

                onTriggered: {
                    sketchCanvas.clear();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: cameraPageComponent
        XFormCameraCapture {
            imagesFolder: page.imagesFolder
            imagePrefix: "$camera"

            title: title

            onCaptured: {
                clearTemporaryAttachment();
                sketchCanvas.resetPastedImageObject();
                sketchCanvas.pasteImage(url);
                sketchCanvas.lastLoadedImage = path;
                temporaryAttachmentUrl = path;
            }
        }
    }

    Component {
        id: externalCameraPageComponent
        XFormExternalCameraCapture {
            imagesFolder: page.imagesFolder
            imagePrefix: "$camera"
            appearance: page.appearance

            title: title

            onCaptured: {
                clearTemporaryAttachment();
                sketchCanvas.resetPastedImageObject();
                sketchCanvas.pasteImage(url);
                sketchCanvas.lastLoadedImage = path;
                temporaryAttachmentUrl = path;
            }
        }
    }

    XFormPictureChooser {
        id: pictureChooser

        parent: xform.popoverStackView
        outputFolder: page.imagesFolder
        outputPrefix:  "$chooser"

        onAccepted: {
            clearTemporaryAttachment();
            sketchCanvas.resetPastedImageObject();
            var path = AppFramework.resolvedPath(pictureUrl);
            console.log(path)
            sketchCanvas.pasteImage(path);
            sketchCanvas.lastLoadedImage = path;
            temporaryAttachmentUrl = path;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: mapCapture

        XFormMapCapture {
            positionSourceManager: positionSourceConnection.positionSourceManager
            map.plugin: XFormMapPlugin {
                settings: mapSettings
            }

            onAccepted: {
                sketchCanvas.canvas.addImageObject(imageObject);
            }
        }
    }

    //--------------------------------------------------------------------------

    function save() {
        if (sketchCanvas.isNull) {
            console.log("Null sketch:", imagePrefix);
            return;
        }

        var imagePath;

        if (!(imageUrl > "")) {
            var imageName = imagePrefix + "-" + AppFramework.createUuidString(2) + ".jpg";

            imageUrl = imagesFolder.fileUrl(imageName);
        }

        var fileInfo = AppFramework.fileInfo(imageUrl);
        imagePath = fileInfo.filePath;

        console.log("save sketch url:", imageUrl, "path:", imagePath);

        if (!sketchCanvas.save(imagePath)) {
            console.error("Canvas not saved");
            return;
        }

        saved(imagePath, imageUrl);
        clearTemporaryAttachment();
    }

    //--------------------------------------------------------------------------

    function clearTemporaryAttachment(){
        imagesFolder.removeFile(temporaryAttachmentUrl);
    }

    //--------------------------------------------------------------------------

}
