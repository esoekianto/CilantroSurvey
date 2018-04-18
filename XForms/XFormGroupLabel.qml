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
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Column {
    property var label

    readonly property string labelText: textValue(label).trim() + (language ? "" : "")
    readonly property string imageSource: mediaValue(label, "image")
    property bool collapsed: false
    property bool collapsible: false
    property bool required: false
    
    width: parent.width
    spacing: 5 * AppFramework.displayScaleFactor
    
    //--------------------------------------------------------------------------

    Loader {
        sourceComponent: labelTextComponent
        width: parent.width
    }

    Loader {
        width: parent.width
        sourceComponent: imageComponent
        active: imageSource > ""
    }

    //--------------------------------------------------------------------------

    Component {
        id: labelTextComponent

        RowLayout {
            layoutDirection: xform.languageDirection

            Loader {
                Layout.preferredWidth: 25 * AppFramework.displayScaleFactor * xform.style.scale
                Layout.preferredHeight: Layout.preferredWidth

                active: collapsible
                visible: collapsible
                sourceComponent: Image {

                    fillMode: Image.PreserveAspectFit
                    source: "images/group-indicator.png"

                    rotation: collapsed ? (xform.languageDirection === Qt.RightToLeft ? 90 : -90) : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            collapsed = !collapsed;
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true

                text: XFormJS.encodeHTMLEntities(labelText)  + (required ? ' <font color="red">*</font>' : "")
                color: xform.style.groupLabelColor
                font {
                    pointSize: xform.style.groupLabelPointSize
                    bold: xform.style.groupLabelBold
                    family: xform.style.groupLabelFontFamily
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                visible: text > ""
                textFormat: Text.RichText
            }
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: imageComponent

        Image {
            source: imageSource
            fillMode: Image.PreserveAspectFit
            visible: !collapsed

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    xform.popoverStackView.push({
                                                    item: valuesPreview,
                                                    properties: {
                                                        values: label
                                                    }
                                                });
                }
            }
        }
    }

    //--------------------------------------------------------------------------

}
