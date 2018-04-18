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

import ArcGIS.AppFramework 1.0

import "../XForms"

GalleryView {
    id: listView

    property string currentSurvey: (currentIndex >= 0 && currentIndex < count) ? getSurvey(currentIndex) : ""

    focus: true

    //--------------------------------------------------------------------------

    function getSurveyItem(index) {
        if (model.items) {
            var items = model.items;
            if (index < items.count) {
                return model.items.get(index).model;
            } else {
                console.error("index out of range:", index, ">=", items,count);
                return null;
            }
        } else {
            return model.get(index);
        }
    }

    //--------------------------------------------------------------------------

    function getSurvey(index) {
        var surveyItem = getSurveyItem(index);

        if (surveyItem) {
            return surveyItem.survey;
        } else {
            return "";
        }
    }

    //--------------------------------------------------------------------------
}
