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
import QtQuick.Dialogs 1.2
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

GroupBox {
    id: imageControl

    property var binding
    property var mediatype
    property XFormData formData

    property var formElement

    property FileFolder imagesFolder: xform.attachmentsFolder
    property alias imagePath: imageFileInfo.filePath
    property url imageUrl
    property string imagePrefix: "Image"

    readonly property var appearance: formElement ? formElement["@appearance"] : null
    readonly property bool canAnnotate: XFormJS.contains(appearance, "annotate")
    readonly property bool canDraw: XFormJS.contains(appearance, "draw")
    readonly property bool canDrawOrAnnotate: canDraw || canAnnotate
    readonly property bool useExternalCamera: XFormJS.contains(appearance, "spike") || XFormJS.contains(appearance, "spike-full-measure")
    property url externalCameraIcon: "images/spike-icon.png"


    property bool readOnly: false
    readonly property bool relevant: parent.relevant

    readonly property int buttonSize: 35 * AppFramework.displayScaleFactor

    property var calculatedValue
    property var defaultValue
    property url defaultImageUrl

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    flat: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        imagePrefix = binding["@nodeset"];
        var i = imagePrefix.lastIndexOf("/");
        if (i >= 0) {
            imagePrefix = imagePrefix.substr(i + 1);
        }

        console.log("image prefix:", imagePrefix);
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
        if (relevant && formData.changeBinding !== binding) {
            //console.log("onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            setDefaultValue(calculatedValue);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {

        width: parent.width

        Image {
            id: imagePreview

            Layout.preferredWidth: parent.width
            Layout.maximumHeight: 150 * AppFramework.displayScaleFactor

            autoTransform: true
            width: parent.width
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
            source: imageUrl
            cache: false
            smooth: false
            asynchronous: true
            sourceSize {
                width: imagePreview.width
                height: Layout.maximumHeight
            }

            visible: source > ""

            Rectangle {
                anchors.centerIn: parent

                width: parent.paintedWidth
                height: parent.paintedHeight

                border {
                    width: 1
                    color: "darkgrey"
                }
                color: "transparent"
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (canDrawOrAnnotate && !imageControl.readOnly) {
                        drawButton.clicked();
                    } else {
                    }
                }

                onPressAndHold: {
                    sourceText.visible = !sourceText.visible;
                }
            }

            function refresh() {
                var url = imageUrl;
                imageUrl = "";
                imageUrl = url;
            }


            XFormImageButton {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                width: buttonSize
                height: buttonSize

                source: "images/trash.png"
                color: xform.style.deleteIconColor
                visible: !imageControl.readOnly

                onClicked: {
                    var name = imagesFolder.fileInfo(imagePath).fileName;

                    var panel = confirmPanel.createObject(app, {
                                                              iconColor: "#a9d04d",
                                                              title: qsTr("Confirm Image Delete"),
                                                              question: qsTr("Are you sure you want to delete %1?").arg(name)
                                                          });

                    panel.show(deleteImage, undefined);
                }

                function deleteImage() {
                    imagesFolder.removeFile(imagePath);
                    setValue(null);
                }
            }
        }

        XFormImageButton {
            id: drawButton

            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize
            Layout.alignment: Qt.AlignHCenter

            source: canAnnotate ? "images/annotate.png" : "images/pencil.png"
            color: xform.style.iconColor
            visible: canDrawOrAnnotate && !imagePreview.visible && !readOnly

            onClicked: {
                xform.popoverStackView.push({
                                                item: sketchPage,
                                                properties: {
                                                    imageUrl: imageControl.imageUrl,
                                                    annotate: canAnnotate
                                                }
                                            });
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: buttonSize / 2
            visible: !readOnly

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/pencil.png"
                visible: canAnnotate && imageUrl > "" && false
                color: xform.style.iconColor

                onClicked: {
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: !canDrawOrAnnotate && QtMultimedia.availableCameras.length > 0
                source: useExternalCamera ? externalCameraIcon : "images/camera.png"
                color: useExternalCamera ? "transparent" : xform.style.iconColor

                onClicked: {
                    xform.popoverStackView.push({
                                                    item: useExternalCamera ? externalCameraPage : cameraPage,
                                                                              properties: {
                                                                              }
                                                });
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/folder.png"
                visible: !canDrawOrAnnotate
                color: xform.style.iconColor

                onClicked: {
                    pictureChooser.open();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: imageUrl > "" && !canDrawOrAnnotate
                source: "images/rotate_left.png"
                color: xform.style.iconColor

                onClicked: {
                    rotateImage(imagePath, -90);
                    imagePreview.refresh();
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: imageUrl > "" && !canDrawOrAnnotate
                source: "images/rotate_right.png"
                color: xform.style.iconColor

                onClicked: {
                    rotateImage(imagePath, 90);
                    imagePreview.refresh();
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        XFormFileRenameControl {
            Layout.fillWidth: true

            visible: imageUrl > ""
            fileName: imageFileInfo.fileName
            fileFolder: imagesFolder
            readOnly: imageControl.readOnly

            onRenamed: {
                imagePath = imagesFolder.filePath(newFileName);
                imageUrl = imagesFolder.fileUrl(newFileName);
                updateValue();
            }
        }
    }

    XFormPictureChooser {
        id: pictureChooser

        parent: xform.popoverStackView
        outputFolder: imageControl.imagesFolder
        outputPrefix: imageControl.imagePrefix

        onAccepted: {
            var path = AppFramework.resolvedPath(pictureUrl);
            resizeImage(path);
            imagePath = path;
            imageUrl = pictureUrl;
            updateValue();
        }
    }

    Component {
        id: cameraPage

        XFormCameraCapture {
            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            makerNote: JSON.stringify({
                                          "nodeset": binding["@nodeset"]
                                      })

            title: textValue(formElement.label, "", "long")

            onCaptured: {
                resizeImage(path);
                imagePath = path;
                imageUrl = url;
                updateValue();
            }
        }
    }

    Component {
        id: externalCameraPage

        XFormExternalCameraCapture {
            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            appearance: imageControl.appearance

            title: textValue(formElement.label, "", "long")

            onCaptured: {
                resizeImage(path);
                imagePath = path;
                imageUrl = url;
                updateValue();
                imagePreview.refresh();
            }
        }
    }

    Component {
        id: sketchPage

        XFormSketchCapture {
            title: textValue(formElement.label, "", "long")

            imagesFolder: imageControl.imagesFolder
            imagePrefix: imageControl.imagePrefix
            defaultImageUrl: imageControl.defaultImageUrl
            useExternalCamera: imageControl.useExternalCamera
            externalCameraIcon: imageControl.externalCameraIcon
            appearance: imageControl.appearance

            onSaved: {
                imageControl.imagePath = path;
                imageControl.imageUrl = url;
                updateValue();
                imagePreview.refresh();
            }
        }
    }

    FileInfo {
        id: imageFileInfo
    }

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            fontFamily: xform.style.fontFamily
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: imageObject
    }

    function resizeImage(path) {
        var captureResolution = xform.captureResolution;

        /* @TODO - Enable when settings are enabled again
        if (xform.allowCaptureResolutionOverride && app.captureResolution > 0) {
            captureResolution = app.captureResolution;
        }
        */

        if (!captureResolution) {
            console.log("No image resize:", captureResolution);
            return;
        }

        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error("Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log("File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error("Unable to load image:", path);
            return;
        }

        if (imageObject.width <= captureResolution) {
            console.log("No resize required:", imageObject.width, "<=", captureResolution);
            return;
        }

        console.log("Rescaling image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        imageObject.scaleToWidth(captureResolution);

        if (!imageObject.save(path)) {
            console.error("Unable to save image:", path);
            return;
        }

        imageObject.clear();

        fileInfo.refresh();
        console.log("Scaled image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }

    function rotateImage(path, angle) {
        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error("Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log("File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error("Unable to load image:", path);
            return;
        }

        console.log("Rotating image:", angle, imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        imageObject.rotate(angle);

        if (!imageObject.save(path)) {
            console.error("Unable to save image:", path);
            return;
        }

        imageObject.clear();

        fileInfo.refresh();
        console.log("Rotated image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        var imageName = imageFileInfo.fileName;
        console.log("image-updateValue:", imageName);
        console.log("imageUrl:", imageUrl);

        formData.setValue(binding, imageName);

        xform.controlFocusChanged(this, false, binding);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];
            console.log("image-editMode:", editMode);

            readOnly = editMode > formData.kEditModeAdd;
        } else {
            readOnly = false;
        }

        if (value > "") {
            console.log("image-setValue:", value, "readOnly:", readOnly);

            imagePath = imagesFolder.filePath(value);
            imageUrl = imagesFolder.fileUrl(value);
        } else {
            imagePath = "";
            imageUrl = "";
        }

        formData.setValue(binding, value);
    }

    //--------------------------------------------------------------------------

    function setDefaultValue(value) {
        defaultValue = value;

        if (defaultValue > "" && mediaFolder.fileExists(defaultValue)) {
            defaultImageUrl = mediaFolder.fileUrl(defaultValue);
        } else {
            defaultImageUrl = "";
        }

        console.log("image defaultValue:", defaultValue, "defaultImageUrl:", defaultImageUrl);
    }

    //--------------------------------------------------------------------------
}
