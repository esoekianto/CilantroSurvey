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

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

Tab {
    title: qsTr("Images")

    property int imageSizeSmall: 320
    property int imageSizeMedium: 640
    property int imageSizeLarge: 1280
    
    Item {
        id: imagesInfo

        Component.onDestruction: {
            app.captureResolution = imageSizeGroup.current.value;
            settings.setValue("Camera/captureResolution", app.captureResolution, 0);
        }

        ColumnLayout {

            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            Text {
                Layout.fillWidth: true

                text: qsTr("The image size setting helps you limit the size of photos submitted with your surveys. This setting will only be used if a survey has been configured to allow the image size specified by the survey to be overriden.")
                color: app.textColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
            }

            ExclusiveGroup {
                id: imageSizeGroup
            }

            GroupBox {
                Layout.fillWidth: true

                ColumnLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("Image Size")
                        color: app.textColor
                    }

                    StyledRadioButton {
                        Layout.fillWidth: true

                        property int value: 0

                        text: qsTr("As specified by the survey")
                        exclusiveGroup: imageSizeGroup
                        textColor: app.textColor
                        checked: !app.captureResolution
                    }

                    StyledRadioButton {
                        Layout.fillWidth: true

                        property int value: imageSizeSmall

                        text: qsTr("Small")
                        exclusiveGroup: imageSizeGroup
                        textColor: app.textColor
                        checked: app.captureResolution == value
                    }

                    StyledRadioButton {
                        Layout.fillWidth: true

                        property int value: imageSizeMedium

                        text: qsTr("Medium")
                        exclusiveGroup: imageSizeGroup
                        textColor: app.textColor
                        checked: app.captureResolution == value
                    }

                    StyledRadioButton {
                        Layout.fillWidth: true

                        property int value: imageSizeLarge

                        text: qsTr("Large")
                        exclusiveGroup: imageSizeGroup
                        textColor: app.textColor
                        checked: app.captureResolution == value
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
