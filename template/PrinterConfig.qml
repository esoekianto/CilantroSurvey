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

import ArcGIS.AppFramework 1.0

Item {
    property string type: "Bluetooth"

    property bool valid: deviceAddress > ""

    property string deviceName
    property string deviceAddress
    property string serviceUuid: "{00001101-0000-0000-0000-000000000000}"

    property int dpi: 203
    property int widthDots: 384

    readonly property string kKeyPrefix: "Printer/"
    readonly property string kKeyDeviceAddress: kKeyPrefix + "deviceAddress"

    property Settings setting: app.settings

    Component.onCompleted: {
        read();
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log("Reading printer configuration");

        deviceAddress = app.settings.value(kKeyDeviceAddress);
        deviceName = "Zebra iMZ220";
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log("Writing printer configuration");

        settings.setValue(kKeyDeviceAddress, deviceAddress);
    }

    //--------------------------------------------------------------------------
}
