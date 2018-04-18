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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Rectangle {
    id: signatureControl

    property var binding
    property var mediatype
    property XFormData formData

    property var formElement

    property FileFolder imagesFolder: xform.attachmentsFolder
    property alias imagePath: imageFileInfo.filePath
    property url imageUrl
    property string imagePrefix: "Signature"

    //--------------------------------------------------------------------------

    property bool readOnly: false
    readonly property bool relevant: parent.relevant

    anchors {
        left: parent.left
        right: parent.right
    }

    height: xform.style.signatureHeight

    border {
        width: 1
        color: xform.style.signatureBorderColor
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        imagePrefix = binding["@nodeset"];
        var i = imagePrefix.lastIndexOf("/");
        if (i >= 0) {
            imagePrefix = imagePrefix.substr(i + 1);
        }

        console.log("signature prefix:", imagePrefix);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    XFormSignatureCanvas {
        id: sketchCanvas

        anchors {
            fill: parent
            margins: 1
        }

        color: xform.style.signatureBackgroundColor
        penColor: xform.style.signaturePenColor
        penWidth: xform.style.signaturePenWidth
        enabled: !readOnly

        ImageButton {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            width: 40 * AppFramework.displayScaleFactor
            height: width
            visible: !readOnly

            source: "images/clear.png"
            glowColor: "transparent"
            hoverColor: "transparent"
            pressedColor: "transparent"

            onClicked: {
                clear();
            }
        }

        onPenReleased: {
            updateValue();
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: imageFileInfo

    }

    //--------------------------------------------------------------------------

    function zeroPad(num, places) {
        var zero = places - num.toString().length + 1;
        return new Array(+(zero > 0 && zero)).join("0") + num;
    }

    function save() {
        if (sketchCanvas.isNull) {
            console.log("Null sketch:", imagePrefix);
            return undefined;
        }

        if (!imageFileInfo.exists) {
            /*
            var imageDate = new Date();
            var imageName = imagePrefix + "_" +
                    imageDate.getUTCFullYear().toString() +
                    zeroPad(imageDate.getUTCMonth(), 2) +
                    zeroPad(imageDate.getUTCDate(), 2) +
                    "-" +
                    zeroPad(imageDate.getUTCHours(), 2) +
                    zeroPad(imageDate.getUTCMinutes(), 2) +
                    zeroPad(imageDate.getUTCSeconds(), 2) +
                    ".jpg";
            */

            var imageName = imagePrefix + "-" + AppFramework.createUuidString(2) + ".jpg";

            imagePath = imagesFolder.filePath(imageName);
        }

        console.log("store signature:", imagePath);

        sketchCanvas.save(imagePath);

        return imageFileInfo.fileName;
    }


    //--------------------------------------------------------------------------

    function clear() {
        sketchCanvas.clear();
        if (imageFileInfo.exists) {
            if (imagesFolder.removeFile(imageFileInfo.fileName)) {
                console.log("Deleted signature:", imageFileInfo.filePath);
            } else {
                console.error("Failed to delete:", imageFileInfo.filePath);
            }
        }

        imagePath = ""
        imageUrl = "";

        updateValue();
    }

    //--------------------------------------------------------------------------
/*
    function storeValue() {
        save();
    }
*/
    //--------------------------------------------------------------------------

    function updateValue() {
        save();

        var imageName = imageFileInfo.fileName;
        console.log("signature-updateValue", imageName);

        if (!imageName.length) {
            imageName = undefined;
        }

        formData.setValue(binding, imageName);

        xform.controlFocusChanged(this, false, binding);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];
            console.log("signature-editMode:", editMode);

            readOnly = editMode > formData.kEditModeAdd;
        } else {
            readOnly = false;
        }

        console.log("signature-setValue", value, "readOnly:", readOnly);

        sketchCanvas.clear();

        if (value > "") {
            imagePath = imagesFolder.filePath(value);
            imageUrl = imagesFolder.fileUrl(value);

            sketchCanvas.load(imagePath);
        } else {
            imagePath = "";
            imageUrl = "";
        }

        formData.setValue(binding, value);
    }

    //--------------------------------------------------------------------------
}
