import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Variants {
    model: [Quickshell.screens[0]]

    PanelWindow {
        property var modelData
        screen: modelData
        id: barWindow

        anchors {
            top: true
            left: true
            bottom: true
        }

        implicitWidth: 50
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        visible: true

        readonly property bool hasMusic: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return false
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing ||
                    players[i].playbackState === MprisPlaybackState.Paused) return true
            }
            return false
        }

        readonly property var activePlayer: {
            var players = Mpris.players.values
            if (!players || players.length === 0) return null
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
            }
            return players.length > 0 ? players[0] : null
        }

        Rectangle {
            id: barRect
            anchors.fill: parent
            anchors.margins: 6
            anchors.rightMargin: 0

            color: Qt.rgba(zyuTheme.bar_bg.r, zyuTheme.bar_bg.g, zyuTheme.bar_bg.b, 0.82)
            radius: 18
            border.color: Qt.rgba(zyuTheme.border.r, zyuTheme.border.g, zyuTheme.border.b, 0.28)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 0

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 1

                    Text {
                        id: hourText
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: zyuTheme.bar_fg
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.bold: true

                        function updateTime() {
                            text = new Date().getHours().toString().padStart(2, "0")
                        }

                        Component.onCompleted: updateTime()
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 3
                        height: 3
                        radius: 999
                        color: zyuTheme.accent2
                        opacity: 0.7
                    }

                    Text {
                        id: minText
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: zyuTheme.accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.bold: true

                        function updateTime() {
                            text = new Date().getMinutes().toString().padStart(2, "0")
                        }

                        Component.onCompleted: updateTime()
                    }

                    Timer {
                        interval: 30000
                        running: true
                        repeat: true
                        onTriggered: {
                            hourText.updateTime()
                            minText.updateTime()
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 9
                    Layout.bottomMargin: 9
                    width: barRect.width - 18
                    height: 1
                    radius: 1
                    color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.08)
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Item {
                            width: 24
                            height: 24
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: modelData.id > 0 && modelData.id <= 9

                            property bool isActive: modelData.id === Hyprland.focusedMonitor?.activeWorkspace?.id

                            Rectangle {
                                anchors.centerIn: parent
                                width: isActive ? 12 : 4
                                height: isActive ? 12 : 4
                                radius: isActive ? 3 : 999
                                rotation: isActive ? 45 : 0
                                color: isActive ? "transparent" : zyuTheme.bar_fg
                                opacity: isActive ? 1.0 : 0.25
                                border.width: isActive ? 2 : 0
                                border.color: zyuTheme.accent

                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + modelData.id)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 9
                    Layout.bottomMargin: 9
                    width: barRect.width - 18
                    height: 1
                    radius: 1
                    color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.08)
                }

                Item {
                    Layout.fillHeight: true
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: barWindow.hasMusic ? 36 : 0
                    opacity: barWindow.hasMusic ? 1.0 : 0.0
                    clip: true

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        radius: 10
                        color: Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.14)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: barWindow.activePlayer ? (barWindow.activePlayer.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            sourceSize.width: 68
                            sourceSize.height: 68
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.musicVisible = !root.musicVisible
                        }
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: barWindow.hasMusic ? 8 : 0
                    Layout.preferredWidth: barRect.width
                    Layout.preferredHeight: barWindow.hasMusic ? musicTextCol.implicitWidth + 18 : 0
                    opacity: barWindow.hasMusic ? 1.0 : 0.0

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.musicVisible = !root.musicVisible
                    }

                    Column {
                        id: musicTextCol
                        anchors.centerIn: parent
                        spacing: 4
                        rotation: -90
                        transformOrigin: Item.Center

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: barWindow.activePlayer ? (barWindow.activePlayer.trackTitle || "") : ""
                            color: root.musicVisible ? zyuTheme.accent : zyuTheme.bar_fg
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: root.musicVisible ? 30 : 10
                            height: 1
                            radius: 1
                            color: zyuTheme.accent
                            opacity: 0.35

                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: barWindow.activePlayer ? (barWindow.activePlayer.trackArtist || "") : ""
                            color: zyuTheme.bar_fg
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            opacity: 0.45
                            visible: (barWindow.activePlayer?.trackArtist || "") !== ""
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: wifiMa.containsMouse || root.wifiVisible ? 30 : 0
                        height: width
                        radius: 9
                        color: root.wifiVisible
                            ? Qt.rgba(zyuTheme.accent.r, zyuTheme.accent.g, zyuTheme.accent.b, 0.18)
                            : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.07)

                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "◌"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 17
                        font.bold: true
                        color: root.wifiVisible ? zyuTheme.accent : Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, wifiMa.containsMouse ? 0.8 : 0.45)
                    }

                    MouseArea {
                        id: wifiMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wifiVisible = !root.wifiVisible
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: dashMa.containsMouse ? 30 : 0
                        height: width
                        radius: 9
                        color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, 0.07)

                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "◆"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        font.bold: true
                        color: Qt.rgba(zyuTheme.bar_fg.r, zyuTheme.bar_fg.g, zyuTheme.bar_fg.b, dashMa.containsMouse ? 0.8 : 0.45)
                    }

                    MouseArea {
                        id: dashMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("exec kaizen-welcome")
                    }
                }
            }
        }
    }
}
