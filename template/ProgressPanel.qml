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
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0


Rectangle {
    id: progressPanel
    
    property alias title: titleText.text
    property alias message: messageText.text
    property alias progressBar: progressBar

    anchors {
        fill: parent
    }
    
    color: "#40000000"
    visible: false
    z: 99999

    Rectangle {
        anchors {
            fill: contentColumn
            margins: -5
        }

        visible: contentColumn.visible
        color: "white"
        radius: 5
    }

    Column {
        id: contentColumn

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 15
        }

        visible: !messagePanel.visible
        spacing: 5

        AppText {
            id: titleText

            width: parent.width

            font {
                pointSize: 22
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        AppText {
            id: messageText

            width: parent.width

            font {
                pointSize: 16
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        ProgressBar {
            id: progressBar

            anchors {
                left: parent.left
                right: parent.right
            }

            height: 20 * AppFramework.displayScaleFactor
            minimumValue: 0
            maximumValue: 1
        }

        AppBusyIndicator {
            anchors {
                horizontalCenter: parent.horizontalCenter
            }

            running: contentColumn.visible
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
        }
    }

    function open() {
        progressBar.value = 0;
        visible = true;
    }

    function close() {
        visible = false;
    }

    function closeSuccess(text) {
        messagePanel.showInfo(text);
    }

    function closeWarning(text, warnings) {
        if (Array.isArray(warnings)) {
            var warningsText = "";
            warnings.forEach(function (element) {
                warningsText += element + "\n";
            });

            messagePanel.showWarning(text, undefined, warningsText);
        } else {
            messagePanel.showWarning(text, undefined, JSON.stringify(warnings, undefined, 2));
        }
    }

    function closeError(text, message, details, report) {
        messagePanel.showError(text, message, details, report);
    }

    ConfirmPanel {
        id: messagePanel


        onButtonClicked: {
            if (index === 2) { // Report
                reportError();
            }
            progressPanel.close();
        }

        function showInfo(text, informativeText, detailedText) {
            show(StandardIcon.Information, text, informativeText, detailedText);
        }

        function showError(text, informativeText, detailedText, report) {
            show(StandardIcon.Critical, text, informativeText, detailedText, report);
        }

        function showWarning(text, informativeText, detailedText) {
            show(StandardIcon.Warning, text, informativeText, detailedText);
        }

        function show(icon, text, informativeText, detailedText, report) {
            clear();

            button1Text = qsTr("Ok");
            button2Text = report ? qsTr("Report this error to Esri") : "";
            messagePanel.title = text ? text : " ";
            messagePanel.informativeText = informativeText ? informativeText : " "
            messagePanel.detailedText = detailedText ? detailedText : ""

            switch (icon) {
            case StandardIcon.Information:
                messagePanel.icon = "images/information.png";
                break;

            case StandardIcon.Critical:
                messagePanel.icon = "images/critical.png";
                break;

            case StandardIcon.Warning:
                messagePanel.icon = "images/warning.png";
                break;

            default:
                messagePanel.icon = "";
            }

            messagePanel.open();
        }

        function reportError() {
            var urlInfo = AppFramework.urlInfo("mailto:survey123@esri.com");

            urlInfo.queryParameters = {
                "subject": "Survey123 Service Error Report",
                "body": "Error Report Details:\n" +
                        informativeText +
                        "\n\n" +
                        detailedText +
                        "\n\nOperating System: " + Qt.platform.os +
                        "\nApplication Version: " + app.info.version +
                        "\nFramework version: " + AppFramework.version +
                        "\n\n[Please add any further comments here]"
            };

            Qt.openUrlExternally(urlInfo.url);
        }
    }
}
