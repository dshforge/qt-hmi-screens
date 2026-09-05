import QtQuick
import QtQuick.Layouts
import Screens
import Screens.Backend

/*  What this application does to itself, measured live.

    Nearly every OEM wants a correct cluster within two seconds of
    ignition, and a 60 Hz panel gives 16.7 ms a frame. Both are
    worst-case numbers, so this screen leads with p99 and max and
    puts the mean last.                                            */
Rectangle {
    id: screen
    color: Theme.bg

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "TIMING \u2014 THIS APPLICATION, MEASURED ON ITSELF"
                color: Theme.ink
                font.family: Theme.faceUi; font.pixelSize: 15; font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Frames.frameCount.toLocaleString(Qt.locale(), "f", 0) + " FRAMES SAMPLED"
                color: Theme.dim
                font.family: Theme.faceData; font.pixelSize: 12; font.letterSpacing: 1.6
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.rule }

        // ---------------- headline figures --------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 1

            Repeater {
                model: [
                    { k: "BOOT TO FIRST FRAME", v: Frames.bootMs.toFixed(0), u: "ms",
                      limit: Frames.bootBudget, raw: Frames.bootMs },
                    { k: "p99 FRAME", v: Frames.p99Ms.toFixed(1), u: "ms",
                      limit: Frames.budgetMs, raw: Frames.p99Ms },
                    { k: "WORST FRAME", v: Frames.maxMs.toFixed(1), u: "ms",
                      limit: Frames.budgetMs, raw: Frames.maxMs },
                    { k: "FRAMES OVER BUDGET", v: String(Frames.missedFrames), u: "",
                      limit: 1, raw: Frames.missedFrames }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool over: modelData.raw > modelData.limit

                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    color: Theme.panel

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4
                        Text {
                            text: modelData.k
                            color: Theme.dim
                            font.family: Theme.faceData; font.pixelSize: 10; font.letterSpacing: 1.5
                        }
                        Item { Layout.fillHeight: true }
                        RowLayout {
                            spacing: 6
                            Text {
                                text: modelData.v
                                color: over ? Theme.ttRed : Theme.ink
                                font.family: Theme.faceUi; font.pixelSize: 30; font.bold: true
                            }
                            Text {
                                Layout.alignment: Qt.AlignBaseline
                                text: modelData.u
                                color: Theme.dim
                                font.family: Theme.faceData; font.pixelSize: 13
                            }
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top
                        width: 3; height: parent.height
                        color: over ? Theme.ttRed : Theme.accent
                    }
                }
            }
        }

        // ---------------- distribution + budgets --------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 34

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Text {
                    text: "FRAME TIME DISTRIBUTION"
                    color: Theme.accent
                    font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 2
                }
                BarChart {
                    Layout.fillWidth: true
                    labels: Frames.buckets
                    values: Frames.histogram
                    barColor: Theme.cyan
                    alertFrom: 4                 // buckets past 16.7 ms
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: "Anything past 16.7 ms missed the vsync deadline on a 60 Hz "
                          + "panel. The mean hides these; the histogram does not."
                    color: Theme.faint
                    font.family: Theme.faceUi; font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 320
                Layout.maximumWidth: 320
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Text {
                    text: "PERCENTILES"
                    color: Theme.accent
                    font.family: Theme.faceData; font.pixelSize: 11; font.letterSpacing: 2
                }
                Repeater {
                    model: [
                        ["p50 (median)", Frames.p50Ms],
                        ["p95",          Frames.p95Ms],
                        ["p99",          Frames.p99Ms],
                        ["max",          Frames.maxMs],
                        ["mean",         Frames.meanMs]
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Text {
                            text: modelData[0]
                            color: Theme.dim
                            font.family: Theme.faceData; font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Number(modelData[1]).toFixed(2) + " ms"
                            color: Number(modelData[1]) > Frames.budgetMs ? Theme.ttRed : Theme.ink
                            font.family: Theme.faceData; font.pixelSize: 12
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.topMargin: 8; height: 1; color: Theme.rule }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: "Budget 16.67 ms at 60 Hz. Boot budget 2000 ms \u2014 the "
                          + "window most OEMs allow between ignition and a correct "
                          + "cluster."
                    color: Theme.faint
                    font.family: Theme.faceUi; font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
