/* Copyright 2017 Esri
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

function detectSketch(points) {

    //console.log("detecting sketch:", JSON.stringify(points));

    if (!Array.isArray(points)) {
        return;
    }

    if (points.length < 2) {
        return;
    }

    //    var si = selfIntersects(points);

    //    console.log("Self intersects");
    //    var extent = SketchLib.extent(polyline);
    //    if (extent.xyAspect > 0.3 && extent.yxAspect > 0.3) {
    //        textInput.show(extent.center.x, extent.center.y);
    //    }

    var result = detectLineSketch(points);

    if (!result) {
        result = detectArrowSketch(points);
    }

    if (!result) {
        result = detectRectangleSketch(points);
    }

    if (!result) {
        result = detectEllipseSketch(points);
    }

    console.log("detectSketch:", JSON.stringify(result, undefined, 2));

    return result;
}

//------------------------------------------------------------------------------

function detectLineSketch(points) {

    // https://www.varsitytutors.com/hotmath/hotmath_help/topics/line-of-best-fit


    var xSum = 0;
    var ySum = 0;

    points.forEach(function (vertex) {
        xSum += vertex.x;
        ySum += vertex.y;
    });

    var n = points.length;

    var _x = xSum / n;
    var _y = ySum / n;

    var dxdySum = 0;
    var dx2Sum = 0;

    points.forEach(function (vertex) {
        var dx = (vertex.x - _x);
        dxdySum += dx * (vertex.y - _y);
        dx2Sum += dx * dx;
    });


    var m = dxdySum / dx2Sum;
    var c = _y - m * _x;

    function fx(x) {
        return m * x + c;
    }

    function fy(y) {
        return (y - c) / m;
    }

    var a = m;
    var b = -1;

    function fdxy(x, y) {
        return (a * x + b * y + c) / Math.sqrt(a * a + b * b);
    }


    var x1 = points[0].x;
    var y1 = fx(x1);
    var x2 = points[points.length - 1].x;
    var y2 = fx(x2);

    var l = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));

    console.log("line: y = ", m, "* x +", c, "l=", l);

    var q = 0;

    points.forEach(function (vertex) {
        var d = Math.abs(fdxy(vertex.x, vertex.y));
        q = Math.max(q, d / l);
    });


    var result  = {
        type: "line",
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        length: l,
        q: q,
        a: Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI + 90,
        center: {
            x: (x2 + x1) / 2,
            y: (y2 + y1) / 2
        }
    };

    return result;
}

//------------------------------------------------------------------------------

function beginArrowSketch(x, y) {
    return {
        type: "arrow",
        x1: x,
        y1: y,
        x2: x,
        y2: y,
        length: 0,
        q: 0,
        a: 0
    };
}

//------------------------------------------------------------------------------

function updateArrowSketch(sketch, x, y) {
    sketch.x2 = x;
    sketch.y2 = y;
    sketch.length = Math.sqrt((sketch.x2 - sketch.x1) * (sketch.x2 - sketch.x1) + (sketch.y2 - sketch.y1) * (sketch.y2 - sketch.y1));
    sketch.a = Math.atan2(sketch.y2 - sketch.y1, sketch.x2 - sketch.x1) * 180 / Math.PI + 90;
}

//------------------------------------------------------------------------------

function detectArrowSketch(points) {

    var result;


    return result;
}

//------------------------------------------------------------------------------

function detectRectangleSketch(points) {

    var result;


    return result;
}

//------------------------------------------------------------------------------

function detectEllipseSketch(points) {

    var result;


    return result;
}

//--------------------------------------------------------------------------

function drawSketches(ctx, sketches) {
    if (!Array.isArray(sketches)) {
        return;
    }

    sketches.forEach(function (sketch) {
        drawSketch(ctx, sketch);
    });
}

//--------------------------------------------------------------------------

function drawSketch(ctx, sketch) {
    if (!sketch) {
        return;
    }

    // console.log("drawSketch:", JSON.stringify(sketch, undefined, 2));


    switch (sketch.type) {
    case "line":
        drawLineSketch(ctx, sketch);
        break;

    case "polyline":
        drawPolylineSketch(ctx, sketch);
        break;

    case "polygon":
        drawPolygonSketch(ctx, sketch);
        break;

    case "arrow":
        drawArrowSketch(ctx, sketch);
        break;

    case "rectangle":
        drawRectangleSketch(ctx, sketch);
        break;

    case "ellipse":
        drawEllipseSketch(ctx, sketch);
        break;

    case "text":
        drawTextSketch(ctx, sketch);
        break;

    case "image":
        drawImageSketch(ctx, sketch);
        break;

    default:
        console.warn("Unknown sketch type:", sketch.type);
        break;
    }
}

//------------------------------------------------------------------------------

function drawLineSketch(ctx, sketch) {
    ctx.save();

    ctx.beginPath();

    ctx.strokeStyle = sketch.lineColor;
    ctx.lineWidth = sketch.lineWidth;
    ctx.lineCap = "round";

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.lineColor, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }

    ctx.moveTo(sketch.x1, sketch.y1);
    ctx.lineTo(sketch.x2, sketch.y2);

    ctx.stroke();

    ctx.restore();
}

//------------------------------------------------------------------------------

function drawPolylineSketch(ctx, sketch) {
    ctx.save();

    ctx.strokeStyle = sketch.lineColor;
    ctx.lineWidth = sketch.lineWidth;
    ctx.lineCap = "round";

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.lineColor, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }

    drawSmoothLine(ctx, sketch.points);

    ctx.restore();
}

//------------------------------------------------------------------------------

function drawPolygonSketch(ctx, sketch) {
    ctx.save();

    ctx.strokeStyle = sketch.lineColor;
    ctx.lineWidth = sketch.lineWidth;
    ctx.lineCap = "round";

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.lineColor, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }

    ctx.restore();
}

//------------------------------------------------------------------------------

function drawArrowSketch(ctx, sketch) {
    ctx.save();

    ctx.beginPath();

    ctx.strokeStyle = sketch.lineColor;
    ctx.lineWidth = sketch.lineWidth;
    ctx.lineCap = "butt";

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.lineColor, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }

    ctx.moveTo(sketch.x1, sketch.y1);
    ctx.lineTo(sketch.x2, sketch.y2);

    var a = (sketch.a - 180 + sketch.headAngle - 90) * Math.PI / 180;

    var x3 = sketch.x2 + sketch.headLength * Math.cos(a);
    var y3 = sketch.y2 + sketch.headLength * Math.sin(a);

    ctx.moveTo(x3, y3);
    ctx.lineTo(sketch.x2, sketch.y2);

    a = (sketch.a - 180 - sketch.headAngle - 90) * Math.PI / 180;

    x3 = sketch.x2 + sketch.headLength * Math.cos(a);
    y3 = sketch.y2 + sketch.headLength * Math.sin(a);

    ctx.lineTo(x3, y3);

    ctx.stroke();

    ctx.restore();
}

//------------------------------------------------------------------------------

function drawRectangleSketch(ctx, sketch) {
    ctx.save();

    ctx.beginPath();

    ctx.strokeStyle = sketch.lineColor;
    ctx.lineWidth = sketch.lineWidth;
    ctx.lineCap = "butt";

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.lineColor, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }

    ctx.strokeRect(sketch.xMin, sketch.yMin, sketch.width, sketch.height);

    /*
    var w2 = sketch.width / 2;
    var h2 = sketch.height / 2;

    ctx.translate(sketch.xMin + w2, sketch.yMin + h2);
    ctx.rotate(radians(sketch.indicativeAngle - 45));

    ctx.strokeRect(-w2, -h2, sketch.width, sketch.height);
*/

    ctx.restore();
}

//------------------------------------------------------------------------------

function drawEllipseSketch(ctx, sketch) {
    ctx.save();

    ctx.beginPath();

    ctx.strokeStyle = sketch.lineColor;
    ctx.lineWidth = sketch.lineWidth;

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.color, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }

    ctx.ellipse(sketch.xMin, sketch.yMin, sketch.width, sketch.height);

    ctx.stroke();

    ctx.restore();
}

//------------------------------------------------------------------------------

function drawImageSketch(ctx, sketch) {
    var source = sketch.url;

    var x = sketch.x;
    var y = sketch.y;
    var width = sketch.width;
    var height = sketch.height;
    var canvas = ctx.canvas;

    if (sketch.fit) {
        var canvasRatio = canvas.width / canvas.height;
        var imageRatio = sketch.width / sketch.height;

        var scaleFactor = 1;

//        if (Qt.platform.os === "osx" || Qt.platform.os === "ios") {
//            scaleFactor = Screen.devicePixelRatio;
//            console.warn("Using Qt canvas bug workaround scaleFactor:", scaleFactor);
//        }

        if (imageRatio < canvasRatio) {
            height = canvas.height * scaleFactor;
            width = height * imageRatio;
        } else {
            width = canvas.width * scaleFactor;
            height = width / imageRatio;
        }

        x = (canvas.width - width / scaleFactor) / 2;
        y = (canvas.height - height / scaleFactor) / 2;
    }

    ctx.drawImage(source, x, y, width, height);
}

//------------------------------------------------------------------------------

function drawTextSketch(ctx, sketch) {
    ctx.save();
    ctx.font = sketch.font;
    ctx.translate(sketch.x, sketch.y);

    var alignment = sketch.alignment;

    var a = sketch.angle;
    if (((a + 450) % 360) > 180) {
        a -= 180;
        if (!alignment) {
            alignmnet = "right";
        }
    }

    if (!alignment) {
        alignment = "left";
    }

    ctx.textAlign = alignment;

    var baseline = sketch.baseline;
    if (!baseline) {
        baseline = "bottom";
    }

    ctx.textBaseline = baseline;

    ctx.rotate(a * Math.PI / 180);

    ctx.fillStyle = sketch.color;

    if (sketch.shadowBlur) {
        ctx.shadowColor = contrastColor(sketch.color, "#808080");
        ctx.shadowBlur = sketch.shadowBlur;
    }
    //ctx.strokeStyle = contrastColor(sketch.color);

    if (sketch.maximumWidth) {
        wrapText(ctx, sketch.text, 0, 0, sketch.maximumWidth, sketch.height);
    } else {
        ctx.fillText(sketch.text, 0, 0);//sketch.x, sketch.y);
        //ctx.strokeText(sketch.text, 0, 0);//sketch.x, sketch.y);
    }


    ctx.restore();
}

//------------------------------------------------------------------------------

function wrapText(ctx, text, x, y, maxWidth, lineHeight) {
    var lines = text.split("\n");

    lines.forEach(function (line) {
        var textLine = "";
        var words = line.split(" ");

        words.forEach(function (word) {
            var testLine = textLine + word + " ";
            var metrics = ctx.measureText(testLine);
            var testWidth = metrics.width;

            if (testWidth > maxWidth) {
                ctx.fillText(textLine, x, y);
                textLine = word + " ";
                y += lineHeight;
            }
            else {
                textLine = testLine;
            }
        });

        ctx.fillText(textLine, x, y);
        //ctx.strokeText(textLine, x, y);

        y += lineHeight;
    });
}

//------------------------------------------------------------------------------

function drawLine(ctx, points) {

    if (!Array.isArray(points)) {
        return;
    }

    if (points.length < 2) {
        return;
    }

    ctx.beginPath();

    for (var i = 0; i < points.length; i++) {
        var point = points[i];
        if (point.x < 0 && point.y < 0) {
            ctx.moveTo(-point.x, -point.y);
        } else {
            ctx.lineTo(point.x, point.y);
        }
    }

    ctx.stroke();
}

//------------------------------------------------------------------------------

function drawSmoothLine(ctx, points) {
    if (!Array.isArray(points)) {
        return;
    }

    if (points.length < 4) {
        return;
    }

    ctx.beginPath();

    ctx.moveTo(points[0].x, points[0].y);

    for (var i = 1; i < points.length - 2; i ++)
    {
        var xc = (points[i].x + points[i + 1].x) / 2;
        var yc = (points[i].y + points[i + 1].y) / 2;
        ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
    }

    ctx.quadraticCurveTo(points[i].x, points[i].y, points[i+1].x,points[i+1].y);

    ctx.stroke();
}

//------------------------------------------------------------------------------

function toFontString(font, points) {
    if (!font) {
        return;
    }

    var fontString = "%1 %2 %3px \"%4\""
    .arg(font.italic ? "italic" : "normal")
    .arg(font.bold ? "bold" : "normal")
    .arg(points ? font.pointSize : font.pixelSize)
    .arg(font.family);

    // console.log("fontString:", fontString);

    return fontString;
}

//------------------------------------------------------------------------------

function extent(points) {
    if (!Array.isArray(points)) {
        return;
    }

    var e = {
        count: points.length
    };

    var xSum = 0;
    var ySum = 0;

    points.forEach(function(point) {
        xSum += point.x;
        ySum += point.y;

        if (e.xMin === undefined || point.x < e.xMin) {
            e.xMin = point.x;
        }
        if (e.yMin === undefined || point.y < e.yMin) {
            e.yMin = point.y;
        }
        if (e.xMax === undefined || point.x > e.xMax) {
            e.xMax = point.x;
        }
        if (e.yMax === undefined || point.y > e.yMax) {
            e.yMax = point.y;
        }
    });

    e.width = e.xMax - e.xMin;
    e.height = e.yMax - e.yMin;
    e.xyAspect = e.width / e.height;
    e.yxAspect = e.height / e.width;

    e.center = {
        x: e.xMin + e.width / 2,
        y: e.yMin + e.height / 2
    };

    e.centroid = {
        x: xSum / points.length,
        y: ySum / points.length
    }

    e.indicativeAngle = degrees(Math.atan2(e.centroid.y - points[0].y, e.centroid.x - points[0].x));

    console.log("extent:", JSON.stringify(e, undefined, 2));

    return e;
}

//------------------------------------------------------------------------------

function degrees(a) {
    return ((a * 180 / Math.PI) + 360) % 360;
}

function radians(a) {
    return a * Math.PI / 180;
}

//------------------------------------------------------------------------------

function createRectangleSketch(points) {
    var e = extent(points);

    return {
        type: "rectangle",
        xMin: e.xMin,
        yMin: e.yMin,
        xMax: e.xMax,
        yMax: e.yMax,
        width: e.width,
        height: e.height,
        indicativeAngle: e.indicativeAngle,
        a: 90,
        center: {
            x: (e.xMin + e.xMax) / 2,
            y: (e.yMin + e.yMax) / 2,
        }
    }
}

//------------------------------------------------------------------------------

function createEllipseSketch(points) {
    var e = extent(points);

    return {
        type: "ellipse",
        xMin: e.xMin,
        yMin: e.yMin,
        xMax: e.xMax,
        yMax: e.yMax,
        width: e.width,
        height: e.height,
        indicativeAngle: e.indicativeAngle,
        a: 90,
        center: {
            x: (e.xMin + e.xMax) / 2,
            y: (e.yMin + e.yMax) / 2,
        }
    }
}

//------------------------------------------------------------------------------

function createArrowSketch(points) {
    var sketch = detectLineSketch(points);

    sketch.type = "arrow";
    sketch.headLength = sketch.length * 0.10;
    sketch.headAngle = 30;

    return sketch;
}

//------------------------------------------------------------------------------

function hex2rgba(color, factor) {
    var hex = Qt.lighter(color, 1).toString();

    var a = 255;
    var r = 128;
    var g = 128;
    var b = 128;

    var aOffset = 0;
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) {
        result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        if (result) {
            aOffset  = 1;
            a = parseInt(result[1], 16);
        }
    }

    if (result) {
        r = parseInt(result[1 + aOffset], 16);
        g = parseInt(result[2 + aOffset], 16);
        b = parseInt(result[3 + aOffset], 16);
    }

    if (!factor) {
        factor = 1;
    }

    return {
        a: a / factor,
        r: r / factor,
        g: g / factor,
        b: b / factor
    }
}

//------------------------------------------------------------------------------

function contrastColor(color, darkColor, lightColor) {

    function contrast(color) {
        var rgb = hex2rgba(color);
        return (Math.round(rgb.r * 299) + Math.round(rgb.g * 587) + Math.round(rgb.b * 114)) / 1000;
    }

    return (contrast(color) >= 128) ? (darkColor || 'black') : (lightColor || 'white');
}

//------------------------------------------------------------------------------
// Precise method, which guarantees v = v1 when s = 1

function lerp(v0, v1, s) {
    return (1 - s) * v0 + s * v1;
}

//------------------------------------------------------------------------------

function interpolateColor(color1, color2, s) {
    if (s <= 0) {
        return color1;
    } else if (s >= 1) {
        return color2;
    }

    var rgb1 = hex2rgba(color1, 255);
    var rgb2 = hex2rgba(color2, 255);

    var r = lerp(rgb1.r, rgb2.r, s);
    var g = lerp(rgb1.g, rgb2.g, s);
    var b = lerp(rgb1.b, rgb2.b, s);
    var a = lerp(rgb1.a, rgb2.a, s);

    return Qt.rgba(r, g, b, a);
}

//------------------------------------------------------------------------------

function interpolateColors(colors, s) {
    if (!Array.isArray(colors)) {
        console.error("Not an array:", colors);
        return;
    }

    var iMax = colors.length;

    if (s <= 0) {
        return colors[0];
    } else if (s >= 1) {
        return colors[iMax - 1];
    }

    var i = Math.floor(s * iMax);

    return interpolateColor(colors[i], colors[i + 1], s - i / (iMax-1));
}

//------------------------------------------------------------------------------

function interpolateArray(array, s, minValue, maxValue) {
    if (!Array.isArray(array)) {
        console.error("Not an array:", array);
        return;
    }

    var iMax = array.length;

    if (s <= 0) {
        return minValue ? minValue : array[0];
    } else if (s >= 1) {
        return maxValue ? maxValue: array[iMax - 1];
    }

    var i = Math.floor(s * iMax);

    return array[i];
}

//------------------------------------------------------------------------------
// Determinant formula which gives twice the (signed) area of the
// triangle a->b->c. If the area is positive, then a->b->c is counterclockwise;
// if the area is negative, then a->b->c is clockwise; if the area is zero
// then a->b->c are collinear.

function det(a, b, c) {
    var d = (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
    //console.log("det:", d, "a:", JSON.stringify(a), "b:", JSON.stringify(b), "c:", JSON.stringify(c));
    return d;
}


//------------------------------------------------------------------------------
// +1 if counter-clockwise, -1 if clockwise, 0 if collinear

function ccw(a, b, c) {
    // return a.x*b.y - a.y*b.x + a.y*c.x - a.x*c.y + b.x*c.y - b.y*c.x;
    var area2 = (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
    if      (area2 < 0) return -1;
    else if (area2 > 0) return +1;
    else                return  0;
}

function ccw2(a, b, c) {
    var dx1 = b.x - a.x;
    var dy1 = b.y - a.y;
    var dx2 = c.x - a.x;
    var dy2 = c.y - a.y;
    if      (dx1*dy2 < dy1*dx2)                     return +1;
    else if (dx1*dy2 < dy1*dx2)                     return -1;
    else if (dx1*dx2 < 0 || dy1*dy2 < 0)            return -1;
    else if (dx1*dx1 + dy1*dy1 < dx2*dx2 + dy2*dy2) return +1;
    else
        return  0;
}
//------------------------------------------------------------------------------
// Two line segments (ap, aq) and (bp, bq) intersect (properly or inproperly) if either
// (ap, aq, bp) and (ap, aq, bq) have different orientations and
// (bp, bq, ap) and (bp, bq, aq) have different orientations.
// (ap, aq, bp), (ap, aq, bq), (bp, bq, ap), and (bp, bq, aq) are all collinear
// and the x-projections of the two line segments intersect and the y-projections
// of the two line segments intersect.

function intersects(ap, aq, bp, bq) {
    //console.log("a:", JSON.stringify(ap), JSON.stringify(aq));
    //console.log("b:", JSON.stringify(bp), JSON.stringify(bq));

    if ((ccw2(ap, aq, bp) * ccw2(ap, aq, bq)) > 0) {
        return false;
    }

    if ((ccw2(bp, bq, ap) * ccw2(bp, bq, aq)) > 0) {
        return false;
    }

    return true;
}

//------------------------------------------------------------------------------

function eq(a, b) {
    return a.x === b.x && a.y === b.y;
}

//------------------------------------------------------------------------------

function selfIntersects(points) {
    for (var i = 0; i < points.length - 1; i++) {
        for (var j = points.length - 2; j--; j > i + 1) {
            if (intersects(points[i], points[i + 1],
                           points[j], points[j + 1])) {
                console.log("Interests:", i, j, points.length);
                return points.splice(i, j - i);
            }
        }
    }
}

//------------------------------------------------------------------------------
