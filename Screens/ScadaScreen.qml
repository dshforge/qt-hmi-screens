import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Screens
import Screens.Backend

/*  Process mimic.

    A mimic is not a dashboard. The screen is a schematic of the plant,
    and an operator navigates it the way they walk the site, so geometry
    carries meaning: a pipe between two vessels means those vessels are
    connected, and the flow animates in the direction the fluid moves.

    Colour is state, never decoration. Running, standby, alarm. Anything
    that is not one of those three is drawn in the neutral line colour so
    the eye is never pulled by something that is merely present.        */
Rectangle {
    id: screen
    color: "#070A0E"

    readonly property color pipe: "#2B3947"
    readonly property color flow: "#4FD8E8"
    readonly property color ok: "#3FD98A"
    readonly property color warn: "#F2B325"
    readonly property color alarm: "#FF5B4D"

    readonly property real t: Vehicle.rpm / 5200
    readonly property real feedFlow: 118 + t * 46
    readonly property real reactorC: 214 + t * 38
    readonly property real reactorBar: 6.2 + t * 1.9
    readonly property real level1: 0.34 + t * 0.28
    readonly property real level2: 0.72 - t * 0.22
    readonly property bool tripped: reactorC > 246

    component Tank: Item {
        property string tag: ""
        property real level: 0.5
        property color liquid: screen.flow
        implicitWidth: 84; implicitHeight: 110
        Rectangle {
            anchors.fill: parent
            color: "#0B1017"; border.width: 1.5; border.color: screen.pipe; radius: 4
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 3 }
            height: (parent.height - 6) * Math.max(0, Math.min(1, level))
            color: liquid; opacity: 0.30; radius: 3
            Behavior on height { NumberAnimation { duration: 400 } }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; margins: 3 }
            y: (parent.height - 6) * (1 - Math.max(0, Math.min(1, level))) + 3
            height: 2; color: liquid
            Behavior on y { NumberAnimation { duration: 400 } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top; anchors.bottomMargin: 5
            text: tag; color: Theme.dim
            font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.2
        }
        Text {
            anchors.centerIn: parent
            text: Math.round(level * 100) + "%"
            color: Theme.ink
            font.family: Theme.faceData; font.pixelSize: 14
        }
    }

    component Pipe: Rectangle {
        property bool flowing: true
        property bool vertical: false
        color: screen.pipe
        Rectangle {
            id: pulse
            width: parent.vertical ? parent.width : 16
            height: parent.vertical ? 16 : parent.height
            color: screen.flow
            visible: parent.flowing
            SequentialAnimation on x {
                running: parent.flowing && !parent.vertical
                loops: Animation.Infinite
                NumberAnimation { from: -16; to: pulse.parent.width; duration: 1500 }
            }
            SequentialAnimation on y {
                running: parent.flowing && parent.vertical
                loops: Animation.Infinite
                NumberAnimation { from: -16; to: pulse.parent.height; duration: 1500 }
            }
        }
        clip: true
    }

    component Valve: Item {
        property string tag: ""
        property bool open: true
        implicitWidth: 26; implicitHeight: 22
        Shape {
            anchors.fill: parent
            ShapePath {
                fillColor: open ? screen.ok : screen.warn
                strokeColor: "transparent"
                startX: 1; startY: 2
                PathLine { x: 13; y: 11 } PathLine { x: 1; y: 20 } PathLine { x: 1; y: 2 }
            }
            ShapePath {
                fillColor: open ? screen.ok : screen.warn
                strokeColor: "transparent"
                startX: 25; startY: 2
                PathLine { x: 13; y: 11 } PathLine { x: 25; y: 20 } PathLine { x: 25; y: 2 }
                PathLine { x: 25; y: 2 }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom; anchors.topMargin: 3
            text: tag; color: Theme.faint
            font.family: Theme.faceData; font.pixelSize: 9
        }
    }

    component Readout: ColumnLayout {
        property string tag: ""
        property string value: ""
        property string unit: ""
        property color tint: Theme.ink
        spacing: 1
        Text { text: tag; color: Theme.faint
               font.family: Theme.faceData; font.pixelSize: 9; font.letterSpacing: 1.2 }
        RowLayout {
            spacing: 4
            Text { text: value; color: tint
                   font.family: Theme.faceUi; font.pixelSize: 19; font.bold: true }
            Text { Layout.alignment: Qt.AlignBaseline; text: unit; color: Theme.dim
                   font.family: Theme.faceData; font.pixelSize: 10 }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "UNIT 200  \u00B7  REACTOR LOOP"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: st.width + 20; implicitHeight: 24; radius: 3
                color: "transparent"
                border.width: 1
                border.color: screen.tripped ? screen.alarm : screen.ok
                Text {
                    id: st
                    anchors.centerIn: parent
                    text: screen.tripped ? "HIGH TEMP  \u00B7  INTERLOCK ARMED" : "RUNNING  \u00B7  AUTO"
                    color: screen.tripped ? screen.alarm : screen.ok
                    font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.3
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#141C25" }

        // ---------------- the mimic --------------------------------
        //
        // The schematic is a fixed drawing, centred in whatever space it
        // gets. Stretching a mimic distorts the geometry, and on a mimic
        // the geometry is the information.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: mimic
                width: 640; height: 300
                anchors.centerIn: parent

                Tank { id: feed; tag: "T-201  FEED"; x: 0; y: 40; level: screen.level1 }

                Pipe { x: 84; y: 88; width: 106; height: 6; flowing: true }
                Valve { id: v1; tag: "FV-201"; x: 124; y: 80; open: true }

                Rectangle {   // reactor
                    id: reactor
                    x: 190; y: 18
                    width: 170; height: 168; radius: 8
                    color: "#0B1017"
                    border.width: 2
                    border.color: screen.tripped ? screen.alarm : screen.pipe
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top; anchors.bottomMargin: 6
                        text: "R-201  REACTOR"; color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.2
                    }
                    // agitator sits at the top, clear of the readouts
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 12; width: 3; height: 20; color: screen.pipe
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 31; width: 44; height: 3; color: screen.ok
                        transformOrigin: Item.Center
                        RotationAnimation on rotation {
                            running: v1.open; loops: Animation.Infinite
                            from: 0; to: 360; duration: 900
                        }
                    }
                    ColumnLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 52
                        spacing: 10
                        Readout {
                            Layout.alignment: Qt.AlignHCenter
                            tag: "TEMPERATURE"; unit: "°C"
                            value: screen.reactorC.toFixed(0)
                            tint: screen.tripped ? screen.alarm : Theme.ink
                        }
                        Readout {
                            Layout.alignment: Qt.AlignHCenter
                            tag: "PRESSURE"; unit: "bar"
                            value: screen.reactorBar.toFixed(1)
                        }
                    }
                }

                Pipe { x: 360; y: 88; width: 106; height: 6; flowing: !screen.tripped }
                Valve { id: v2; tag: "PV-202"; x: 400; y: 80; open: !screen.tripped }

                Tank { id: prod; tag: "T-202  PRODUCT"; x: 466; y: 40; level: screen.level2
                       liquid: screen.ok }

                // cooling return: down from the reactor, back along the
                // bottom, up into the feed side. Drawn as a run, not a box.
                Pipe { x: 272; y: 186; width: 5; height: 62; flowing: true; vertical: true }
                Pipe { x: 60;  y: 243; width: 217; height: 5; flowing: true }
                Pipe { x: 60;  y: 150; width: 5; height: 98; flowing: true; vertical: true }
                Pipe { x: 60;  y: 150; width: 30; height: 5; flowing: true }
                Text {
                    x: 96; y: 252
                    text: "COOLING RETURN  ·  49 °C"; color: Theme.faint
                    font.family: Theme.faceData; font.pixelSize: 9; font.letterSpacing: 1.2
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#141C25" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 34
            Readout { tag: "FEED FLOW"; value: screen.feedFlow.toFixed(0); unit: "m\u00B3/h" }
            Readout { tag: "COOLANT IN"; value: "28"; unit: "\u00B0C" }
            Readout { tag: "COOLANT OUT"; value: (44 + screen.t * 14).toFixed(0); unit: "\u00B0C" }
            Readout { tag: "CONVERSION"; value: (91.4 - screen.t * 3.1).toFixed(1); unit: "%" }
            Readout { tag: "RUN TIME"; value: "412"; unit: "h" }
            Item { Layout.fillWidth: true }
        }
    }
}
