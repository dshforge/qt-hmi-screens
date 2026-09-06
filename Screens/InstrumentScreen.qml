import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  Spectrum analyser. Logarithmic dBm scale, because the signal of
    interest usually sits near the noise floor. 10 x 8 graticule.       */
Rectangle {
    id: screen
    color: "#05080B"

    readonly property color trace: "#F2D024"
    readonly property real markerX: 0.18

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "SPECTRUM  \u00B7  CH 1"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Repeater {
                model: [["CENTRE", "1.200 GHz"], ["SPAN", "2.400 GHz"],
                        ["RBW", "30 kHz"], ["REF", "-10 dBm"]]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 7
                    Text { text: modelData[0]; color: Theme.faint
                           font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.4 }
                    Text { text: modelData[1]; color: Theme.ink
                           font.family: Theme.faceData; font.pixelSize: 12 }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#070B10"
            border.width: 1; border.color: "#16202A"

            // 10 x 8 graticule, the convention on this class of instrument
            Repeater {
                model: 9
                delegate: Rectangle {
                    required property int index
                    width: 1; height: parent.height
                    x: parent.width * (index + 1) / 10
                    color: index === 4 ? "#243040" : "#141D26"
                }
            }
            Repeater {
                model: 7
                delegate: Rectangle {
                    required property int index
                    height: 1; width: parent.width
                    y: parent.height * (index + 1) / 8
                    color: index === 3 ? "#243040" : "#141D26"
                }
            }

            WaveTrace {
                id: spectrumTrace
                anchors.fill: parent
                anchors.margins: 1
                samples: Waves.spectrum
                stroke: screen.trace
                minY: -110
                maxY: -10
                lineWidth: 1.6
                filled: true
                fillOpacity: 0.14
            }

            // marker: an exact readout, never an estimate from the picture
            Rectangle {
                x: parent.width * screen.markerX
                width: 1; height: parent.height
                color: "#FF6B57"
                opacity: 0.8
            }
            Rectangle {
                x: parent.width * screen.markerX - 4
                y: parent.height * (1 - (Waves.peakDbm - spectrumTrace.minY) / (spectrumTrace.maxY - spectrumTrace.minY)) - 4
                width: 9; height: 9; radius: 5
                color: "#FF6B57"
            }
            Rectangle {
                x: Math.min(parent.width - width - 8, parent.width * screen.markerX + 12)
                y: 12
                width: mk.width + 20; height: mk.height + 14
                color: "#0B1118"
                border.width: 1; border.color: "#2A3542"
                radius: 3
                ColumnLayout {
                    id: mk
                    anchors.centerIn: parent
                    spacing: 2
                    Text { text: "MARKER 1"; color: "#FF6B57"
                           font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.4 }
                    Text { text: Waves.peakHz.toFixed(1) + " MHz"; color: Theme.ink
                           font.family: Theme.faceData; font.pixelSize: 13 }
                    Text { text: Waves.peakDbm.toFixed(2) + " dBm"; color: Theme.ink
                           font.family: Theme.faceData; font.pixelSize: 13 }
                }
            }

            // axis labels, placed on the scale the trace actually uses
            Repeater {
                model: [-10, -35, -60, -85, -110]
                delegate: Text {
                    required property int modelData
                    required property int index
                    x: 8
                    y: parent.height * (index / 4) - (index === 0 ? 0 : (index === 4 ? 14 : 7))
                    text: modelData + " dBm"
                    color: Theme.faint
                    font.family: Theme.faceData; font.pixelSize: 10
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 26
            Repeater {
                model: [["SWEEP", "42 ms"], ["DET", "peak"], ["TRACE", "clear/write"],
                        ["ATT", "10 dB"], ["AVG", "off"]]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 7
                    Text { text: modelData[0]; color: Theme.faint
                           font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.3 }
                    Text { text: modelData[1]; color: Theme.dim
                           font.family: Theme.faceData; font.pixelSize: 11 }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
