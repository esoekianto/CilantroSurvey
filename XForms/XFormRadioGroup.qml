import QtQuick 2.4

QtObject {
    property var value
    property var label
    property bool required
    readonly property string text: textValue(label) + (language ? "" : "")
    property bool valid: true

//    onValueChanged: console.log("RadioGroup: onValueChanged:", JSON.stringify(value));
//    onLabelChanged: console.log("RadioGroup: onLabelChanged:", JSON.stringify(label));
//    onTextChanged: console.log("RadioGroup: onTextChanged:", JSON.stringify(text));
}
