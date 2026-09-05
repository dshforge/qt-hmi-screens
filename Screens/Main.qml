import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Screens
import Screens.Backend

ApplicationWindow {
    id: app
    width: 1280
    height: 720
    minimumWidth: 960
    minimumHeight: 560
    visible: true
    title: "HMI Screens"
    color: Theme.bezel

    // One list drives the tab strip, the stack order and the number
    // shortcuts, so they cannot drift apart when a screen is added.
    // Loads once, on first selection, and stays loaded afterwards so
    // switching back is instant.
    component LazyScreen: Loader {
        property int slot: -1
        readonly property bool wanted: stack.currentIndex === slot
        active: false
        onWantedChanged: if (wanted) active = true
    }

    Component { id: cHeavy;    HeavyScreen {} }
    Component { id: cClimate;  ClimateScreen {} }
    Component { id: cMedical;    MedicalScreen {} }
    Component { id: cInstrument; InstrumentScreen {} }
    Component { id: cScada;      ScadaScreen {} }
    Component { id: cFleet;      FleetScreen {} }
    Component { id: cCan;      CanScreen {} }
    Component { id: cTiming;   TimingScreen {} }

    readonly property var screens: [
        "CLUSTER", "HEAVY", "CLIMATE", "PATIENT", "SPECTRUM", "PLANT",
        "FLEET", "CAN BUS", "TIMING"
    ]

    // In solo mode the screen is the whole window: no brand bar, no tab
    // strip, no footer. Each design then stands on its own.
    readonly property bool solo: typeof soloMode !== "undefined" && soloMode

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: app.solo ? 0 : 10
        spacing: app.solo ? 0 : 8

        // ---------------- bezel header ----------------------------
        RowLayout {
            visible: !app.solo
            Layout.preferredHeight: app.solo ? 0 : implicitHeight
            Layout.fillWidth: true
            Layout.leftMargin: 6
            spacing: 14

            Text {
                text: "HMI"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
                font.letterSpacing: 1
            }
            Text {
                text: "SCREENS"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.8
            }

            Item { Layout.fillWidth: true }

            Flow {
                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth
                spacing: 2
                layoutDirection: Qt.LeftToRight

            Repeater {
                model: app.screens
                delegate: Rectangle {
                    required property int index
                    required property string modelData
                    readonly property bool on: stack.currentIndex === index

                    implicitWidth: tabText.width + 26
                    implicitHeight: 28
                    radius: 4
                    color: on ? Theme.accent : "transparent"

                    Text {
                        id: tabText
                        anchors.centerIn: parent
                        text: modelData
                        color: on ? Theme.bg : Theme.dim
                        font.family: Theme.faceData
                        font.pixelSize: 11
                        font.letterSpacing: 1.6
                        font.bold: on
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stack.currentIndex = index
                    }
                }
            }
            }
        }

        // ---------------- screen ----------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: app.solo ? 0 : 6
            color: Theme.bg
            clip: true

            StackLayout {
                id: stack
                anchors.fill: parent
                currentIndex: Math.max(0, Math.min(app.screens.length - 1,
                                                   typeof startScreen !== "undefined"
                                                   ? startScreen : 0))

                // The cluster is built eagerly because it is what the
                // first frame has to show. Everything else loads the
                // first time it is selected and then stays loaded --
                // a StackLayout instantiates all of its children up
                // front otherwise, and every one of them lands on the
                // boot path in front of the first frame.
                ClusterScreen {}

                LazyScreen { slot: 1; sourceComponent: cHeavy }
                LazyScreen { slot: 2; sourceComponent: cClimate }
                LazyScreen { slot: 3; sourceComponent: cMedical }
                LazyScreen { slot: 4; sourceComponent: cInstrument }
                LazyScreen { slot: 5; sourceComponent: cScada }
                LazyScreen { slot: 6; sourceComponent: cFleet }
                LazyScreen { slot: 7; sourceComponent: cCan }
                LazyScreen { slot: 8; sourceComponent: cTiming }
            }
        }

        // ---------------- bezel footer ----------------------------
        RowLayout {
            visible: !app.solo
            Layout.preferredHeight: app.solo ? 0 : implicitHeight
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Text {
                text: "Qt " + Vehicle.qtVersion + "  \u00B7  Qt Quick / QML  \u00B7  "
                      + "RHI / " + Frames.graphicsApi
                color: Theme.faint
                font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.2
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "fake data, real render loop"
                color: Theme.faint
                font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 1.2
            }
        }
    }

    // Space bar pauses the drive cycle -- useful when demoing a value.
    Shortcut {
        sequence: "Space"
        onActivated: Vehicle.running = !Vehicle.running
    }
    // Number keys jump straight to a screen, which is faster than
    // reaching for the mouse midway through showing someone the app.
    Repeater {
        model: Math.min(app.screens.length, 9)
        delegate: Item {
            required property int index
            Shortcut {
                sequence: String(index + 1)
                onActivated: stack.currentIndex = index
            }
        }
    }
}
