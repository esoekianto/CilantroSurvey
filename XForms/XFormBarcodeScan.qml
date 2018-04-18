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
import QtQuick.Controls.Styles 1.4
import QtMultimedia 5.5
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Barcodes 1.0


Rectangle {
    id: page

    property var formElement

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: AppFramework.alphaColor(accentColor, 0.9)

    property int defaultDecodeHints: BarcodeDecoder.DecodeHintCODE_39 |
                                     BarcodeDecoder.DecodeHintCODE_93 |
                                     BarcodeDecoder.DecodeHintCODE_128 |
                                     BarcodeDecoder.DecodeHintEAN_8 |
                                     BarcodeDecoder.DecodeHintEAN_13 |
                                     BarcodeDecoder.DecodeHintQR_CODE |
                                     BarcodeDecoder.DecodeHintRSS_14 |
                                     BarcodeDecoder.DecodeHintRSS_EXPANDED |
                                     BarcodeDecoder.DecodeHintUPC_A |
                                     BarcodeDecoder.DecodeHintUPC_E |
                                     BarcodeDecoder.DecodeHintUPC_EAN_EXTENSION

    //--------------------------------------------------------------------------

    signal codeScanned(string code)

    //--------------------------------------------------------------------------

    color: "#D0000000"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        codeScanViewPage.decodeHints = app.settings.numberValue("Barcode/decodeHints", defaultDecodeHints);
        codeScanViewPage.decodeHints |= BarcodeDecoder.DecodeHintTryHarder;

        var deviceId = app.settings.value("Barcode/Camera/deviceId", "");
        if (deviceId > "") {
            codeScanViewPage.camera.deviceId = deviceId;
        }
    }

    Component.onDestruction: {
        app.settings.setValue("Barcode/decodeHints", codeScanViewPage.decodeHints);
        app.settings.setValue("Barcode/Camera/deviceId", codeScanViewPage.camera.deviceId);
    }


    //--------------------------------------------------------------------------

    onCodeScanned: {
        audio.play();
    }

    Audio {
        id: audio

        source: "audio/barcode-ok.mp3"
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            id: titleBar

            Layout.fillWidth: true

            property int buttonHeight: 35 * AppFramework.displayScaleFactor

            height: columnLayout.height + 5
            color: barBackgroundColor //"#80000000"

            ColumnLayout {
                id: columnLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 2
                }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    ImageButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.buttonHeight
                        Layout.preferredWidth: titleBar.buttonHeight

                        source: "images/back.png"

                        ColorOverlay {
                            anchors.fill: parent
                            source: parent.image
                            color: xform.style.titleTextColor
                        }

                        onClicked: {
                            close();
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: textValue(formElement.label, "", "long")
                        font {
                            pointSize: xform.style.titlePointSize
                            family: xform.style.titleFontFamily
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: barTextColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    XFormMenuButton {
                        Layout.fillHeight: true
                        Layout.preferredHeight: titleBar.buttonHeight
                        Layout.preferredWidth: titleBar.buttonHeight

                        menuPanel: barcodeMenuPanel
                    }
                }
                /*
                Text {
                    Layout.fillWidth: true

                    text: textValue(formElement.hint, "", "long")
                    visible: text > ""
                    font {
                        pointSize: 12
                    }
                    horizontalAlignment: Text.AlignHCenter
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
*/
            }
        }

        XFormBarcodeScanView {
            id: codeScanViewPage

            Layout.fillWidth: true
            Layout.fillHeight: true

            onCodeScanned: {
                page.close();
                page.codeScanned(code);
            }
            onSelectCamera: {
                cameraComboBox.visible = true;
                switchButton.visible = false;
            }
        }

        XFormCameraComboBox {
            id: cameraComboBox

            Layout.fillWidth: true

            camera: codeScanViewPage.camera

            onActivated: {
                cameraComboBox.visible = false;
                cameraControls.switchButton.visible = true;
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormMenuPanel {
        id: barcodeMenuPanel

        textColor: xform.style.titleTextColor
        backgroundColor: xform.style.titleBackgroundColor
        fontFamily: xform.style.menuFontFamily

        title: qsTr("Barcode Types")
        menu: Menu {
            id: barcodeMenu

            MenuItem {
                text: qsTr("Any type")
                checkable: true
                checked: codeScanViewPage.decodeHints == -1

                onTriggered: {
                    if (codeScanViewPage.decodeHints != -1) {
                        codeScanViewPage.decodeHints = -1;
                    } else {
                        codeScanViewPage.decodeHints = defaultDecodeHints | BarcodeDecoder.DecodeHintTryHarder;
                    }
                }
            }
        }

        Component.onCompleted: {
            addBarcodeTypes();
        }

        Component {
            id: barcodeTypeItem

            MenuItem {
                property int decodeHint

                checkable: true
                checked: (codeScanViewPage.decodeHints & decodeHint) != 0

                onTriggered: {
                    if (codeScanViewPage.decodeHints & decodeHint) {
                        console.log("Unset decodeHint:", decodeHint);
                        codeScanViewPage.decodeHints &= ~decodeHint;
                    } else {
                        console.log("Set decodeHint:", decodeHint);
                        codeScanViewPage.decodeHints |= decodeHint;
                    }
                }
            }
        }

        function addBarcodeTypes() {
            var barcodeTypes = [
                        { decodeHint: BarcodeDecoder.DecodeHintQR_CODE, name: "QR Code" },

                        { decodeHint: BarcodeDecoder.DecodeHintCODE_39, name: "Code 39" },
                        { decodeHint: BarcodeDecoder.DecodeHintCODE_93, name: "Code 93" },
                        { decodeHint: BarcodeDecoder.DecodeHintCODE_128, name: "Code 128" },

                        { decodeHint: BarcodeDecoder.DecodeHintEAN_8, name: "EAN 8" },
                        { decodeHint: BarcodeDecoder.DecodeHintEAN_13, name: "EAN 13" },

                        { decodeHint: BarcodeDecoder.DecodeHintUPC_A, name: "UPC A" },
                        { decodeHint: BarcodeDecoder.DecodeHintUPC_E, name: "UPC E" },
                        { decodeHint: BarcodeDecoder.DecodeHintUPC_EAN_EXTENSION, name: "UPC EAN Extension" },

                        { decodeHint: BarcodeDecoder.DecodeHintAZTEC, name: "Aztec" },
                        { decodeHint: BarcodeDecoder.DecodeHintCODABAR, name: "Codabar" },
                        { decodeHint: BarcodeDecoder.DecodeHintDATA_MATRIX, name: "Data Matrix" },
                        { decodeHint: BarcodeDecoder.DecodeHintITF, name: "ITF" },
                        { decodeHint: BarcodeDecoder.DecodeHintMAXICODE, name: "MaxiCode" },
                        { decodeHint: BarcodeDecoder.DecodeHintPDF_417, name: "PDF 417" },
                        { decodeHint: BarcodeDecoder.DecodeHintRSS_14, name: "RSS 14" },
                        { decodeHint: BarcodeDecoder.DecodeHintRSS_EXPANDED, name: "RSS Expanded" }
                    ];

            barcodeTypes.forEach(function(barcodeType) {
                var menuItem = barcodeTypeItem.createObject(barcodeMenu, {
                                                                decodeHint: barcodeType.decodeHint,
                                                                text: barcodeType.name
                                                            });

                barcodeMenu.insertItem(barcodeMenu.items.length, menuItem);
            });
        }
    }

    //--------------------------------------------------------------------------

    function close() {
        parent.pop();
    }
}
