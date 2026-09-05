import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  Off-highway / heavy equipment panel.

    Same components as the passenger cluster, different information
    priority: an operator cares about hydraulic temperature, DEF level
    and engine hours far more than road speed, and the panel is read in
    direct sunlight through a dirty windscreen, hence the heavier
    type and the larger touch targets.                               */
Rectangle {
    id: screen
    color: Theme.bg

    // Vehicle.rpm is a passenger-car figure. A diesel of this class
    // idles near 900 and is governed around 2100, so the shared drive
    // cycle is remapped rather than displayed raw -- feeding it in
    // directly pins the needle past the redline permanently.
    readonly property real engineRpm: 900 + (Vehicle.rpm / 5200) * 1200
    readonly property real hydraulicC: 78 + (Vehicle.rpm / 5200) * 26
    readonly property real loadPct: 34 + (Vehicle.rpm / 5200) * 52

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Text {
                text: "EXCAVATOR 220 \u00B7 UNIT EX-4471"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Repeater {
                model: [
                    { t: "WORK MODE",  v: "HEAVY" },
                    { t: "ENGINE HRS", v: "9 733" },
                    { t: "DEF",        v: "62 %" }
                ]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 7
                    Text {
                        text: modelData.t
                        color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.4
                    }
                    Text {
                        text: modelData.v
                        color: Theme.ink
                        font.family: Theme.faceData; font.pixelSize: 13; font.bold: true
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            Gauge {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.min(height, screen.width * 0.27)
                Layout.maximumWidth: screen.width * 0.29
                value: screen.engineRpm
                from: 0; to: 3000
                majorTicks: 6
                tickLabels: ["0", "5", "10", "15", "20", "25", "30"]
                redlineFrom: 0.833
                arcColor: Theme.cyan
                caption: "r/min"
                subCaption: "x100"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 240
                spacing: 12

                Item { Layout.fillHeight: true }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "HYDRAULIC"
                    color: Theme.dim
                    font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 2
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: screen.hydraulicC.toFixed(0) + "\u00B0"
                    color: screen.hydraulicC > 98 ? Theme.ttRed : Theme.ink
                    font.family: Theme.faceUi
                    font.pixelSize: Math.min(screen.height * 0.26, 108)
                    font.bold: true
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "OIL TEMPERATURE \u00B7 LIMIT 98\u00B0C"
                    color: Theme.faint
                    font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.4
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    spacing: 22
                    Telltale { kind: "temp";  tint: Theme.ttRed
                               active: screen.hydraulicC > 98 }
                    Telltale { kind: "fuel";  tint: Theme.ttAmber; active: true }
                    Telltale { kind: "batt";  tint: Theme.ttRed;   active: false }
                    Telltale { kind: "brake"; tint: Theme.ttRed;   active: false }
                }

                Item { Layout.fillHeight: true }
            }

            Gauge {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.min(height, screen.width * 0.27)
                Layout.maximumWidth: screen.width * 0.29
                value: screen.loadPct
                from: 0; to: 100
                majorTicks: 4
                tickLabels: ["0", "", "50", "", "100"]
                redlineFrom: 0.85
                arcColor: Theme.accent
                caption: "load  %"
                subCaption: "pump duty"
                innerVisible: true
                innerValue: 0.62
                innerColor: Theme.ttGreen
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        RowLayout {
            Layout.fillWidth: true
            spacing: 26
            Repeater {
                model: [
                    ["BOOM",   "RETRACTED"],
                    ["SWING",  "LOCKED"],
                    ["TRAVEL", "LOW"],
                    ["FUEL",   "41 %"],
                    ["COOLANT", Vehicle.coolantC.toFixed(0) + " \u00B0C"]
                ]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 7
                    Text {
                        text: modelData[0]
                        color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.3
                    }
                    Text {
                        text: modelData[1]
                        color: Theme.ink
                        font.family: Theme.faceData; font.pixelSize: 11
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
