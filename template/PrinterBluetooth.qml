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
import QtBluetooth 5.3

Printer {
    ready: btSocket.connected

    BluetoothSocket {
        id: btSocket

        connected: false

        onSocketStateChanged: {
            console.log("btSocket socketState:", JSON.stringify(socketState));
        }

        onErrorChanged: {
            console.log("btSocket error:", JSON.stringify(error));
        }

        onConnectedChanged: {
            console.log("btSocket connected:", connected);
        }

        service: BluetoothService {
            deviceAddress: printerConfig.deviceAddress
            serviceUuid: printerConfig.serviceUuid
            serviceProtocol: BluetoothService.RfcommProtocol

            onDetailsChanged: {
                console.log("btService Details:", deviceName);
                console.log("deviceAddress:", deviceAddress);
                console.log("serviceUuid:", serviceUuid);
                console.log("serviceProtocol:", serviceProtocol);
            }
        }
    }

    //--------------------------------------------------------------------------

    function connect() {
        if (btSocket.connected) {
            return;
        }

        console.log("Connecting:", btSocket.service.deviceAddress);
        btSocket.connected = true;
    }

    //--------------------------------------------------------------------------

    function disconnect() {
        if (!btSocket.connected) {
            return;
        }

        console.log("Disconnecting");

        btSocket.connected = false;
    }

    //--------------------------------------------------------------------------

    function printLine(text) {
        if (!text) {
            text = "";
        }

        if (debug) {
            console.log("btPrint:", text);
        }

        btSocket.stringData = text + "\r";
    }
}
