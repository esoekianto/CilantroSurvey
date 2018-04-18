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

import QtQuick 2.9

import ArcGIS.AppFramework 1.0

import "../Portal"
import "XForm.js" as XFormJS

Item {
    property Portal portal
    property var webhooks
    property bool debug: true

    //--------------------------------------------------------------------------

    readonly property string kEventAddData: "addData"
    readonly property string kEventEditData: "editData"

    //--------------------------------------------------------------------------

    onWebhooksChanged: {
        console.log("onWebhooksChanged:", JSON.stringify(webhooks));
    }

    //--------------------------------------------------------------------------

    function handleEvent(event, callback) {
        if (!Array.isArray(webhooks)) {
            console.log("No webhooks defined");
            return;
        }

        console.log("handle webhook event:", event);

        webhooks.forEach(function (webhook) {
            if (handlesEvent(webhook, event)) {
                callback(webhook, event);
            }
        });
    }

    //--------------------------------------------------------------------------

    function handlesEvent(webhook, event) {
        if (!webhook.active) {
            console.log("Not active");
            return;
        }

        if (!Array.isArray(webhook.events)) {
            console.log("Events not an array");
            return;
        }

        if (webhook.events.indexOf(event) < 0) {
            console.log("Event not found:", event);
            return;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function submit(surveyInfo, featureServiceInfo, applyEdits, response) {

        function findLayer(layerId) {
            for (var i = 0; i < featureServiceInfo.layers.length; i++) {
                var info = featureServiceInfo.layers[i];

                if (info.id == layerId) {
                    return featureServiceInfo.layers[i]
                }
            }

            for (i = 0; i < featureServiceInfo.tables.length; i++) {
                info = featureServiceInfo.tables[i];

                if (info.id == layerId) {
                    return featureServiceInfo.tables[i]
                }
            }

            return null;
        }

        var _surveyInfo = {
            "formItemId": surveyInfo.itemId,
            "formTitle": surveyInfo.title,
            "serviceItemId": featureServiceInfo.itemId,
            "serviceUrl": featureServiceInfo.url
        }

        var layerId = applyEdits[0]["id"];
        var layer = findLayer(layerId);

        var layerInfo = {
            "id": layer.id,
            "name": layer.name
        }

        handleEvent(kEventAddData, function (webhook, event) {
            var feature = applyEdits[0].adds[0];
            feature["layerInfo"] = layerInfo;

            var payload = {
                "feature": feature
            };

            if (webhook.includeServiceRequest) {
                payload["applyEdits"] = applyEdits;
            }

            if (webhook.includeServiceResponse) {
                payload["response"] = response;
            }

            if (webhook.includeSurveyInfo) {
                payload["surveyInfo"] = _surveyInfo;
            }

            //webhookRequest.sendRequest(webhook, event, payload);
            sendRequest(webhook, event, payload);
        });
    }

    //--------------------------------------------------------------------------

    NetworkRequest {
        id: webhookRequest

        method: "POST"

        onReadyStateChanged: {
            if (readyState === NetworkRequest.DONE ) {
            }
        }

        function sendRequest(webhook, event, payload) {
            url = webhook.url;

            headers.json = {
                "Content-Type": "application/json",
                "X-Survey123-Event": event,
                "X-Survey123-Signature": webhook.secret,
                "X-Survey123-Delivery": AppFramework.createUuidString(1)
            };

            send(payload);
        }
    }

    //--------------------------------------------------------------------------

    function sendRequest (webhook, event, payload) {

        if (webhook.includePortalInfo) {
            var portalInfo = {
                "url": portal.portalUrl.toString(),
                "token": portal.token
            };

            payload.portalInfo = portalInfo;
        }

        if (webhook.includeUserInfo) {
            var userInfo = {
                "username": XFormJS.userProperty(app, 'username'),
                "firstName": XFormJS.userProperty(app, 'firstName'),
                "lastName": XFormJS.userProperty(app, 'lastName'),
                "fullName": XFormJS.userProperty(app, 'fullName'),
                "email": XFormJS.userProperty(app, 'email'),
            };

            payload.userInfo = userInfo;
        }

        console.log("sending webhook event:", event, "webhook:", JSON.stringify(webhook, undefined, 2), "payload:", JSON.stringify(payload, undefined, 2));


        var request = new XMLHttpRequest();

        request.onreadystatechange = function() {
            console.log("Webhook event:", event, "readyState:", request.readyState);
        }

        request.open("POST", webhook.url);

        request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setRequestHeader("X-Survey123-Event", event);
        request.setRequestHeader("X-Survey123-Delivery", AppFramework.createUuidString(1));
        //request.setRequestHeader("X-Survey123-Signature", webhook.secret);

        var data = JSON.stringify(payload, undefined, 2);

        request.send(data);
    }

    //--------------------------------------------------------------------------
}

