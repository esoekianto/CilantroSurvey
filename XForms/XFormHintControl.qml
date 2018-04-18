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
import QtMultimedia 5.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

RowLayout {
    property var hint

    readonly property string hintText: textValue(hint).trim() + (language ? "" : "")
    readonly property string audioSource: mediaValue(hint, "audio")

    anchors {
        left: parent.left
        right: parent.right
    }

    layoutDirection: xform.languageDirection

    //--------------------------------------------------------------------------

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true

        sourceComponent: hintTextComponent
    }

    Loader {
        sourceComponent: component_ColumnLayout
        active: audioSource > ""
    }

    //--------------------------------------------------------------------------

    Component {
        id: hintTextComponent

        Text {
            text: XFormJS.encodeHTMLEntities(hintText)
            color: xform.style.hintColor
            font {
                pointSize: xform.style.hintPointSize
                bold: xform.style.hintBold
                family: xform.style.hintFontFamily
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            visible: text > ""
            textFormat: Text.RichText

            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: component_ColumnLayout

        ColumnLayout {
            XFormAudioButton {
                Layout.preferredWidth: xform.style.playButtonSize
                Layout.preferredHeight: Layout.preferredWidth

                audio {
                    source: audioSource
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
