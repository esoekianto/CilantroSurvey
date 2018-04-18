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

import QtQuick 2.3

Item {
    property alias model: itemsModel

    property var items: []
    property XFormItemset itemset
    property bool blankItem: false
    readonly property string blankText: qsTr("<Blank>")

    signal filterChanged();

    ListModel {
       id: itemsModel
    }

    //--------------------------------------------------------------------------

    Connections {
        target: itemset

        onFilteredItemsChanged: {
            items = itemset.filteredItems;

            filterChanged();
        }
    }

    onItemsChanged: {
        refresh();
    }

    onBlankItemChanged: {
        refresh();
    }

    //--------------------------------------------------------------------------

    function refresh() {
        model.clear();

        for (var i = 0; items && i < items.length; i++) {
            var item = items[i];

            model.append({
                       nameValue: {
                           "value": item.value,
                           "label": item.label
                       },
                       "text": textValue(item.label)
                   });
        }

        if (blankItem) {
            model.insert(0,
                   {
                       nameValue: {
                           "value": undefined,
                           "label": ""
                       },
                       "text": blankText
                   });
        }
    }

    //--------------------------------------------------------------------------

    function refreshText() {
        for (var i = 0; i < count; i++) {
            var item = model.get(i);
            if (item.nameValue.label > "") {
                item.text = textValue(item.nameValue.label);
                model.set(i, item);
            }
        }
    }

    //--------------------------------------------------------------------------
}
