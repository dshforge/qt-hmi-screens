import QtQuick
import QtQuick.Layouts
import Screens

/*  Dual-zone climate control.

    The setpoints live here rather than in C++ on purpose: until this is
    bound to a real HVAC controller they are view state, not vehicle
    state, and pushing them down would invent a model that has nothing
    behind it yet. The binding point is one property per control.     */
Rectangle {
    id: screen
    color: Theme.bg

    property real driverTemp: 21.5
    property real passengerTemp: 22.0
    property int  fanSpeed: 4
    property string mode: "face+feet"
    property bool acOn: true
    property bool recirc: false
    property bool rearDefrost: false
    property int  driverSeat: 2
    property int  passengerSeat: 0

    component ZoneDial: ColumnLayout {
        id: zone
        property string title: ""
        property real value: 21.0
        property int seatLevel: 0
        signal bump(real delta)
        signal cycleSeat()

        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: zone.title
            color: Theme.dim
            font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 2
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Rectangle {
                implicitWidth: 40; implicitHeight: 40; radius: 20
                color: dn.pressed ? Theme.rule : "transparent"
                border.width: 1; border.color: Theme.rule
                Text {
                    anchors.centerIn: parent; text: "\u2212"
                    color: Theme.ink; font.pixelSize: 20; font.family: Theme.faceUi
                }
                MouseArea {
                    id: dn; anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: zone.bump(-0.5)
                }
            }

            Text {
                text: zone.value.toFixed(1) + "\u00B0"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 46; font.bold: true
            }

            Rectangle {
                implicitWidth: 40; implicitHeight: 40; radius: 20
                color: up.pressed ? Theme.rule : "transparent"
                border.width: 1; border.color: Theme.rule
                Text {
                    anchors.centerIn: parent; text: "+"
                    color: Theme.ink; font.pixelSize: 20; font.family: Theme.faceUi
                }
                MouseArea {
                    id: up; anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: zone.bump(0.5)
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Text {
                text: "SEAT"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.5
            }
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    implicitWidth: 22; implicitHeight: 8; radius: 2
                    color: index < zone.seatLevel ? Theme.accent : Theme.rule
                }
            }
            MouseArea {
                implicitWidth: 24; implicitHeight: 20
                cursorShape: Qt.PointingHandCursor
                onClicked: zone.cycleSeat()
                Text {
                    anchors.centerIn: parent; text: "\u25B8"
                    color: Theme.dim; font.pixelSize: 12
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "CLIMATE"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "CABIN 19\u00B0  \u00B7  OUTSIDE 31\u00B0"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 1.6
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        // ---------------- the two zones -----------------------------
        //
        // The zones sit in bare Items rather than filling the row
        // directly: a ColumnLayout carries its content's implicit
        // width into the parent layout, and the wider of the two then
        // takes the leftover space instead of the row splitting evenly.
        // An empty Item has nothing to contribute, so the halves match.
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 10
            Layout.maximumHeight: 250
            spacing: 40

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ZoneDial {
                    anchors.centerIn: parent
                    title: "DRIVER"
                    value: screen.driverTemp
                    seatLevel: screen.driverSeat
                    onBump: function(d) {
                        screen.driverTemp = Math.min(28, Math.max(16, screen.driverTemp + d))
                    }
                    onCycleSeat: screen.driverSeat = (screen.driverSeat + 1) % 4
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.rule }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ZoneDial {
                    anchors.centerIn: parent
                    title: "PASSENGER"
                    value: screen.passengerTemp
                    seatLevel: screen.passengerSeat
                    onBump: function(d) {
                        screen.passengerTemp = Math.min(28, Math.max(16, screen.passengerTemp + d))
                    }
                    onCycleSeat: screen.passengerSeat = (screen.passengerSeat + 1) % 4
                }
            }
        }

        // ---------------- fan ---------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 8
            Text {
                text: "FAN"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 2
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: 7
                    delegate: Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30 + index * 4
                        Layout.alignment: Qt.AlignBottom
                        radius: 2
                        color: index < screen.fanSpeed ? Theme.accent : Theme.panel
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: screen.fanSpeed = index + 1
                        }
                    }
                }
            }
        }

        // ---------------- modes and toggles -------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 10

            Repeater {
                model: ["face", "face+feet", "feet", "defrost"]
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool on: screen.mode === modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 4
                    color: on ? Theme.accent : Theme.panel
                    Text {
                        anchors.centerIn: parent
                        text: modelData.toUpperCase()
                        color: on ? Theme.bg : Theme.dim
                        font.family: Theme.faceData; font.pixelSize: 11
                        font.letterSpacing: 1.4; font.bold: on
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: screen.mode = modelData
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: [
                    { label: "A/C",         key: "acOn" },
                    { label: "RECIRC",      key: "recirc" },
                    { label: "REAR DEFROST", key: "rearDefrost" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: screen[modelData.key]
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: on ? Theme.accent : Theme.rule
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 9
                        Rectangle {
                            implicitWidth: 7; implicitHeight: 7; radius: 4
                            color: on ? Theme.accent : Theme.faint
                        }
                        Text {
                            text: modelData.label
                            color: on ? Theme.ink : Theme.dim
                            font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.4
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: screen[modelData.key] = !screen[modelData.key]
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
