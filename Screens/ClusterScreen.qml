import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  The cluster. Reads state, renders it, owns no vehicle logic. Frame
    time comes from FrameAnimation, driven by the scene graph's own
    swap, so the figure on screen is measured and not estimated.     */
Rectangle {
    id: screen
    color: Theme.bg

    FrameAnimation { id: renderClock; running: true }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Telltale { kind: "left";  tint: Theme.ttGreen; active: Vehicle.ttLeft }
            Telltale { kind: "beam";  tint: Theme.ttBlue;  active: Vehicle.ttBeam }
            Telltale { kind: "abs";   tint: Theme.ttAmber; active: Vehicle.ttAbs }
            Telltale { kind: "brake"; tint: Theme.ttRed;   active: Vehicle.ttBrake }
            Telltale { kind: "temp";  tint: Theme.ttRed;   active: Vehicle.ttTemp }
            Telltale { kind: "fuel";  tint: Theme.ttAmber; active: Vehicle.ttFuel }
            Telltale { kind: "batt";  tint: Theme.ttRed;   active: Vehicle.ttBatt }

            Item { Layout.fillWidth: true }

            Text {
                text: "GEAR"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 13; font.letterSpacing: 2
            }
            Text {
                text: Vehicle.gearLabel
                color: Theme.ink
                font.family: Theme.faceData; font.pixelSize: 15
                font.weight: Font.DemiBold; font.letterSpacing: 2
            }
            Telltale { kind: "right"; tint: Theme.ttGreen; active: Vehicle.ttRight }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        RowLayout {
            id: gaugeRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Gauge {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.min(height, screen.width * 0.30)
                Layout.maximumWidth: screen.width * 0.32
                value: Vehicle.rpm
                from: 0; to: 8000
                majorTicks: 8
                tickLabels: ["0","1","2","3","4","5","6","7","8"]
                redlineFrom: 0.75
                arcColor: Theme.cyan
                caption: "r/min"
                subCaption: "x1000"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 220
                spacing: 0

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 26
                    Repeater {
                        model: ["P", "R", "N", "D"]
                        delegate: Text {
                            required property string modelData
                            readonly property bool on: Vehicle.driveMode === modelData
                            text: modelData
                            color: on ? Theme.accent : Theme.faint
                            font.family: Theme.faceUi
                            font.pixelSize: 22
                            font.bold: on
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    text: Vehicle.speedKph < 10
                          ? "0" + Math.round(Vehicle.speedKph) : Math.round(Vehicle.speedKph)
                    color: Theme.ink
                    font.family: Theme.faceUi
                    font.pixelSize: Math.min(screen.height * 0.34, 150)
                    font.bold: true
                    font.letterSpacing: -3
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "km / h"
                    color: Theme.dim
                    font.family: Theme.faceData; font.pixelSize: 17; font.letterSpacing: 3
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 14
                    text: "RANGE " + Vehicle.rangeKm.toFixed(0) + " km"
                    color: Theme.dim
                    font.family: Theme.faceData; font.pixelSize: 14; font.letterSpacing: 2
                }

                Item { Layout.fillHeight: true }
            }

            Gauge {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.min(height, screen.width * 0.30)
                Layout.maximumWidth: screen.width * 0.32
                value: Vehicle.fuelPct
                from: 0; to: 100
                majorTicks: 4
                tickLabels: ["E", "", "1/2", "", "F"]
                arcColor: Vehicle.fuelPct < 15 ? Theme.ttRed : Theme.accent
                caption: "fuel  %"
                subCaption: "coolant \u00B0C"
                innerVisible: true
                innerValue: (Vehicle.coolantC - 40) / 80
                innerColor: Vehicle.coolantC > 105 ? Theme.ttRed : Theme.ttBlue
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        RowLayout {
            Layout.fillWidth: true
            spacing: 30

            Text {
                text: "ODO " + Vehicle.odometerKm.toFixed(1)
                      + " km   TRIP " + Vehicle.tripKm.toFixed(1) + " km"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 13
            }
            Text {
                text: "COOLANT " + Vehicle.coolantC.toFixed(0) + " \u00B0C"
                color: Vehicle.coolantC > 100 ? Theme.ttRed : Theme.dim
                font.family: Theme.faceData; font.pixelSize: 13
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "RENDER " + (renderClock.smoothFrameTime * 1000).toFixed(1) + " ms/frame   "
                      + (1 / Math.max(renderClock.smoothFrameTime, 0.0001)).toFixed(0) + " fps"
                color: Theme.cyan
                font.family: Theme.faceData; font.pixelSize: 13
            }
        }
    }
}
