import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  Patient monitor.

    A different industry means a different set of rules, not a recoloured
    cluster. Here the colours are the ones clinicians already read: green
    for ECG, cyan for pleth, yellow for respiration. Numbers are enormous
    because they are read across a room. Alarm limits sit beside every
    value, because a number without its limits is not clinical data.   */
Rectangle {
    id: screen
    color: "#04070A"

    readonly property color ecgGreen: "#3FE07A"
    readonly property color plethCyan: "#4FD8E8"
    readonly property color respYellow: "#F2D024"

    component Vital: ColumnLayout {
        property string label: ""
        property string value: ""
        property string unit: ""
        property string limits: ""
        property color tint: "#FFFFFF"
        spacing: 0
        RowLayout {
            spacing: 8
            Text {
                text: label
                color: tint
                font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 1.6
            }
            Text {
                text: unit
                color: Theme.faint
                font.family: Theme.faceData; font.pixelSize: 11
            }
        }
        Text {
            text: value
            color: tint
            font.family: Theme.faceUi
            font.pixelSize: 52
            font.bold: true
        }
        Text {
            text: limits
            color: Theme.faint
            font.family: Theme.faceData; font.pixelSize: 11
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        // ---------------- waveform stack --------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "BED 4  \u00B7  ADULT  \u00B7  MONITORING"
                    color: Theme.dim
                    font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 1.6
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: alarmTxt.width + 18; implicitHeight: 22; radius: 3
                    color: "transparent"; border.width: 1; border.color: screen.respYellow
                    Text {
                        id: alarmTxt
                        anchors.centerIn: parent
                        text: "ALARMS ACTIVE"
                        color: screen.respYellow
                        font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.2
                    }
                }
            }

            Repeater {
                model: [
                    { lab: "II",     src: 0, col: screen.ecgGreen,   lo: -0.35, hi: 1.15, fill: false },
                    { lab: "PLETH",  src: 1, col: screen.plethCyan,  lo: -0.1,  hi: 1.4,  fill: true },
                    { lab: "RESP",   src: 2, col: screen.respYellow, lo: 0.0,   hi: 1.0,  fill: false }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#070B10"
                    border.width: 1
                    border.color: "#111820"
                    radius: 3

                    Text {
                        x: 10; y: 8
                        text: modelData.lab
                        color: modelData.col
                        font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 1.4
                    }
                    WaveTrace {
                        anchors.fill: parent
                        anchors.margins: 10
                        anchors.topMargin: 22
                        samples: modelData.src === 0 ? Waves.ecg
                               : modelData.src === 1 ? Waves.pleth : Waves.resp
                        stroke: modelData.col
                        minY: modelData.lo
                        maxY: modelData.hi
                        lineWidth: 1.9
                        filled: modelData.fill
                        fillOpacity: 0.18
                    }
                }
            }
        }

        // ---------------- vitals column ---------------------------
        Rectangle {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            color: "#070B10"
            border.width: 1; border.color: "#111820"; radius: 3

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Vital {
                    label: "HR"; unit: "bpm"; tint: screen.ecgGreen
                    value: String(Waves.heartRate); limits: "50  ~  120"
                }
                Vital {
                    label: "SpO\u2082"; unit: "%"; tint: screen.plethCyan
                    value: String(Waves.spo2); limits: "90  ~  100"
                }
                Vital {
                    label: "RR"; unit: "rpm"; tint: screen.respYellow
                    value: String(Waves.respRate); limits: "8  ~  24"
                }
                Vital {
                    label: "NIBP"; unit: "mmHg"; tint: Theme.ink
                    value: Waves.sysBp + "/" + Waves.diaBp; limits: "auto  \u00B7  15 min"
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 18
                    ColumnLayout {
                        spacing: 0
                        Text { text: "TEMP"; color: Theme.dim
                               font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.4 }
                        Text { text: Waves.tempC.toFixed(1) + " \u00B0C"; color: Theme.ink
                               font.family: Theme.faceUi; font.pixelSize: 20; font.bold: true }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text { text: "etCO\u2082"; color: Theme.dim
                               font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.4 }
                        Text { text: Waves.etco2.toFixed(0) + " mmHg"; color: Theme.ink
                               font.family: Theme.faceUi; font.pixelSize: 20; font.bold: true }
                    }
                }
                Item { Layout.fillHeight: true }
                Text {
                    Layout.fillWidth: true
                    text: "nobody is in this bed. the numbers are made up."
                    color: Theme.faint
                    font.family: Theme.faceData; font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
