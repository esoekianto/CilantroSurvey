import QtQuick 2.7
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "../template"

Rectangle {

    id: pictureChooserAndroid

    color: xform.style.backgroundColor

    property var pictureUrl
    property string path
    property var imageArray: []
    property bool noImages: true
    property int emulatedFolderCount: 100

    signal accepted(url fileUrl)
    signal rejected()

    // -------------------------------------------------------------------------

    Stack.onStatusChanged: {
        if (Stack.status === Stack.Active) {
            busyIndicator.running = true;
            getPaths();
        }
    }

    // -------------------------------------------------------------------------

    FileFolder {
        id: fileFolder
    }

    ExifInfo {
        id: fileExifInfo
    }

    FileInfo {
        id: fileInfo
    }

    // -------------------------------------------------------------------------

    ListModel {
        id: picturesModel
    }

    // -------------------------------------------------------------------------

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            Layout.alignment: Qt.AlignTop
            color: xform.style.titleBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: app.titleBarHeight

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    XFormImageButton {
                        anchors {
                            fill: parent
                            margins: 4 * AppFramework.displayScaleFactor
                        }
                        source: "images/back.png"
                        color: xform.style.titleTextColor
                        onClicked: {
                            rejected();
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    XFormImageButton {
                        anchors {
                            fill: parent
                            margins: 4 * AppFramework.displayScaleFactor
                        }
                        source: asc ? "images/sort-time-asc.png" : "images/sort-time-desc.png"
                        color: xform.style.titleTextColor
                        property bool asc: false
                        visible: !noImages
                        enabled: !noImages
                        onClicked: {
                            asc = !asc;
                            sort(asc);
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width
            Layout.maximumWidth: 600 * AppFramework.displayScaleFactor
            anchors.horizontalCenter: parent.horizontalCenter

            GridView {
                id: gridView
                anchors.fill: parent
                model: picturesModel
                focus: true
                clip: true

                cellWidth: gridView.width / 3
                cellHeight: gridView.width / 3

                delegate: Rectangle {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 5 * AppFramework.displayScaleFactor
                        }
                        color: "#eee"
                        Image {
                            id: thumbnail
                            anchors.fill: parent
                            source: url
                            asynchronous: true
                            autoTransform: true
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 200
                            sourceSize.height: 200
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    pictureUrl = url;
                                    pictureChooserAndroid.accepted(pictureUrl);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    AppBusyIndicator {
        id: busyIndicator
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: statusText.top
        }
    }

    Text {
        id: statusText
        anchors.centerIn: parent
        wrapMode: Text.Wrap
        maximumLineCount: 2
        color: xform.style.groupLabelColor
        font {
            family: xform.style.fontFamily
            weight: Font.Bold
            pointSize: xform.style.titlePointSize
        }
        visible: text > ""
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    // -------------------------------------------------------------------------

    function getPaths() {

        var androidImagePaths = [];

        // Test StandardPaths and subfolders -----------------------------------

        var standardPaths = AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation);

        for (var standardPath in standardPaths) {

            fileFolder.path = standardPaths[standardPath];

            if (fileFolder.exists) {
                androidImagePaths.push("file://" + standardPaths[standardPath]);
            }

            var standardPathsSubFolders = fileFolder.folderNames();

            if (standardPathsSubFolders.length > 0) {
                for (var subpath in standardPathsSubFolders) {
                    androidImagePaths.push("file://" + standardPaths[standardPath] + "/%1".arg(standardPathsSubFolders[subpath]));
                }
            }
        }

        // Test BasePath of /storage -------------------------------------------

        var basePath = "/storage";
        var paths = [];

        fileFolder.path = basePath;
        var basePathSubFolders = fileFolder.folderNames();

        // Get DCIM folders within storage paths -------------------------------

        for (var basePathSubFolder in basePathSubFolders) {

            var folderName = basePathSubFolders[basePathSubFolder];
            var pathToSearch = basePath + "/" + folderName + "/";

            if (folderName.search(/emulated/i) > -1) {
                var typicalAndroidEmulatedPath = pathToSearch + "0/DCIM";
                fileFolder.path = typicalAndroidEmulatedPath;
                if (fileFolder.exists) {
                    pathToSearch = typicalAndroidEmulatedPath;
                }
                else {
                    for (var pathCounter = 1; pathCounter < emulatedFolderCount + 1; pathCounter++) {
                        var pathToTest = pathToSearch + pathCounter.toString() + "/DCIM";
                        fileFolder.path = pathToTest;
                        if (fileFolder.exists) {
                            pathToSearch = pathToTest;
                            break;
                        }
                    }
                }
            }
            else {
                pathToSearch += "DCIM";
            }

            fileFolder.path = pathToSearch;

            if (fileFolder.exists) {
                paths.push(pathToSearch);
                androidImagePaths.push("file://" + pathToSearch);
            }
        }

        // Get folders within the DCIM folders ---------------------------------

        for (var storagePath in paths) {

            fileFolder.path = paths[storagePath];

            if (fileFolder.exists) {

                var subPathFolders = fileFolder.folderNames();

                if (subPathFolders.length > 0) {

                    for (var subPath in subPathFolders) {
                        var dcimSubFolderPath = "file://" + paths[storagePath]  + "/" + subPathFolders[subPath];
                        androidImagePaths.push(dcimSubFolderPath);
                    }
                }
            }
        }

        console.log("*-*-*-*-*-*-*-*-: ", JSON.stringify(androidImagePaths));

        // Get file paths from dcim folders ------------------------------------

        var firstFileName = [];
        var duplicate = false;

        for (var androidImagePath in androidImagePaths) {

            fileFolder.url = androidImagePaths[androidImagePath];
            var sourceFilesCurrent = fileFolder.fileNames();

            if (sourceFilesCurrent) {

                for (var sourceFile in sourceFilesCurrent) {

                    var file = sourceFilesCurrent[sourceFile];

                    if (file.search(/\.(jpeg|jpg|gif|png|tif|tiff)$/i) > -1){

                        // check for a duplicate first item in each array ------

                        if (sourceFile === 0) {
                            firstFileName.push(file);
                        }

                        if (firstFileName.length > 1 && sourceFile === 0) {
                            for (var fileName in firstFileName) {
                                if (firstFileName[fileName] === file) {
                                    duplicate = true;
                                    break;
                                }
                            }
                        }

                        if (duplicate) {
                            duplicate = false;
                            break;
                        }

                        // add path to the imageArray --------------------------

                        path = androidImagePaths[androidImagePath] + "/" + file;

                        fileInfo.filePath = AppFramework.urlInfo(path).path;
                        imageArray.push({"url": path, "name": file, "created": Date.parse(fileInfo.created)});
                    }
                }
            }
        }

        if (imageArray.length > 0) {
            statusText.text = "";
            sort(false);
            noImages = false;
        }
        else {
            statusText.text = qsTr("Sorry, no photos found.");
            noImages = true;
            busyIndicator.running = false;
        }

    }

    // -------------------------------------------------------------------------

    function sort(asc){
        // asc is oldest to newest
        imageArray = imageArray.sort(function(obj1, obj2) {
            if (asc) {
                return obj1.created - obj2.created;
            }
            else {
                return obj2.created - obj1.created;
            }
        });

        updateModel();
    }

    // -------------------------------------------------------------------------

    function updateModel(){
        picturesModel.clear();
        imageArray.forEach(function(obj){
            picturesModel.append(obj);
        });
        busyIndicator.running = false;
    }

    // End /////////////////////////////////////////////////////////////////////
}
