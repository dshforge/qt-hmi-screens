import QtQuick
import QtQuick.Layouts
import Screens

/*  Horizontal bars over labelled buckets. One scale places both the bar
    and its axis label, so length and number cannot disagree.          */
Item {
    id: root

    property var labels: []
    property var values: []
    property color barColor: Theme.cyan
    property var alertFrom: -1          // index at/after which bars go red
    property int labelWidth: 78

    readonly property real peak: {
        var m = 1;
        for (var i = 0; i < values.length; ++i)
            m = Math.max(m, Number(values[i]) || 0);
        return m;
    }

    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 6

        Repeater {
            model: root.labels.length

            delegate: RowLayout {
                required property int index
                readonly property real value: Number(root.values[index]) || 0
                readonly property bool alert: root.alertFrom >= 0 && index >= root.alertFrom

                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.preferredWidth: root.labelWidth
                    Layout.maximumWidth: root.labelWidth
                    horizontalAlignment: Text.AlignRight
                    text: root.labels[index]
                    color: alert ? Theme.ttRed : Theme.dim
                    font.family: Theme.faceData
                    font.pixelSize: 11
                }

                Rectangle {                       // track
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14
                    color: Theme.panel
                    radius: 2

                    Rectangle {                   // bar
                        height: parent.height
                        radius: 2
                        width: Math.max(value > 0 ? 2 : 0,
                                        parent.width * (value / root.peak))
                        color: alert ? Theme.ttRed : root.barColor
                        Behavior on width { NumberAnimation { duration: 120 } }
                    }
                }

                Text {
                    Layout.preferredWidth: 62
                    Layout.maximumWidth: 62
                    text: value.toLocaleString(Qt.locale(), "f", 0)
                    color: alert ? Theme.ttRed : Theme.ink
                    font.family: Theme.faceData
                    font.pixelSize: 11
                }
            }
        }
    }
}
