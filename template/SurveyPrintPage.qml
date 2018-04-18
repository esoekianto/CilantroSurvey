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

import "../XForms"

import "CPCL.js" as CPCL

Page {
    id: page

    property XForm xform

    title: "Print Survey"

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


            ConfirmButton {
                Layout.fillWidth: true

                enabled: printerConfig.valid

                text: "Print"

                onClicked: {
                    printer.addPrintJob(printSurvey);
                    printer.connect();
                }
            }

            ConfirmButton {
                Layout.fillWidth: true

                text: "Print to Email"

                onClicked: {
                    printEmail();
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            GroupBox {
                Layout.fillWidth: true

                title: "Printer"

                ColumnLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: printerConfig.deviceName
                        color: "black"
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        horizontalAlignment: Text.AlignHCenter
                    }

                    AppText {
                        Layout.fillWidth: true

                        visible: printer.ready
                        text: "Ready"
                        color: "black"
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ConfirmButton {
                        Layout.fillWidth: true

                        text: "Configure Printer"

                        onClicked: {
                            printer.disconnect();

                            page.Stack.view.push({
                                                     item: printerConfigPage,
                                                     properties: {
                                                         printer: printer
                                                     }
                                                 });
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: printerConfigPage

        PrinterConfigPage {
        }
    }

    //--------------------------------------------------------------------------

    PrinterConfig {
        id: printerConfig
    }

    //--------------------------------------------------------------------------

    PrinterBluetooth {
        id: printer

        printerConfig: printerConfig
        debug: true

        Component.onCompleted: {
            CPCL.setSendLine(printLine);
        }
    }

    //--------------------------------------------------------------------------

    function printEmail() {
        var printObject = xform.formData.toPrintObject();

        var subject = printObject.title;
        var body = JSON.stringify(printObject.printFields, undefined, 2);

        var urlInfo = AppFramework.urlInfo("mailto:");

        urlInfo.queryParameters = {
            "subject": subject,
            "body": body
        };

        Qt.openUrlExternally(urlInfo.url);
    }

    //--------------------------------------------------------------------------

    function printSurvey() {
        console.log("Printing...");

        var printObject = xform.formData.toPrintObject();

        CPCL.printSurvey(printObject);
    }

    //--------------------------------------------------------------------------
}
