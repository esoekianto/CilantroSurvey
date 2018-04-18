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
import QtQuick.Controls.Styles 1.2
import QtQuick.Layouts 1.1
import QtMultimedia 5.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

RowLayout {
    id: radioControl

    property var binding
    property var label
    property var value
    property string appearance
    property XFormRadioGroup radioGroup

    Layout.preferredWidth: xform.style.gridColumnWidth
    Layout.fillWidth: true
    Layout.alignment: likert ? Qt.AlignTop : Qt.AlignVCenter | Qt.AlignLeft

    readonly property bool compact: appearance === "compact" || appearance === "quickcompact"
    readonly property bool likert: appearance === "likert"

    readonly property string imageSource: mediaValue(label, "image")
    readonly property string audioSource: mediaValue(label, "audio")
    
    clip: true
    layoutDirection: xform.languageDirection

    //--------------------------------------------------------------------------

    Component {
        id: imageButtonComponent

        ImageButton {
            source: imageSource
            glowColor: "transparent"
            hoverColor: "transparent"
            pressedColor: "transparent"

            onClicked: {
                xform.popoverStackView.push({
                                                item: valuesPreview,
                                                properties: {
                                                    values: radioControl.label
                                                }
                                            });
            }
        }
    }

    Loader {
        Layout.preferredWidth: xform.style.imageButtonSize
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: imageButtonComponent
        active: imageSource > ""
        visible: active
    }
    
    //--------------------------------------------------------------------------

    XFormRadioButton {
        id: radioButton

        Layout.fillWidth: true

        text: (!compact || compact && !(imageSource > "")) ? textValue(label) + (language ? "" : "") : ""
        checked: radioGroup.value == value
        orientation: likert ? Qt.Vertical : Qt.Horizontal

        onClicked: {
            // console.log("radio click:", text, "checked:", checked, "value:", value, "groupValue:", radioGroup.value);

            if (checked) {
                radioGroup.value = value;
                radioGroup.label = label;
            } else {
                if (radioGroup.value == value) {
                    radioGroup.value = undefined;
                    radioGroup.label = undefined;
                }
            }
        }

        onActiveFocusChanged: {
            xform.controlFocusChanged(this, activeFocus, binding);
        }
    }

    Connections {
        target: radioGroup

        onValueChanged: {
            radioButton.checked = radioGroup.value == value;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: audioButtonComponent

        XFormAudioButton {
            audio {
                source: audioSource
            }

            ttsText: radioButton.text
        }
    }

    Loader {
        Layout.preferredWidth: xform.style.playButtonSize
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: audioButtonComponent
        active: audioSource > ""
        visible: active
    }

    //--------------------------------------------------------------------------
}
