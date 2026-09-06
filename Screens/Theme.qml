pragma Singleton
import QtQuick
import Screens.Backend

/*  The instrument palette.

    Telltale colours are not styling. ISO 2575 reserves red for stop,
    amber for act soon, green for function active and blue for main
    beam, so they are named here: one file for a homologation review,
    and no way for a screen to pick the wrong one quietly.           */
QtObject {
    // grounds
    readonly property color bg:        "#07090C"
    readonly property color panel:     "#0D1116"
    readonly property color bezel:     "#161A20"
    readonly property color rule:      "#1E2630"
    readonly property color track:     "#1A222C"

    // text
    readonly property color ink:       "#DCE3EC"
    readonly property color dim:       "#6E7986"
    readonly property color faint:     "#39424E"

    // data
    readonly property color accent:    "#F2A20C"
    readonly property color cyan:      "#4FD8E8"

    // ISO 2575 telltale set
    readonly property color ttRed:     "#FF5B4D"
    readonly property color ttAmber:   "#F2A20C"
    readonly property color ttGreen:   "#3FD07E"
    readonly property color ttBlue:    "#5B93F5"

    // type
    // Resolved in C++ against the families the machine actually has,
    // so this is a real name on every platform rather than a Windows
    // name that silently substitutes elsewhere. See src/typography.h.
    readonly property string faceUi:   Typography.ui
    readonly property string faceData: Typography.mono

    readonly property int gaugeStroke: 22
    readonly property real startAngle: 140   // degrees, 0 = 3 o'clock
    readonly property real sweepAngle: 260
}
