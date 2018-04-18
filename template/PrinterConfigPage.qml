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
import QtBluetooth 5.3

import ArcGIS.AppFramework 1.0

import "CPCL.js" as CPCL

Page {
    id: page

    property Printer printer

    title: "Printer Configuration"

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        printer.printerConfig.write();
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            GroupBox {
                Layout.fillWidth: true

                title: "Printer Type"

                ColumnLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    RadioButton {
                        Layout.fillWidth: true

                        text: "Zebra (CPCL)"
                        checked: true
                        enabled: false
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: "Dots Per Inch"
                        color: "black"
                    }

                    TextField {
                        Layout.fillWidth: true

                        text: printer.printerConfig.dpi
                        enabled: false

                        onEditingFinished: {
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: "Paper Width"
                        color: "black"
                    }

                    TextField {
                        Layout.fillWidth: true

                        text: printer.printerConfig.widthDots
                        enabled: false

                        onEditingFinished: {
                        }
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true

                title: "Device"

                ColumnLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    RadioButton {
                        Layout.fillWidth: true

                        text: "Bluetooth"
                        checked: true
                        enabled: false
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: "Address"
                        color: "black"
                    }

                    TextField {
                        id: deviceAddressField

                        Layout.fillWidth: true

                        inputMask: ">HH:HH:HH:HH:HH:HH;_"

                        text: printer.printerConfig.deviceAddress
                        textColor: acceptableInput ? "black" : "red"

                        onEditingFinished: {
                            printer.printerConfig.deviceAddress = text;
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        visible: printer.ready
                        text: "Connected"
                        color: "black"
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }


            ConfirmButton {
                Layout.fillWidth: true

                enabled: deviceAddressField.acceptableInput

                text: "Print Settings"

                onClicked: {
                    printStart();
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------

    function printStart() {
        printer.disconnect();
        printer.addPrintJob(printTest);
        printer.connect();
    }

    //--------------------------------------------------------------------------

    function printTest() {
        console.log("Printing Test...");

        CPCL.test();
    }

    //--------------------------------------------------------------------------
}
