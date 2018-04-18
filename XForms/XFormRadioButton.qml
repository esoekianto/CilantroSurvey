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
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Private 1.0

RadioButton {
    id: radioButton

    property int horizontalAlignment: Text.AlignLeft
    property int orientation: Qt.Horizontal

    activeFocusOnPress: true

    style: RadioButtonStyle {
        id: radioButtonStyle

        label: Item {
            implicitWidth: text.implicitWidth + 2
            implicitHeight: text.implicitHeight
            baselineOffset: text.y + text.baselineOffset

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
                verticalAlignment: orientation == Qt.Vertical ? Text.AlignTop : Text.AlignVCenter
                horizontalAlignment: orientation == Qt.Vertical ? Text.AlignHCenter : (xform.languageDirection == Qt.RightToLeft ? Text.AlignRight : Text.AlignLeft)
                elide: Text.ElideRight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                // textFormat: Text.RichText

                onHorizontalAlignmentChanged: {
                    radioButton.horizontalAlignment = horizontalAlignment;
                }
            }
        }

        indicator: Rectangle {
            width:  Math.round(TextSingleton.implicitHeight)
            height: width
            gradient: Gradient {
                GradientStop {color: "#eee" ; position: 0}
                GradientStop {color: control.pressed ? "#eee" : "#fff" ; position: 0.4}
                GradientStop {color: "#fff" ; position: 1}
            }
            border.color: control.activeFocus ? "#16c" : "gray"
            antialiasing: true
            radius: height/2

            Rectangle {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.5)
                height: width
                gradient: Gradient {
                    GradientStop {color: "#999" ; position: 0}
                    GradientStop {color: "#555" ; position: 1}
                }
                border.color: "#222"
                antialiasing: true
                radius: height/2
                Behavior on opacity {NumberAnimation {duration: 80}}
                opacity: control.checked ? control.enabled ? 1 : 0.5 : 0
            }
        }

        panel: Item {
            implicitWidth: Math.max(backgroundLoader.implicitWidth, orientation == Qt.Horizontal ? panelLayout.implicitWidth + padding.left + padding.right : 0)
            implicitHeight: Math.max(backgroundLoader.implicitHeight, panelLayout.implicitHeight + padding.top + padding.bottom)
            //            implicitHeight: Math.max(backgroundLoader.implicitHeight, labelLoader.implicitHeight + padding.top + padding.bottom,indicatorLoader.implicitHeight + padding.top + padding.bottom)
            baselineOffset: labelLoader.item ? padding.top + labelLoader.item.baselineOffset : 0

            Loader {
                id: backgroundLoader
                sourceComponent: background
                anchors.fill: parent
            }

            GridLayout {
                id: panelLayout

                anchors {
                    fill: parent

                    leftMargin: padding.left
                    rightMargin: padding.right
                    topMargin: padding.top
                    bottomMargin: padding.bottom
                }

                columns: orientation == Qt.Vertical ? 1 : 2
                rows: orientation == Qt.Vertical ? 2 : 1
                columnSpacing: radioButtonStyle.spacing
                rowSpacing: columnSpacing

                //layoutDirection: radioButton.horizontalAlignment == Text.AlignRight ? Qt.RightToLeft : Qt.LeftToRight
                layoutDirection: xform.languageDirection

                Loader {
                    id: indicatorLoader

                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: Math.round(TextSingleton.implicitHeight)
                    Layout.preferredWidth: Layout.preferredHeight

                    sourceComponent: indicator
                }

                Loader {
                    id: labelLoader

                    Layout.fillWidth: true

                    sourceComponent: label
                }
            }

            /*
            RowLayout {
                id: row

                anchors {
                    fill: parent

                    leftMargin: padding.left
                    rightMargin: padding.right
                    topMargin: padding.top
                    bottomMargin: padding.bottom
                }

                spacing: radioButtonStyle.spacing

                layoutDirection: radioButton.horizontalAlignment == Text.AlignRight ? Qt.RightToLeft : Qt.LeftToRight

                Loader {
                    id: indicatorLoader
                    sourceComponent: indicator
                    anchors.verticalCenter: parent.verticalCenter
                }

                Loader {
                    id: labelLoader
                    Layout.fillWidth: true
                    sourceComponent: label
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            */
        }
    }
}
