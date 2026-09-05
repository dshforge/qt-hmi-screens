import QtQuick
import QtQuick.Shapes
import Screens

/*  Arc gauge drawn with Qt Quick Shapes, so the sweep is a real
    GPU-batched path rather than a repainted Canvas. Everything is
    driven off `value`; nothing in here knows what it is measuring.  */
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property int  majorTicks: 8
    property var  tickLabels: []
    property real redlineFrom: -1        // fraction 0..1, -1 disables
    property color arcColor: Theme.cyan
    property string caption: ""
    property string subCaption: ""

    // optional inner ring (coolant inside the fuel gauge, for instance)
    property bool  innerVisible: false
    property real  innerValue: 0
    property color innerColor: Theme.ttBlue

    readonly property real frac: to > from
        ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real radius: Math.min(width, height) / 2 - Theme.gaugeStroke / 2

    implicitWidth: 260
    implicitHeight: 260

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.samples: 4

        ShapePath {                                   // unfilled track
            strokeColor: Theme.track
            strokeWidth: Theme.gaugeStroke
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius; radiusY: root.radius
                startAngle: Theme.startAngle
                sweepAngle: Theme.sweepAngle
            }
        }
        ShapePath {                                   // value sweep
            strokeColor: root.redlineFrom >= 0 && root.frac >= root.redlineFrom
                         ? Theme.ttRed : root.arcColor
            strokeWidth: Theme.gaugeStroke
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius; radiusY: root.radius
                startAngle: Theme.startAngle
                sweepAngle: Theme.sweepAngle * root.frac
            }
        }
        ShapePath {                                   // inner ring
            strokeColor: root.innerColor
            strokeWidth: 9
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius - 58; radiusY: root.radius - 58
                startAngle: Theme.startAngle
                sweepAngle: root.innerVisible
                    ? Theme.sweepAngle * Math.max(0, Math.min(1, root.innerValue)) : 0
            }
        }
    }

    // --- minor ticks ------------------------------------------------
    Repeater {
        model: root.majorTicks * 4
        delegate: Rectangle {
            required property int index
            readonly property real f: index / (root.majorTicks * 4)
            readonly property real deg: Theme.startAngle + Theme.sweepAngle * f
            readonly property real rad: deg * Math.PI / 180
            visible: index % 4 !== 0
            width: 9; height: 2
            color: Theme.faint
            transformOrigin: Item.Center
            rotation: deg
            x: root.cx + Math.cos(rad) * (root.radius - 17) - width / 2
            y: root.cy + Math.sin(rad) * (root.radius - 17) - height / 2
        }
    }

    // --- major ticks + labels ---------------------------------------
    Repeater {
        model: root.majorTicks + 1
        delegate: Item {
            required property int index
            readonly property real f: index / root.majorTicks
            readonly property real deg: Theme.startAngle + Theme.sweepAngle * f
            readonly property real rad: deg * Math.PI / 180
            readonly property bool red: root.redlineFrom >= 0 && f >= root.redlineFrom - 0.0001

            Rectangle {
                width: 18; height: 4; radius: 2
                color: parent.red ? Theme.ttRed : Theme.dim
                transformOrigin: Item.Center
                rotation: parent.deg
                x: root.cx + Math.cos(parent.rad) * (root.radius - 22) - width / 2
                y: root.cy + Math.sin(parent.rad) * (root.radius - 22) - height / 2
            }
            Text {
                visible: index < root.tickLabels.length && root.tickLabels[index] !== ""
                text: visible ? root.tickLabels[index] : ""
                color: parent.red ? Theme.ttRed : Theme.ink
                font.family: Theme.faceData
                font.pixelSize: Math.max(11, root.radius * 0.145)
                font.weight: Font.Medium
                x: root.cx + Math.cos(parent.rad) * (root.radius - 50) - width / 2
                y: root.cy + Math.sin(parent.rad) * (root.radius - 50) - height / 2
            }
        }
    }

    // --- captions ----------------------------------------------------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy + root.radius * 0.36
        spacing: 3
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.caption
            color: Theme.dim
            font.family: Theme.faceData
            font.pixelSize: Math.max(10, root.radius * 0.11)
            font.letterSpacing: 1.2
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subCaption
            color: Theme.faint
            font.family: Theme.faceData
            font.pixelSize: Math.max(9, root.radius * 0.095)
            font.letterSpacing: 1.2
        }
    }

    // --- needle ------------------------------------------------------
    Item {
        x: root.cx
        y: root.cy
        rotation: Theme.startAngle + Theme.sweepAngle * root.frac
        Rectangle {
            x: -26; y: -2.5
            width: root.radius - 8; height: 5; radius: 2.5
            color: root.redlineFrom >= 0 && root.frac >= root.redlineFrom
                   ? Theme.ttRed : Theme.ink
        }
    }
    Rectangle {
        width: 34; height: 34; radius: 17
        x: root.cx - 17; y: root.cy - 17
        color: Theme.bg
        border.width: 4
        border.color: root.redlineFrom >= 0 && root.frac >= root.redlineFrom
                      ? Theme.ttRed : Theme.ink
    }
}
