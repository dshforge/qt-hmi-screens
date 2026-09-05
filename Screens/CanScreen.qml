import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  Bus monitor. The model decodes frames and keeps a short history
    per signal; the view only draws. Swapping the simulated source
    for a QCanBusDevice is a change in CanModel, not in here.      */
Rectangle {
    color: Theme.bg

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "BUS MONITOR  \u00B7  CAN 1, 500 kbit/s"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "DECODED AGAINST DBC  \u00B7  " + Vehicle.can.frameRate + " FRAMES/S"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 1.6
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            Repeater {
                model: [["ID", 80], ["SIGNAL", 160], ["RAW", 90],
                        ["SCALED", 90], ["UNIT", 70], ["TREND", 80], ["AGE", 60]]
                delegate: Text {
                    required property var modelData
                    Layout.preferredWidth: modelData[1]
                    text: modelData[0]
                    color: Theme.dim
                    font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.6
                }
            }
            Item { Layout.fillWidth: true }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Vehicle.can

            delegate: Item {
                required property string frameId
                required property string signalName
                required property string raw
                required property real scaled
                required property int decimals
                required property string unit
                required property int ageMs
                required property bool alarm
                required property var history

                width: ListView.view.width
                height: 34

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1; color: "#141A21"
                }

                RowLayout {
                    anchors.fill: parent
                    Text {
                        Layout.preferredWidth: 80; text: frameId; color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 13
                    }
                    Text {
                        Layout.preferredWidth: 160; text: signalName; color: Theme.ink
                        font.family: Theme.faceData; font.pixelSize: 13
                    }
                    Text {
                        Layout.preferredWidth: 90; text: raw; color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 13
                    }
                    Text {
                        Layout.preferredWidth: 90
                        text: scaled.toFixed(decimals)
                        color: alarm ? Theme.ttRed : Theme.ink
                        font.family: Theme.faceData; font.pixelSize: 13
                    }
                    Text {
                        Layout.preferredWidth: 70; text: unit; color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 13
                    }
                    Sparkline {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter
                        samples: history
                        stroke: alarm ? Theme.ttRed : Theme.cyan
                    }
                    Text {
                        Layout.preferredWidth: 60; text: ageMs + " ms"; color: Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 13
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
