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
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Extras 1.4

import ArcGIS.AppFramework 1.0

RowLayout {
    id: timePicker

    property date selectedDate
    property bool isValid: false

    property bool updating: false
    property bool initializing: true

    property real maxColumnWidth: 0
    property real defaultColumnWidth: 0

    layoutDirection: xform.languageDirection

    //--------------------------------------------------------------------------

    onSelectedDateChanged: {
        isValid = true;
        updateTumblers();
    }

    onVisibleChanged: {
        if (visible) {
            if (!isValid) {
                selectedDate = new Date();
            }

            updating = false;
            updateTumblers();
        }
    }

    //--------------------------------------------------------------------------

    MouseArea {
        Layout.fillWidth: true
        Layout.fillHeight: true

        onClicked: {
            forceActiveFocus();
        }
    }

    Tumbler {
        id: tumbler

        Component.onCompleted: {
            initializing = false;
            updateTumblers();
        }

        TumblerColumn {
            id: hoursColumn

            model: [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            onCurrentIndexChanged: updateTime()

            Component.onCompleted: {
                defaultColumnWidth = width;
            }
        }

        TumblerColumn {
            id: minutesColumn

            model: new Array(60).join().split(',').map(function(item, index){
                return (index < 10) ? ("0" + index) : index;
            })

            onCurrentIndexChanged: updateTime()
        }

        TumblerColumn {
            id: apColumn

            model: [Qt.locale().amText, Qt.locale().pmText]
            onCurrentIndexChanged: updateTime()
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        selectedDate.setTime(NaN);
        isValid = false;
    }

    //--------------------------------------------------------------------------

    function updateTime() {
        if (initializing) {
            return;
        }

        if (updating) {
            return;
        }
        updating = true;

        var time = new Date();

        if (isValid) {
            time.setTime(selectedDate.getTime());
        }

        var hours = hoursColumn.currentIndex;
        var minutes = minutesColumn.currentIndex;

        if (apColumn.currentIndex === 1) {
            hours += 12;
        }

        time.setHours(hours);
        time.setMinutes(minutes);
        time.setSeconds(0);
        time.setMilliseconds(0);


        if (selectedDate.getTime() != time.getTime()) {
            isValid = true;
            selectedDate = time;
        }

        updating = false;
    }

    //--------------------------------------------------------------------------

    function updateTumblers() {
        if (updating) {
            return;
        }
        updating = true;

        var time = new Date();

        if (isValid) {
            time.setTime(selectedDate.getTime());
        }

        var hours = time.getHours();
        var minutes = time.getMinutes();
        var ap = 0;

        if (hours >= 12) {
            hours -= 12;
            ap = 1;
        }

        tumbler.setCurrentIndexAt(0, hours);
        tumbler.setCurrentIndexAt(1, minutes);
        tumbler.setCurrentIndexAt(2, ap);

        if (maxColumnWidth > 0 && defaultColumnWidth > 0) {
            var w = Math.min(defaultColumnWidth, maxColumnWidth);

            hoursColumn.width = w;
            minutesColumn.width = w;
            apColumn.width = w;
        }


        updating = false;
    }
}
