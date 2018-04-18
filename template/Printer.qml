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

Item {
    property PrinterConfig printerConfig

    property bool ready: false
    property bool debug: false
    property var printJobs

    //--------------------------------------------------------------------------

    function connect() {
        console.warn("Abstract printer connect");
    }

    function disconnect() {
        console.warn("Abstract printer disconnect");
    }

    function printLine(text) {
        console.warn("abstract printLine:", text);
    }

    //--------------------------------------------------------------------------

    onReadyChanged: {
        if (ready) {
            sendJobs();
        }
    }

    //--------------------------------------------------------------------------

    function addPrintJob(printCallback) {
        if (!printJobs) {
            printJobs = [];
        }

        printJobs.push(printCallback);

        if (ready) {
            sendJobs();
        }
    }

    //--------------------------------------------------------------------------

    function sendJobs() {
        if (!printJobs) {
            return;
        }

        printJobs.forEach(function (printCallback) {
            printCallback();
        });

        printJobs = null;
    }

    //--------------------------------------------------------------------------
}
