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

.pragma library

//------------------------------------------------------------------------------

var dpi = 203;
var pageWidthDots = 384;

var fontNames = [
            "Standard",
            "Script",
            "OCR-A",
            ,
            "Unison",
            "Manhattan",
            "MICR",
            "Warwick"
        ];

var fontHeights = [
            [9, 9, 18, 18, 18, 36, 36,  ],
            [48, , , , , , ,  ],
            [12, 24, , , , , , ],
            [, , , , , , , ],
            [47, 94, 45, 90, 180,, 270, 360, 450],
            [24, 48, 46, 92, , , , ],
            [27, , , , , , , ],
            [24, 48, , , , , , ]
        ];

var cclKey = "!";

//------------------------------------------------------------------------------

var sendLine = function (text) {
    console.log("CPCL.sendLine:", text);
}

function setSendLine(fn) {
    sendLine = fn;
}

//--------------------------------------------------------------------------

function inchDots(inches) {
    return Math.round(inches * dpi);
}

function mmDots(mm) {
    return Math.round(mm / 25.4 * dpi);
}

//--------------------------------------------------------------------------

function sendCommand(text) {
    sendLine(cclKey + " " + text);
}

//--------------------------------------------------------------------------

function beginPage() {
    sendCommand("U1 BEGIN-PAGE");
}

//--------------------------------------------------------------------------

function endPage() {
    sendCommand("U1 END-PAGE");
}

//--------------------------------------------------------------------------

function setFont(font, size, height) {
    if (!font) {
        font = 0;
    }

    if (!size) {
        size = 0;
    }

    if (!height) {
        height = fontHeights[font][size];
    }

    if (!height) {
        console.error("setFont: Invalid font", font, size, height);
    }

    sendCommand("U1 SETLP " + font.toString() + " " + size.toString() + " " + height.toString());
}

//--------------------------------------------------------------------------

function setBold(boldness) {
    if (!boldness) {
        boldness = 0;
    }

    sendCommand("U1 SETBOLD " + boldness.toString());
}

//--------------------------------------------------------------------------

function startLabel(height, copies) {
    if (!height) {
        height = mmDots(10);
    }

    if (!copies) {
        copies = 1;
    }

    sendCommand("0 " + dpi.toString() + " " + dpi.toString() + " " + height.toString() + " " + copies.toString());
}

function endLabel() {
    sendLine("PRINT");
}

//--------------------------------------------------------------------------

function text(font, size, x, y, text) {
    sendLine("TEXT " + font.toString() + " " + size.toString() + " " + x.toString() + " " + y.toString() + " " + text);
}

function scaleToFit(font, width, height, x, y, text) {
    if (!width) {
        width = pageWidthDots;
    }

    if (!height) {
        height = mmDots(10);
    }

    if (!x) {
        x = 0;
    }

    if (!y) {
        y = 0;
    }

    sendLine("SCALE-TO-FIT " + font.toString() + " " + width.toString() + " " + height.toString() + " " + x.toString() + " " + y.toString() + " " + text);
}

//--------------------------------------------------------------------------

function box(x0, y0, x1, y1, width) {
    if (!x0) x0 = 0;
    if (!y0) y0 = 0;
    if (!x1) x1 = pageWidthDots;
    if (!y1) y1 = mmDots(10);
    if (!width) width = 2;

    sendLine("BOX " + x0.toString() + " " + y0.toString() + " " + x1.toString() + " " + y1.toString() + " " + width.toString());
}

//--------------------------------------------------------------------------

function printHLine(height) {
    if (!height) height = 2;

    startLabel(height * 2);
    box(0, 0, undefined, height, height);
    endLabel();
}

//------------------------------------------------------------------------------

function printBarcode(value, style) {
    if (!(value > "")) {
        return;
    }

    switch (style.type) {
    case "qr":
        printQRCode(value);
        break;

    case undefined:
    case null:
        sendLine(value);
        break;

    default:
        print1DBarcode(value, style);
        break;
    }
}

//------------------------------------------------------------------------------

function print1DBarcode(value, style) {
    startLabel(80);
    sendLine("CENTER");
    sendLine("BARCODE-TEXT 7 0 5");
    sendLine("BARCODE 128 1 1 50 0 0 " + value);
    sendLine("BARCODE-TEXT OFF");
    endLabel();
}

//------------------------------------------------------------------------------

function printQRCode(value) {
    startLabel(300);
    sendLine("TEXT 7 0 0 0 " + value)
    sendLine("BARCODE QR 0 30 M 2 U 8");
    sendLine("MA," + value);
    sendLine("ENDQR");
    endLabel();
}

//------------------------------------------------------------------------------

function test() {
    beginPage()
    sendLine("Printer Test");
    sendLine("dpi: " + dpi.toString());
    sendLine("pageWidthDots:" + pageWidthDots);
    endPage();

    sendLine('\x1bh');
    sendLine('\x1bV\x1bh');
}

//------------------------------------------------------------------------------

function reset() {
    sendLine("");
    sendCommand('U1 do "device.reset" ""');
    sendLine('\x1bh');
}

//------------------------------------------------------------------------------

function dumpFonts() {
    for (var f = 0; f < fontHeights.length; f++) {
        var font = fontHeights[f];
        for (var h = 0; h < font.length; h++) {
            var height = font[h];
            if (height === undefined) {
                continue;
            }

            setFont(f, h);
            sendLine(f.toString() + " " + h.toString() + " " + fontNames[f]);
        }
    }
}

//--------------------------------------------------------------------------

function printSurvey(printObject) {
    console.log("Printing...");

    beginPage();
    printHLine(4);
    setBold(0);
    setFont(4, 0);
    sendLine(printObject.title);

    printObject.printFields.forEach(function (printField) {
        setBold(0);
        setFont(7, 0);
        sendLine(printField.printLabel + ":");

        setBold(0);
        setFont(7, 1);

        switch (printField.type) {
        case "barcode":
            printBarcode(printField.printValue, printField.printStyle);
            break;

        default:
            sendLine(printField.printValue);
            break;
        }
    });

    printHLine(4);

    sendLine();
    endPage();
}

//------------------------------------------------------------------------------
