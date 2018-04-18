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
import QtQuick.Layouts 1.1

Rectangle {
    property real padding: 0
    property alias controlsGrid: controlsGrid
    property alias columns: controlsGrid.columns
    property alias controls: controlsGrid.children

    color: "transparent"

    height: visible ? controlsGrid.height + padding * 2 : 0
    
    GridLayout {
        id: controlsGrid

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: padding
        }

        columns: width / xform.style.gridColumnWidth
        columnSpacing: xform.style.gridSpacing
        rowSpacing: xform.style.gridSpacing

        layoutDirection: xform.languageDirection
    }
}
