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

import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

GroupBox {
    id: groupBox

    property var label
    property alias contentItems: itemsColumn
    property var binding
    property XFormData formData
    property bool relevant: parent.relevant

    property var labelControl
    property var hintControl

    anchors {
        left: parent.left
        right: parent.right
    }

    visible: relevant
    title: textValue(label) + (language ? "" : "")

    Component.onCompleted: {
        if (formData && binding && binding["@relevant"]) {
            relevant = formData.relevantBinding(binding);
        }
    }

    Column {
        id: itemsColumn

        readonly property alias relevant: groupBox.relevant

        anchors {
            left: parent.left
            right: parent.right
        }

        spacing: 5 * AppFramework.displayScaleFactor
    }
}
