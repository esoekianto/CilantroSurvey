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
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Private 1.0

import ArcGIS.AppFramework 1.0

CheckBox {
    id: checkBox

    property int horizontalAlignment: Text.AlignLeft

    activeFocusOnPress: true

    style: CheckBoxStyle {
        id: checkboxStyle

        label: Item {
            implicitWidth: text.implicitWidth + 2
            implicitHeight: text.implicitHeight
            baselineOffset: text.baselineOffset

            Rectangle {
                anchors.fill: text
                anchors.margins: -1
                anchors.leftMargin: -3
                anchors.rightMargin: -3
                visible: control.activeFocus
                height: 6
                radius: 3
                color: "#224f9fef"
                border.color: "#47b"
                opacity: 0.6
            }

            Text {
                id: text
                text: control.text //StyleHelpers.stylizeMnemonics(control.text)
                anchors.fill: parent
                color: xform.style.selectTextColor //SystemPaletteSingleton.text(control.enabled)
                renderType: Text.QtRendering //Settings.isMobile ? Text.QtRendering : Text.NativeRendering
                font {
                    pointSize: xform.style.selectPointSize
                    bold: xform.style.selectBold
                    family: xform.style.selectFontFamily
                }
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: xform.languageDirection == Qt.RightToLeft ? Text.AlignRight : Text.AlignLeft
                elide: Text.ElideRight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                //textFormat: Text.RichText

                onHorizontalAlignmentChanged: {
                    checkBox.horizontalAlignment = horizontalAlignment;
                }
            }
        }

        indicator: Item {
            implicitWidth: Math.round(TextSingleton.implicitHeight)
            height: width
            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: -1
                color: "#44ffffff"
                radius: baserect.radius
            }

            Rectangle {
                id: baserect
                gradient: Gradient {
                    GradientStop {color: "#eee" ; position: 0}
                    GradientStop {color: control.pressed ? "#eee" : "#fff" ; position: 0.1}
                    GradientStop {color: "#fff" ; position: 1}
                }
                radius: TextSingleton.implicitHeight * 0.16
                anchors.fill: parent
                border.color: control.activeFocus ? "#47b" : "#999"
            }

            Image {
                anchors {
                    fill: parent
                    margins: baserect.border.width
                }

                source: "images/check-black.png"
                opacity: control.checkedState === Qt.Checked ? control.enabled ? 1 : 0.5 : 0
                fillMode: Image.PreserveAspectFit
                Behavior on opacity {NumberAnimation {duration: 80}}
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: Math.round(baserect.radius)
                antialiasing: true
                gradient: Gradient {
                    GradientStop {color: control.pressed ? "#555" : "#999" ; position: 0}
                    GradientStop {color: "#555" ; position: 1}
                }
                radius: baserect.radius - 1
                anchors.centerIn: parent
                anchors.alignWhenCentered: true
                border.color: "#222"
                Behavior on opacity {NumberAnimation {duration: 80}}
                opacity: control.checkedState === Qt.PartiallyChecked ? control.enabled ? 1 : 0.5 : 0
            }
        }


        panel: Item {
            implicitWidth: Math.max(backgroundLoader.implicitWidth, row.implicitWidth + padding.left + padding.right)
            implicitHeight: Math.max(backgroundLoader.implicitHeight, labelLoader.implicitHeight + padding.top + padding.bottom) //,indicatorLoader.implicitHeight + padding.top + padding.bottom)
            baselineOffset: labelLoader.item ? padding.top + labelLoader.item.baselineOffset : 0

            Loader {
                id: backgroundLoader
                sourceComponent: background
                anchors.fill: parent
            }
            RowLayout {
                id: row
                anchors.fill: parent

                anchors.leftMargin: padding.left
                anchors.rightMargin: padding.right
                anchors.topMargin: padding.top
                anchors.bottomMargin: padding.bottom

                spacing: checkboxStyle.spacing
                //layoutDirection: checkBox.horizontalAlignment == Text.AlignRight ? Qt.RightToLeft : Qt.LeftToRight
                layoutDirection: xform.languageDirection

                Loader {
                    id: indicatorLoader
                    Layout.preferredHeight: 15 * AppFramework.displayScaleFactor
                    Layout.preferredWidth: Layout.preferredHeight
                    sourceComponent: indicator
                    //anchors.verticalCenter: parent.verticalCenter
                }
                Loader {
                    id: labelLoader
                    Layout.fillWidth: true
                    sourceComponent: label
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
