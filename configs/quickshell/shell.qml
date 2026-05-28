import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property alias zyuTheme: zyuTheme
    property bool musicVisible: false
    property bool wifiVisible: false

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell"
    readonly property string cacheThemePath: Quickshell.env("HOME") + "/.cache/kaizen/theme/colors.json"
    readonly property string compPath: configPath + "/components"

    QtObject {
        id: zyuTheme
        property color bar_bg: "#06080c"
        property color bar_fg: "#f4f2ff"
        property color accent: "#9d7cff"
        property color accent2: "#67d8ff"
        property color widget_bg: "#141420"
        property color border: "#2d2940"
        property int bar_height: 50
        property int rounding: 18
    }

    Process {
        id: colorProc
        command: ["bash", "-c", "cat '" + cacheThemePath + "' 2>/dev/null || cat '" + configPath + "/Colors/colors.json' 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var c = JSON.parse(data)

                    if (c.background) zyuTheme.bar_bg = c.background
                    if (c.foreground) zyuTheme.bar_fg = c.foreground
                    if (c.on_surface) zyuTheme.bar_fg = c.on_surface

                    if (c.accent) zyuTheme.accent = c.accent
                    if (c.primary) zyuTheme.accent = c.primary

                    if (c.accent2) zyuTheme.accent2 = c.accent2
                    if (c.secondary) zyuTheme.accent2 = c.secondary

                    if (c.surface) zyuTheme.widget_bg = c.surface
                    if (c.surfaceAlt) zyuTheme.widget_bg = c.surfaceAlt
                    if (c.surface_container) zyuTheme.widget_bg = c.surface_container

                    if (c.border) zyuTheme.border = c.border
                    if (c.outline) zyuTheme.border = c.outline
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
    }

    Loader {
        source: compPath + "/Bar/bar.qml"
    }
}
