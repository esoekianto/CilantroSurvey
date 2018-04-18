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

import ArcGIS.AppFramework 1.0

FileFolder {
    id: xformsFolder

    property var forms: []

    /*
    property FileSystemWatcher fileSystemWatcher: FileSystemWatcher {
        id: fileSystemWatcher
        paths: [ path ]

        onFolderChanged: {
            console.log("Folder change detected:", path);
            update();
        }
    }
    */
    
    path: "~/ArcGIS/XForms"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
//        fileSystemWatcher.paths = [ path ];
        update();
    }

    //--------------------------------------------------------------------------

    onPathChanged: {
        update();
    }

    //--------------------------------------------------------------------------

    function update() {

        console.log("Refreshing surveys:", path);

        var forms = [];

        var files = fileNames("*", true);
        files.forEach(function(fileName) {
            if (fileInfo(fileName).suffix === "xml") {
                forms.push(fileName);
            }
        });

//        console.log("forms:", path, JSON.stringify(forms, undefined, 2));

        xformsFolder.forms = forms;
    }

    //--------------------------------------------------------------------------

    function uniqueName() {
        var index = 1;
        var name;

        do {
            name = qsTr("Survey %1").arg(index);
            index++;
        }
        while (surveysFolder.fileExists(name));

        return name;
    }

    //--------------------------------------------------------------------------
}
