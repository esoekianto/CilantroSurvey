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
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.1
import QtQuick.Extras 1.4

import ArcGIS.AppFramework 1.0

Calendar {
    id: calendar

    property int yearStart: new Date().getFullYear() - 75;
    property int yearEnd: yearStart + 100
    property bool yearPickerVisible: false
    property bool monthPickerVisible: false
    property int barHeight: Math.round(TextSingleton.implicitHeight * 2)
    property int barTextSize: TextSingleton.implicitHeight * 1.1
    readonly property int monthRepeatInterval: 100
    readonly property int yearRepeatInterval: 50

    __locale: xform.locale

    style: CalendarStyle {
        
        dayOfWeekDelegate: Rectangle {
            color: gridVisible ? "#fcfcfc" : "transparent"
            implicitHeight: Math.round(TextSingleton.implicitHeight * 2.25)
            Label {
                text: control.__locale.dayName(styleData.dayOfWeek, control.dayOfWeekFormat)
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#444"
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
                minimumPointSize: 6
                font {
                    family: xform.style.calendarFontFamily
                }
            }
        }

        dayDelegate: Rectangle {
            anchors.fill: parent
            anchors.leftMargin: (!addExtraMargin || control.weekNumbersVisible) && styleData.index % CalendarUtils.daysInAWeek === 0 ? 0 : -1
            anchors.rightMargin: !addExtraMargin && styleData.index % CalendarUtils.daysInAWeek === CalendarUtils.daysInAWeek - 1 ? 0 : -1
            anchors.bottomMargin: !addExtraMargin && styleData.index >= CalendarUtils.daysInAWeek * (CalendarUtils.weeksOnACalendarMonth - 1) ? 0 : -1
            anchors.topMargin: styleData.selected ? -1 : 0
            color: styleData.date !== undefined && styleData.selected ? selectedDateColor : "transparent"

            readonly property bool addExtraMargin: control.frameVisible && styleData.selected
            readonly property color sameMonthDateTextColor: "#444"
            readonly property color selectedDateColor: Qt.platform.os === "osx" ? "#3778d0" : SystemPaletteSingleton.highlight(control.enabled)
            readonly property color selectedDateTextColor: "white"
            readonly property color differentMonthDateTextColor: "#bbb"
            readonly property color invalidDateColor: "#dddddd"
            Label {
                id: dayDelegateText
                text: styleData.date.getDate()
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignRight
                font {
                    pixelSize: Math.min(parent.height/2, parent.width/2)
                    family: xform.style.calendarFontFamily
                }
                color: {
                    var theColor = invalidDateColor;
                    if (styleData.valid) {
                        // Date is within the valid range.
                        theColor = styleData.visibleMonth ? sameMonthDateTextColor : differentMonthDateTextColor;
                        if (styleData.selected)
                            theColor = selectedDateTextColor;
                    }
                    theColor;
                }
            }
        }

        navigationBar: Rectangle {
            height: barHeight * 2 + 1
            color: "#f9f9f9"
            
            Rectangle {
                color: Qt.rgba(1,1,1,0.6)
                height: 1
                width: parent.width
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                height: 1
                width: parent.width
                color: "#ddd"
            }
            
            ColumnLayout {
                id: columnLayout

                property int textSize: height * 0.35

                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height/2

                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-left.png"
                        repeatInterval: monthRepeatInterval

                        onClicked: control.showPreviousMonth()
                        onRepeat: control.showPreviousMonth()
                    }

                    Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        text: control.__locale.standaloneMonthName(control.visibleMonth)
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: "#444"
                        font {
                            pixelSize: columnLayout.textSize
                            family: xform.style.inputFontFamily
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                monthPickerLoader.active = true;
                                monthPickerVisible = !monthPickerVisible;
                            }
                        }
                    }

                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-right.png"
                        repeatInterval: monthRepeatInterval

                        onClicked: control.showNextMonth()
                        onRepeat: control.showNextMonth();
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#ccc"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-left.png"
                        repeatInterval: yearRepeatInterval

                        onClicked: control.showPreviousYear()
                        onRepeat: control.showPreviousYear()
                    }

                    Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        text: control.visibleYear
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        font {
                            pixelSize: columnLayout.textSize
                            family: xform.style.inputFontFamily
                        }
                        color: "#444"

                        MouseArea {
                            anchors.fill: parent

                            enabled: control.visibleYear >= yearStart && control.visibleYear < yearEnd

                            onClicked: {
                                yearPickerLoader.active = true;
                                yearPickerVisible = !yearPickerVisible;
                            }
                        }
                    }


                    XFormHoverButton {
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height * 1.5

                        source: "images/arrow-right.png"
                        repeatInterval: yearRepeatInterval

                        onClicked: control.showNextYear()
                        onRepeat: control.showNextYear()
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: monthPickerLoader

        anchors.fill: parent

        sourceComponent: monthPickerComponent
        active: false
        visible: monthPickerVisible
    }

    Component {
        id: monthPickerComponent

        Rectangle {
            id: monthPicker

            property var calendarControl

            color: "#20000000"

            onVisibleChanged: {
                if (visible) {
                    monthTumbler.setCurrentIndexAt(0, calendar.visibleMonth);
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    monthPickerVisible = false;
                }

                Tumbler {
                    id: monthTumbler

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }

                    TumblerColumn {
                        width: 100 * AppFramework.displayScaleFactor

                        Component.onCompleted: {
                            var months = [];
                            for (var month = 0; month < 12; month++) {
                                months.push(calendar.__locale.standaloneMonthName(month));
                            }

                            model = months;
                        }

                        onCurrentIndexChanged: {
                            if (monthPickerVisible) {
                                calendar.visibleMonth = currentIndex;
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: yearPickerLoader

        anchors.fill: parent

        sourceComponent: yearPickerComponent
        active: false
        visible: yearPickerVisible
    }

    Component {
        id: yearPickerComponent

        Rectangle {
            id: yearPicker

            property var calendarControl

            color: "#20000000"

            onVisibleChanged: {
                if (visible) {
                    yearTumbler.setCurrentIndexAt(0, calendar.visibleYear - yearStart);
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    yearPickerVisible = false;
                }

                Tumbler {
                    id: yearTumbler

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: barHeight + 1
                    }

                    TumblerColumn {
                        Component.onCompleted: {
                            var years = [];
                            for (var year = yearStart; year < yearEnd; year++) {
                                years.push(year);
                            }

                            model = years;
                        }

                        onCurrentIndexChanged: {
                            if (yearPickerVisible) {
                                calendar.visibleYear = currentIndex + yearStart;
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
