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

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtMultimedia 5.5

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Multimedia 1.0

GroupBox {
    id: audioControl

    property var binding
    property var mediatype
    property XFormData formData

    property var formElement

    property FileFolder audioFolder: xform.attachmentsFolder
    property alias audioPath: audioFileInfo.filePath
    property url audioUrl
    property string audioPrefix: "Audio"

    property int recordLimit: 120
    property alias sampleRate: audioRecorder.sampleRate

    property bool readOnly: false

    readonly property bool relevant: parent.relevant

    readonly property int buttonSize: 35 * AppFramework.displayScaleFactor

    readonly property bool hasAudio: audioUrl > ""
    readonly property bool isRecording: audioRecorder.state == AudioRecorder.RecordingState
    readonly property bool isPlaying: audio.playbackState == Audio.PlayingState || audio.playbackState == Audio.PausedState
    readonly property bool isPlayingPaused: audio.playbackState == Audio.PausedState
    readonly property int audioTime: isRecording
                                     ? (audioRecorder.status == AudioRecorder.RecordingStatus ? audioRecorder.duration : -1)
                                     : isPlaying
                                       ? audio.position
                                       : audio.hasAudio ? audio.duration : -1

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    flat: true

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        audioPrefix = binding["@nodeset"];
        var i = audioPrefix.lastIndexOf("/");
        if (i >= 0) {
            audioPrefix = audioPrefix.substr(i + 1);
        }

        console.log("audio prefix:", audioPrefix);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (!relevant) {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {

        width: parent.width

        RowLayout {
            Layout.fillWidth: true

            spacing: buttonSize / 2

            Text {
                visible: hasAudio || isRecording

                text: timeText(audioTime)
                font {
                    pixelSize: parent.height * 0.8
                }

                MouseArea {
                    anchors.fill: parent

                    onPressAndHold: {
                        audioFormatText.visible = !audioFormatText.visible;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: !hasAudio && !readOnly && !isRecording
                source: "images/microphone.png"
                enabled: audioRecorder.available && !isPlaying
                color: xform.style.iconColor
                opacity: audioRecorder.available ? 1 : 0.25

                onClicked: {
                    console.log("Start recording");
                    audioRecorder.started = false;
                    audioTimer.elapsed = 0;
                    audioRecorder.record();
                }

                onPressAndHold: {
                    audioInfoText.visible = true;
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: hasAudio && audio.hasAudio
                source: isPlaying ? "images/action_pause.png" : "images/action_play.png"
                enabled: audioRecorder.state == AudioRecorder.StoppedState && audioUrl > "" && audio.duration > 0
                color: xform.style.iconColor

                onClicked: {
                    if (isPlayingPaused || !isPlaying) {
                        audio.play();
                    } else {
                        audio.pause();
                    }
                }

                onPressAndHold: {
                    audioInfoText.visible = true;
                }
            }

            XFormImageButton {
                id: stopButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/action_stop.png"
                visible: isRecording || isPlaying
                color: xform.style.iconColor

                onClicked: {
                    if (isRecording) {
                        recordLimitTimer.stop();
                        audioTimer.stop();
                        audioRecorder.stop();
                    } else if (isPlaying) {
                        audio.stop();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: hasAudio && !readOnly
                source: "images/trash.png"
                enabled: !(isPlaying || isRecording)
                color: xform.style.deleteIconColor

                onClicked: {
                    var name = audioFolder.fileInfo(audioPath).fileName;

                    var panel = confirmPanel.createObject(app, {
                                                              iconColor: "#a9d04d",
                                                              title: qsTr("Confirm Audio Delete"),
                                                              question: qsTr("Are you sure you want to delete %1?").arg(name)
                                                          });

                    panel.show(deleteAudio, undefined);
                }

                function deleteAudio() {
                    audioFolder.removeFile(audioPath);
                    setValue(null);
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            active: isRecording
            visible: active

            sourceComponent: XFormProgressBar {
                minimumValue: 0
                maximumValue: recordLimitTimer.interval
                value: audioTimer.elapsed
            }
        }

        Loader {
            Layout.fillWidth: true

            active: isPlaying
            visible: active

            sourceComponent: XFormProgressBar {
                minimumValue: 0
                maximumValue: audio.duration
                value: audio.position
            }
        }

        XFormFileRenameControl {
            id: renameControl

            Layout.fillWidth: true

            visible: audioUrl > ""
            fileName: audioFileInfo.fileName
            fileFolder: audioFolder
            readOnly: audioControl.readOnly

            onRenamed: {
                audioPath = audioFolder.filePath(newFileName);
                audioUrl = audioFolder.fileUrl(newFileName);
                updateValue();
            }
        }

        Text {
            id: audioErrorText

            Layout.fillWidth: true

            visible: hasAudio && audio.error > Audio.NoError
            color: xform.style.inputErrorTextColor
            text: "Error %1 %2".arg(audio.error).arg(audio.errorString)

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            id: audioInfoText

            Layout.fillWidth: true

            visible: false

            text: hasAudio
                  ? "%1Kb".arg(Math.round(audioFileInfo.size/1024))
                  : "%1 (%2Hz %3) %4s".arg(audioRecorder.inputDescription).arg(audioRecorder.sampleRate).arg(audioRecorder.containerFormatDescription).arg(recordLimit)
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
        }
    }

    //--------------------------------------------------------------------------

    AudioRecorder {
        id: audioRecorder

        property bool started: false

        //outputLocation: audioFolder.path
        sampleRate: 22050

        onStatusChanged: {
            console.log("audioRecorder status:", status);

            switch (status) {
            case AudioRecorder.UnloadedStatus:
            case AudioRecorder.LoadedStatus:
                if (started) {
                    finalizeRecording();
                }
                break;

            case AudioRecorder.RecordingStatus:
                started = true;
                recordLimitTimer.start();
                audioTimer.start();
                console.log("Recording to outputLocation:", audioRecorder.outputLocation);
                break;
            }
        }

        onStateChanged: {
            console.log("audioRecorder state:", state);
        }

        onErrorChanged: {
            console.log("audioRecorder error:", error, "errorString:", errorString);
        }
    }


    Timer {
        id: recordLimitTimer

        interval: recordLimit * 1000
        repeat: false
        triggeredOnStart: false

        onTriggered: {
            console.warn("Record limit reached");
            stopButton.clicked();
        }
    }

    Timer {
        id: audioTimer

        property int elapsed

        interval: 100
        repeat: true

        onTriggered: {
            elapsed += interval;
        }
    }

    function finalizeRecording() {

        console.log("audio actualLocation:", audioRecorder.actualLocation);

        var sourceFileInfo = AppFramework.fileInfo(audioRecorder.actualLocation);
        var fileName = audioPrefix + "-" + AppFramework.createUuidString(2) + "." + sourceFileInfo.suffix;
        var filePath = audioFolder.filePath(fileName);

        if (audioFolder.fileExists(fileName)) {
            console.log("Removing existing audio file:", filePath);
            if (!audioFolder.removeFile(fileName)) {
                console.error("Unable to remove:", filePath);
                return;
            }
        }

        console.log("Renaming recording:", sourceFileInfo.filePath, "to:", filePath);

        if (sourceFileInfo.folder.renameFile(sourceFileInfo.fileName, filePath)) {
            audioFileInfo.filePath = filePath;
            audioUrl = audioFileInfo.url;
            updateValue();
        } else {
            console.error("Error renaming audio file");
        }

        //                        console.log("Copying:", sourceFileInfo.filePath, "to:", filePath);

        //                        if (sourceFileInfo.folder.copyFile(sourceFileInfo.fileName, filePath)) {
        //                            audioFileInfo.filePath = filePath;;
        //                            audioUrl = audioFileInfo.url;
        //                            updateValue();

        //                            if (!sourceFileInfo.folder.removeFile(sourceFileInfo.fileName)) {
        //                                console.error("Error deleting source file:", sourceFileInfo.filePath);
        //                            }
        //                        } else {
        //                            console.error("Error copying audio file");
        //                        }

    }
    //--------------------------------------------------------------------------

    Audio {
        id: audio

        source: audioUrl

        onStatusChanged: {
            console.log("audio status:", status);
        }

        onError: {
            console.log("audio error:", error, "errorString:", errorString, "source:", source);
        }
    }

    //--------------------------------------------------------------------------

    FileInfo {
        id: audioFileInfo
    }

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            fontFamily: xform.style.fontFamily
        }
    }

    //--------------------------------------------------------------------------

    function timeText(ms) {
        if (ms < 0) {
            return "--:--";
        }

        var minutes = Math.floor(ms / 60000);
        var seconds = Math.floor((ms - minutes * 60000) / 1000);

        function zNum(n) {
            return n < 10 ? "0" + n.toString() : n.toString();
        }

        return "%1:%2".arg(zNum(minutes)).arg(zNum(seconds));
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        var audioName = audioFileInfo.fileName;
        console.log("audio-updateValue", audioName);

        formData.setValue(binding, audioName);

        xform.controlFocusChanged(this, false, binding);
    }

    //--------------------------------------------------------------------------

    function setValue(value, unused, metaValues) {
        if (metaValues) {
            var editMode = metaValues[formData.kMetaEditMode];
            console.log("audio-editMode:", editMode);

            readOnly = editMode > formData.kEditModeAdd;
        } else {
            readOnly = false;
        }

        console.log("audio-setValue:", value, "readOnly:", readOnly);

        if (value > "") {
            audioPath = audioFolder.filePath(value);
            audioUrl = audioFolder.fileUrl(value);
        } else {
            audioPath = "";
            audioUrl = "";
        }

        formData.setValue(binding, value);
    }

    //--------------------------------------------------------------------------
}
