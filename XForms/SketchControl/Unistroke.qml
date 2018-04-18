import QtQuick 2.7

import ArcGIS.AppFramework 1.0

import "SketchLib.js" as SketchLib
import "dollar.js" as Dollar

QtObject {
    id: unistroke

    property var dollar: new Dollar.DollarRecognizer()
    property var result
    property int numUnistrokes: dollar.Unistrokes.length;

    property real defaultThreshold: 0.85

    property var thresholds: {
        "rectangle": 0.85,
                "circle": 0.85,
                "delete": 0.85
    }


    //--------------------------------------------------------------------------

    signal actionStroke(string action)

    //--------------------------------------------------------------------------

    Component.onCompleted: {

        removeGesture("triangle");
        removeGesture("x");
        removeGesture("check");
        removeGesture("caret");
        removeGesture("zig-zag");
        removeGesture("left square bracket");
        removeGesture("right square bracket");
        removeGesture("v");
        removeGesture("left curly brace");
        removeGesture("right curly brace");
        removeGesture("star");
        removeGesture("pigtail");

        addGesture("rectangle2", true, new Array(new Dollar.Point(78,149),new Dollar.Point(78,153),new Dollar.Point(78,157),new Dollar.Point(78,160),new Dollar.Point(79,162),new Dollar.Point(79,164),new Dollar.Point(79,167),new Dollar.Point(79,169),new Dollar.Point(79,173),new Dollar.Point(79,178),new Dollar.Point(79,183),new Dollar.Point(80,189),new Dollar.Point(80,193),new Dollar.Point(80,198),new Dollar.Point(80,202),new Dollar.Point(81,208),new Dollar.Point(81,210),new Dollar.Point(81,216),new Dollar.Point(82,222),new Dollar.Point(82,224),new Dollar.Point(82,227),new Dollar.Point(83,229),new Dollar.Point(83,231),new Dollar.Point(85,230),new Dollar.Point(88,232),new Dollar.Point(90,233),new Dollar.Point(92,232),new Dollar.Point(94,233),new Dollar.Point(99,232),new Dollar.Point(102,233),new Dollar.Point(106,233),new Dollar.Point(109,234),new Dollar.Point(117,235),new Dollar.Point(123,236),new Dollar.Point(126,236),new Dollar.Point(135,237),new Dollar.Point(142,238),new Dollar.Point(145,238),new Dollar.Point(152,238),new Dollar.Point(154,239),new Dollar.Point(165,238),new Dollar.Point(174,237),new Dollar.Point(179,236),new Dollar.Point(186,235),new Dollar.Point(191,235),new Dollar.Point(195,233),new Dollar.Point(197,233),new Dollar.Point(200,233),new Dollar.Point(201,235),new Dollar.Point(201,233),new Dollar.Point(199,231),new Dollar.Point(198,226),new Dollar.Point(198,220),new Dollar.Point(196,207),new Dollar.Point(195,195),new Dollar.Point(195,181),new Dollar.Point(195,173),new Dollar.Point(195,163),new Dollar.Point(194,155),new Dollar.Point(192,145),new Dollar.Point(192,143),new Dollar.Point(192,138),new Dollar.Point(191,135),new Dollar.Point(191,133),new Dollar.Point(191,130),new Dollar.Point(190,128),new Dollar.Point(188,129),new Dollar.Point(186,129),new Dollar.Point(181,132),new Dollar.Point(173,131),new Dollar.Point(162,131),new Dollar.Point(151,132),new Dollar.Point(149,132),new Dollar.Point(138,132),new Dollar.Point(136,132),new Dollar.Point(122,131),new Dollar.Point(120,131),new Dollar.Point(109,130),new Dollar.Point(107,130),new Dollar.Point(90,132),new Dollar.Point(81,133),new Dollar.Point(76,133)));
        addGesture("circle2", true, new Array(new Dollar.Point(127,141),new Dollar.Point(124,140),new Dollar.Point(120,139),new Dollar.Point(118,139),new Dollar.Point(116,139),new Dollar.Point(111,140),new Dollar.Point(109,141),new Dollar.Point(104,144),new Dollar.Point(100,147),new Dollar.Point(96,152),new Dollar.Point(93,157),new Dollar.Point(90,163),new Dollar.Point(87,169),new Dollar.Point(85,175),new Dollar.Point(83,181),new Dollar.Point(82,190),new Dollar.Point(82,195),new Dollar.Point(83,200),new Dollar.Point(84,205),new Dollar.Point(88,213),new Dollar.Point(91,216),new Dollar.Point(96,219),new Dollar.Point(103,222),new Dollar.Point(108,224),new Dollar.Point(111,224),new Dollar.Point(120,224),new Dollar.Point(133,223),new Dollar.Point(142,222),new Dollar.Point(152,218),new Dollar.Point(160,214),new Dollar.Point(167,210),new Dollar.Point(173,204),new Dollar.Point(178,198),new Dollar.Point(179,196),new Dollar.Point(182,188),new Dollar.Point(182,177),new Dollar.Point(178,167),new Dollar.Point(170,150),new Dollar.Point(163,138),new Dollar.Point(152,130),new Dollar.Point(143,129),new Dollar.Point(140,131),new Dollar.Point(129,136),new Dollar.Point(126,139)));
        //addGesture("arrow2", true, new Array(new Dollar.Point(68,222),new Dollar.Point(70,220),new Dollar.Point(73,218),new Dollar.Point(75,217),new Dollar.Point(77,215),new Dollar.Point(80,213),new Dollar.Point(82,212),new Dollar.Point(84,210),new Dollar.Point(87,209),new Dollar.Point(89,208),new Dollar.Point(92,206),new Dollar.Point(95,204),new Dollar.Point(101,201),new Dollar.Point(106,198),new Dollar.Point(112,194),new Dollar.Point(118,191),new Dollar.Point(124,187),new Dollar.Point(127,186),new Dollar.Point(132,183),new Dollar.Point(138,181),new Dollar.Point(141,180),new Dollar.Point(146,178),new Dollar.Point(154,173),new Dollar.Point(159,171),new Dollar.Point(161,170),new Dollar.Point(166,167),new Dollar.Point(168,167),new Dollar.Point(171,166),new Dollar.Point(174,164),new Dollar.Point(177,162),new Dollar.Point(180,160),new Dollar.Point(182,158),new Dollar.Point(183,156),new Dollar.Point(181,154),new Dollar.Point(178,153),new Dollar.Point(171,153),new Dollar.Point(164,153),new Dollar.Point(160,153),new Dollar.Point(150,154),new Dollar.Point(147,155),new Dollar.Point(141,157),new Dollar.Point(137,158),new Dollar.Point(135,158),new Dollar.Point(137,158),new Dollar.Point(140,157),new Dollar.Point(143,156),new Dollar.Point(151,154),new Dollar.Point(160,152),new Dollar.Point(170,149),new Dollar.Point(179,147),new Dollar.Point(185,145),new Dollar.Point(192,144),new Dollar.Point(196,144),new Dollar.Point(198,144),new Dollar.Point(200,144),new Dollar.Point(201,147),new Dollar.Point(199,149),new Dollar.Point(194,157),new Dollar.Point(191,160),new Dollar.Point(186,167),new Dollar.Point(180,176),new Dollar.Point(177,179),new Dollar.Point(171,187),new Dollar.Point(169,189),new Dollar.Point(165,194),new Dollar.Point(164,196)));

        console.log("NumUnistrokes:", numUnistrokes);
    }

    //--------------------------------------------------------------------------

    function recognize(points) {
        if (!Array.isArray(points)) {
            return;
        }

        if (points.length < 1) {
            return;
        }

        var pts = [];

        points.forEach(function (point) {
            pts.push(new Dollar.Point(point.x, point.y));
        });

        result = dollar.Recognize(pts);

        var threshold = thresholds[result.Name];
        if (!threshold) {
            threshold = defaultThreshold;
        }

        console.log("recognize threshold:", threshold, "result:", JSON.stringify(result, undefined, 2));

        if (result.Score < threshold) {
            console.info(result.Name, "score too low:", result.Score, "<", threshold);
            return;
        }

        var sketch;

        switch (result.Name) {
        case "rectangle":
        case "rectangle2":
            sketch = SketchLib.createRectangleSketch(points);
            break;

        case "circle":
        case "circle2":
            sketch = SketchLib.createEllipseSketch(points);
            break;

        case "arrow":
        case "arrow2":
            sketch = SketchLib.createArrowSketch(points);
            break;

        case "delete":
            if (result.Score >= 0.8) {
                actionStroke(result.Name);
            }
            break;
        }

        return sketch;
    }

    //--------------------------------------------------------------------------

    function drawUnistroke(ctx, index, width, height) {

        ctx.clearRect(0, 0, width, height);

        var sf = width / Dollar.SquareSize / 2;
        var stroke = dollar.Unistrokes[index];

        console.log("Stroke:", index, stroke.Name, width, height);

        var points = stroke.Points;

        var dx = Dollar.SquareSize / 2 * sf;
        var dy = Dollar.SquareSize / 2 * sf;

        var x1 = points[0].X * sf + dx;
        var y1 = points[0].Y * sf + dy;


        ctx.beginPath();
        ctx.fillStyle = "red";
        ctx.ellipse(x1, y1, 5, 5);
        ctx.fill();

        ctx.beginPath();

        ctx.moveTo(x1, y1);
        for (var i = 1; i < points.length; i++) {
            ctx.lineTo(points[i].X * sf + dx, points[i].Y * sf + dy)
        }

        ctx.stroke();


        ctx.strokeText("%1 %2".arg(index).arg(stroke.Name), 10, 10);
    }

    //--------------------------------------------------------------------------

    function addGesture(name, reverse, points) {
        if (reverse) {
            points.reverse();
        }

        dollar.AddGesture(name, points)

        numUnistrokes = dollar.Unistrokes.length;
    }

    //--------------------------------------------------------------------------

    function removeGesture(name) {
        for (var i = 0; i < dollar.Unistrokes.length; i++) {
            var stroke = dollar.Unistrokes[i];
            if (stroke.Name === name) {
                console.log("Removing unistroke:", i, name);
                dollar.Unistrokes.splice(i, 1);
                numUnistrokes = dollar.Unistrokes.length;
                return;
            }
        }

        console.error("Unistroke not found:", name);
    }

    //--------------------------------------------------------------------------
}
