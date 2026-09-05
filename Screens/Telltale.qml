import QtQuick
import QtQuick.Shapes
import Screens

/*  One telltale. `kind` selects the pictogram, `tint` comes from the
    ISO 2575 group in Theme -- the two are set together at the call
    site so a lamp cannot be given a colour its standard forbids.     */
Item {
    id: root

    property string kind: "beam"
    property color tint: Theme.ttAmber
    property bool active: false

    implicitWidth: 30
    implicitHeight: 30
    opacity: active ? 1.0 : 0.14
    Behavior on opacity { NumberAnimation { duration: 70 } }

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.kind) {
            case "beam":  return beamIcon
            case "left":  return leftIcon
            case "right": return rightIcon
            case "brake": return brakeIcon
            case "abs":   return absIcon
            case "temp":  return tempIcon
            case "fuel":  return fuelIcon
            case "batt":  return battIcon
            default:      return beamIcon
            }
        }
    }

    // ---- main beam -------------------------------------------------
    Component {
        id: beamIcon
        Item {
            Shape {
                anchors.fill: parent
                ShapePath {
                    fillColor: root.tint; strokeColor: "transparent"
                    startX: width * 0.16; startY: height * 0.27
                    PathLine { x: width * 0.34; y: height * 0.27 }
                    PathArc  { x: width * 0.34; y: height * 0.73
                               radiusX: width * 0.23; radiusY: height * 0.23 }
                    PathLine { x: width * 0.16; y: height * 0.73 }
                    PathLine { x: width * 0.16; y: height * 0.27 }
                }
            }
            Column {
                x: parent.width * 0.54
                y: parent.height * 0.28
                spacing: parent.height * 0.155
                Repeater {
                    model: 3
                    Rectangle { width: root.width * 0.32; height: 2.4; radius: 1.2; color: root.tint }
                }
            }
        }
    }

    // ---- direction indicators --------------------------------------
    Component {
        id: leftIcon
        Shape {
            ShapePath {
                fillColor: root.tint; strokeColor: "transparent"
                startX: root.width * 0.46; startY: root.height * 0.17
                PathLine { x: root.width * 0.13; y: root.height * 0.50 }
                PathLine { x: root.width * 0.46; y: root.height * 0.83 }
                PathLine { x: root.width * 0.46; y: root.height * 0.63 }
                PathLine { x: root.width * 0.84; y: root.height * 0.63 }
                PathLine { x: root.width * 0.84; y: root.height * 0.37 }
                PathLine { x: root.width * 0.46; y: root.height * 0.37 }
                PathLine { x: root.width * 0.46; y: root.height * 0.17 }
            }
        }
    }
    Component {
        id: rightIcon
        Item {
            Loader { anchors.fill: parent; sourceComponent: leftIcon }
            transform: Scale { origin.x: root.width / 2; xScale: -1 }
        }
    }

    // ---- brake: (!) between two brackets ---------------------------
    Component {
        id: brakeIcon
        Item {
            Rectangle {
                width: root.width * 0.52; height: width; radius: width / 2
                anchors.centerIn: parent
                color: "transparent"; border.width: 2.2; border.color: root.tint
            }
            Rectangle {
                width: 2.4; height: root.height * 0.20; radius: 1.2; color: root.tint
                x: root.width / 2 - 1.2; y: root.height * 0.33
            }
            Rectangle {
                width: 2.6; height: 2.6; radius: 1.3; color: root.tint
                x: root.width / 2 - 1.3; y: root.height * 0.60
            }
            Repeater {
                model: [-1, 1]
                delegate: Shape {
                    required property int modelData
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: root.tint; strokeWidth: 2.2; fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        startX: root.width / 2 + modelData * root.width * 0.40
                        startY: root.height * 0.30
                        PathQuad {
                            x: root.width / 2 + modelData * root.width * 0.40
                            y: root.height * 0.70
                            controlX: root.width / 2 + modelData * root.width * 0.52
                            controlY: root.height * 0.50
                        }
                    }
                }
            }
        }
    }

    // ---- ABS: brake symbol with lettering ---------------------------
    Component {
        id: absIcon
        Item {
            Rectangle {
                width: root.width * 0.60; height: width; radius: width / 2
                anchors.centerIn: parent
                color: "transparent"; border.width: 2.0; border.color: root.tint
            }
            Text {
                anchors.centerIn: parent
                text: "ABS"
                color: root.tint
                font.family: Theme.faceUi
                font.pixelSize: root.height * 0.27
                font.bold: true
            }
            Repeater {
                model: [-1, 1]
                delegate: Shape {
                    required property int modelData
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: root.tint; strokeWidth: 2.2; fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        startX: root.width / 2 + modelData * root.width * 0.42
                        startY: root.height * 0.30
                        PathQuad {
                            x: root.width / 2 + modelData * root.width * 0.42
                            y: root.height * 0.70
                            controlX: root.width / 2 + modelData * root.width * 0.54
                            controlY: root.height * 0.50
                        }
                    }
                }
            }
        }
    }

    // ---- coolant temperature ----------------------------------------
    Component {
        id: tempIcon
        Item {
            Rectangle {
                width: 2.6; height: root.height * 0.42; radius: 1.3; color: root.tint
                x: root.width / 2 - 1.3; y: root.height * 0.16
            }
            Rectangle {
                width: root.width * 0.28; height: width; radius: width / 2
                color: root.tint
                x: root.width / 2 - width / 2; y: root.height * 0.55
            }
            Repeater {
                model: [-1, 1]
                delegate: Shape {
                    required property int modelData
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: root.tint; strokeWidth: 2.0; fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        startX: root.width / 2 + modelData * root.width * 0.14
                        startY: root.height * 0.88
                        PathQuad {
                            x: root.width / 2 + modelData * root.width * 0.44
                            y: root.height * 0.88
                            controlX: root.width / 2 + modelData * root.width * 0.29
                            controlY: root.height * 0.70
                        }
                    }
                }
            }
        }
    }

    // ---- low fuel ----------------------------------------------------
    Component {
        id: fuelIcon
        Item {
            Rectangle {                                   // tank body
                x: root.width * 0.16; y: root.height * 0.20
                width: root.width * 0.40; height: root.height * 0.66
                color: "transparent"; border.width: 2.0; border.color: root.tint; radius: 1.5
            }
            Rectangle {                                   // level window
                x: root.width * 0.24; y: root.height * 0.30
                width: root.width * 0.24; height: root.height * 0.20
                color: root.tint
            }
            Rectangle {                                   // ground line
                x: root.width * 0.11; y: root.height * 0.86
                width: root.width * 0.50; height: 2.2; radius: 1.1; color: root.tint
            }
            Shape {                                       // pump neck
                anchors.fill: parent
                ShapePath {
                    strokeColor: root.tint; strokeWidth: 2.0; fillColor: "transparent"
                    capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                    startX: root.width * 0.58; startY: root.height * 0.42
                    PathLine { x: root.width * 0.72; y: root.height * 0.42 }
                    PathLine { x: root.width * 0.72; y: root.height * 0.66 }
                    PathLine { x: root.width * 0.86; y: root.height * 0.66 }
                    PathLine { x: root.width * 0.86; y: root.height * 0.30 }
                    PathLine { x: root.width * 0.76; y: root.height * 0.19 }
                }
            }
        }
    }

    // ---- charging system ---------------------------------------------
    Component {
        id: battIcon
        Item {
            Rectangle {
                x: root.width * 0.10; y: root.height * 0.30
                width: root.width * 0.80; height: root.height * 0.46
                radius: 2
                color: "transparent"; border.width: 2.2; border.color: root.tint
            }
            Repeater {
                model: [0.26, 0.62]
                delegate: Rectangle {
                    required property real modelData
                    x: root.width * modelData; y: root.height * 0.21
                    width: root.width * 0.14; height: 2.4; radius: 1.2; color: root.tint
                }
            }
            Rectangle { x: root.width * 0.20; y: root.height * 0.51
                        width: root.width * 0.17; height: 2.2; color: root.tint }
            Rectangle { x: root.width * 0.27; y: root.height * 0.44
                        width: 2.2; height: root.height * 0.16; color: root.tint }
            Rectangle { x: root.width * 0.61; y: root.height * 0.51
                        width: root.width * 0.17; height: 2.2; color: root.tint }
        }
    }
}
