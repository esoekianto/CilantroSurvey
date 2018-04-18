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
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import "../Portal"

Button {
    property Portal portal
    property bool isSignedIn: portal ? portal.signedIn : false
    property string username: portal && portal.user ? portal.user.username : ""
    property Dialog dialog

    text: isSignedIn ? qsTr("Sign out") : qsTr("Sign in")
    tooltip: isSignedIn
             ? qsTr("Sign out ") + username
             : qsTr("Sign in to ArcGIS Online")
    
    enabled: AppFramework.network.isOnline || isSignedIn

    style: ButtonStyle {
        padding {
            left: 10 * AppFramework.displayScaleFactor
            right: 10 * AppFramework.displayScaleFactor
        }

        label: Text {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: control.enabled ? (!isSignedIn ? "white" : "dimgray") : "gray"
            text: control.text
            font {
                pointSize: 13
                capitalization: Font.AllUppercase
            }
        }
        
        background: Rectangle {
            color: (control.hovered | control.pressed)
                   ? (!isSignedIn ? "#e36b00" : "darkgray")
                   : (!isSignedIn ? "#e98d32" : "lightgray")
            border {
                color: control.activeFocus
                       ? (!isSignedIn ? "#e36b00" : "darkgray")
                       : "transparent"
                width: control.activeFocus ? 2 : 1
            }
            radius: 4
            implicitWidth: 110
        }
    }
    
    onClicked: {
        if (portal) {
            if (isSignedIn) {
                portal.signOut();
            } else {
                if (dialog) {
                    dialog.open();
                }
            }
        } else {
            console.error("portal not set");
        }
    }
}
