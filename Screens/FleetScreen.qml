import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  Fleet list driven by a QAbstractListModel on the C++ side. The
    delegate binds to roles, so adding a column is a role change and
    not a rewrite of the view.                                      */
Rectangle {
    id: screen
    color: Theme.bg

    property int selectedRow: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "DEPOT NORTH  \u00B7  " + Vehicle.fleet.rowCount() + " UNITS"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "TELEMETRY 1 Hz"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 2
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 22

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ---- header row ----
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    Repeater {
                        model: [["UNIT", 110], ["STATUS", 90], ["SPEED", 70],
                                ["COOLANT", 80], ["BRAKE", 70], ["LINK", 60]]
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
                    model: Vehicle.fleet
                    currentIndex: screen.selectedRow

                    delegate: Rectangle {
                        required property int index
                        required property string unitId
                        required property string status
                        required property int speed
                        required property int coolant
                        required property int brakeTemp
                        required property int link

                        width: ListView.view.width
                        height: 38
                        color: index === screen.selectedRow ? "#1A1509" : "transparent"

                        Rectangle {
                            width: 2; height: parent.height
                            color: Theme.accent
                            visible: index === screen.selectedRow
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 1; color: "#141A21"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            Text {
                                Layout.preferredWidth: 110; text: unitId; color: Theme.ink
                                font.family: Theme.faceData; font.pixelSize: 13
                            }
                            Item {
                                Layout.preferredWidth: 90
                                Rectangle {
                                    width: label.width + 16; height: 19; radius: 10
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Vehicle.statusColor(status)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        text: status.toUpperCase()
                                        color: Vehicle.statusColor(status)
                                        font.family: Theme.faceData; font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 70; text: speed; color: Theme.ink
                                font.family: Theme.faceData; font.pixelSize: 13
                            }
                            Text {
                                Layout.preferredWidth: 80; text: coolant
                                color: coolant > 100 ? Theme.ttRed : Theme.ink
                                font.family: Theme.faceData; font.pixelSize: 13
                            }
                            Text {
                                Layout.preferredWidth: 70; text: brakeTemp
                                color: brakeTemp > 400 ? Theme.ttRed : Theme.ink
                                font.family: Theme.faceData; font.pixelSize: 13
                            }
                            Text {
                                Layout.preferredWidth: 60; text: link
                                color: Theme.ink
                                font.family: Theme.faceData; font.pixelSize: 13
                            }
                            Item { Layout.fillWidth: true }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: screen.selectedRow = index
                        }
                    }
                }
            }

            // ---------------- detail pane ----------------------------
            Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                color: "transparent"

                Rectangle { width: 1; height: parent.height; color: Theme.rule }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    spacing: 0

                    Text {
                        text: Vehicle.fleet.field(screen.selectedRow, "unitId")
                        color: Theme.ink
                        font.family: Theme.faceUi; font.pixelSize: 20; font.bold: true
                    }
                    Text {
                        Layout.bottomMargin: 14
                        text: Vehicle.fleet.field(screen.selectedRow, "make").toUpperCase()
                              + "  \u00B7  "
                              + Vehicle.fleet.field(screen.selectedRow, "status").toUpperCase()
                        color: Theme.accent
                        font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.6
                    }

                    Repeater {
                        model: [["POSITION", "pos"], ["FIX", "fix"], ["ENGINE HRS", "hours"],
                                ["ODOMETER", "odo"], ["FUEL", "fuel"],
                                ["LAST DTC", "dtc"], ["UPTIME", "uptime"]]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            Text {
                                text: modelData[0]
                                color: Theme.dim
                                font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.4
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Vehicle.fleet.field(screen.selectedRow, modelData[1])
                                color: Theme.ink
                                font.family: Theme.faceData; font.pixelSize: 12
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
