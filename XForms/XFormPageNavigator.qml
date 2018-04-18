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

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Rectangle {
    id: pageNavigator

    //--------------------------------------------------------------------------

    property int count
    property int currentIndex
    property var currentPage
    property var pages: []
    readonly property int activePages: relevantPages(count)
    readonly property bool canGoto: count > 0
    readonly property bool canGotoPrevious: canGoto && currentIndex > 0
    readonly property bool canGotoNext: canGoto && currentIndex < (count - 1)
    readonly property bool atFirstPage: !canGoto || currentIndex == 0
    readonly property bool atLastPage: !canGoto || currentIndex == (count - 1)

    signal pageActivated()

    //--------------------------------------------------------------------------

    implicitHeight: layout.height + 10 * AppFramework.displayScaleFactor

    visible: canGoto
    color: xform.style.backgroundColor

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MouseArea {
                    anchors.fill: parent

                    enabled: canGotoPrevious

                    onClicked: {
                        gotoPreviousPage();
                    }
                }
            }

            Row {
                spacing: 5 * AppFramework.displayScaleFactor

                Repeater {
                    model: pageNavigator.count

                    Rectangle {
                        id: pageDelegate

                        readonly property int pageIndex: index
                        readonly property var page: pages[index]

                        width: 12 * AppFramework.displayScaleFactor
                        height: width
                        radius: width / 2

                        color: pageIndex === currentIndex ? xform.style.titleBackgroundColor : "lightgrey"

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                currentIndex = pageDelegate.pageIndex;
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MouseArea {
                    anchors.fill: parent

                    enabled: canGotoNext

                    onClicked: {
                        gotoNextPage();
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function addPage(page) {
        console.log("addPage:", page.labelText);

        page.relevantChanged.connect(onRelevantChanged);

        pages.push(page);
        count = pages.length;

        if (count > 1) {
            page.hidden = true;
        }
    }

    //--------------------------------------------------------------------------

    function onRelevantChanged() {
        console.log("onPageRelevantChanged");
    }

    //--------------------------------------------------------------------------

    function gotoPreviousPage() {
        if (!canGoto) {
            return;
        }

        if (currentIndex > 0) {
            currentIndex--;
        }
    }

    //--------------------------------------------------------------------------

    function gotoNextPage() {
        if (!canGoto) {
            return;
        }

        if (currentIndex < (count - 1)) {
            currentIndex++;
        }
    }

    //--------------------------------------------------------------------------

    function gotoPage(index) {
        if (!canGoto) {
            return;
        }

        if (index < 0 || index >= count) {
            console.error("gotoPage invalid index:", index, "count:", count);
            return;
        }

        currentIndex = index;
    }

    //--------------------------------------------------------------------------

    function gotoFirstPage() {
        gotoPage(0);
    }

    //--------------------------------------------------------------------------

    function gotoLastPage() {
        gotoPage(count - 1);
    }

    //--------------------------------------------------------------------------

    function relevantPages() {
        var count = 0;

        pages.forEach(function(page) {
            if (page.relevant) {
                count++;
            }
        });

        return count;
    }

    //--------------------------------------------------------------------------

    onCurrentIndexChanged: {
        if (!canGoto) {
            return;
        }

        currentPage = pages[currentIndex];

        pages.forEach(function(page) {
            page.hidden = page !== currentPage;
        });

        pageActivated();
    }

    //--------------------------------------------------------------------------
}
