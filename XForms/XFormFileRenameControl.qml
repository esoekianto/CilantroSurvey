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

import ArcGIS.AppFramework 1.0

Item {
    id: control

    property FileFolder fileFolder
    property string fileName
    property bool readOnly
    property int padding: 4 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    signal renamed(string newFileName)

    //--------------------------------------------------------------------------

    implicitHeight: textInput.height + 2 * padding

    clip: true
    
    //--------------------------------------------------------------------------

    onFileNameChanged: {
        textInput.text = fileName;
        textInput.color = xform.style.valueColor;
    }

    //--------------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        focus: false
        color: xform.style.inputBackgroundColor
        visible: textInput.focus
        border {
            width: 1
            color: xform.style.inputBorderColor
        }
    }
    
    TextInput {
        id: textInput
        
        property string suffix: ""
        property string oldFileName: ""
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: padding
        }
        
        font {
            pointSize: xform.style.inputPointSize * 0.7
            family: xform.style.inputFontFamily
        }

        enabled: !control.readOnly
        readOnly: control.readOnly
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        cursorVisible: false
        selectByMouse: true
        wrapMode: TextEdit.Wrap
        color: xform.style.valueColor
        inputMethodHints: Qt.ImhNoPredictiveText

        text: fileName

        onFocusChanged: {
            if (focus) {
                oldFileName = text;
                suffix = text.split(".")[1];
                text = text.split(".")[0];
                color = xform.style.inputTextColor;
                horizontalAlignment = Text.AlignLeft;
            } else {
                text = text + "." + suffix;
                console.log("Renaming: ", fileFolder.path, oldFileName, text)
                color = xform.style.valueColor;
                horizontalAlignment = Text.AlignHCenter;
                if (oldFileName !== text) {
                    if (fileFolder.renameFile(oldFileName, text)) {
                        console.log("Rename succeeded:", fileFolder.fileUrl(text));

                        renamed(text);
                    } else {
                        color = xform.style.inputErrorTextColor;
                        text = oldFileName;
                    }
                }
                Qt.inputMethod.hide();
            }
        }
        
        onEditingFinished: {
            console.log("Rename finished:", text, suffix);
            focus = false;
            cursorVisible = false;
        }
    }

    //--------------------------------------------------------------------------

    function rename(newFileName) {
        var oldFileName = fileName;

        if (fileFolder.renameFile(oldFileName, newFileName)) {
            console.log("Rename succeeded:", fileFolder.fileUrl(newFileName));
            textInput.text = newFileName;

            renamed(newFileName);

            return true;
        }

        console.error("Rename failed:", oldFileName, "=>", newFileName);
        textInput.color = xform.style.inputErrorTextColor;
    }

    //--------------------------------------------------------------------------
}
