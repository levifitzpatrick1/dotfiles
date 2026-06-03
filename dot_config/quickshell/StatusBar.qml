import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: barWindow
    color: "transparent"

    property var controlCenter
    property var calendarWindow
    property int activeWorkspaceId: 1
    property var occupiedWorkspaces: [1]
    property string currentClockText: ""

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 44
    margins {
        top: 8
        left: 12
        right: 12
    }

    exclusiveZone: 52
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    focusable: false

    property var themeColors: getThemeColors("")

    FileView {
        id: jsonThemeFile
        path: "/home/levi/.config/hypr/current_theme/theme_colors.json"
        watchChanges: true
        onLoaded: themeColors = getThemeColors(text())
        onTextChanged: themeColors = getThemeColors(text())
    }

    function getThemeColors(text) {
        try {
            if (text && text.length > 0) {
                return JSON.parse(text);
            }
        } catch (e) {}
        return {
            "primary": "#d0bcff",
            "onPrimary": "#07001f",
            "primaryContainer": "rgba(208, 188, 255, 0.18)",
            "background": "rgba(7, 0, 31, 0.72)",
            "surface": "rgba(24, 18, 43, 0.68)",
            "text": "#e6e1e5",
            "subtext": "#cac4d0",
            "border": "rgba(208, 188, 255, 0.28)",
            "fontFamily": "Comfortaa"
        };
    }

    function parseColor(str, fallback) {
        if (!str) return fallback;
        if (str.indexOf("#") === 0) return str;
        if (str.indexOf("rgba") === 0) {
            var m = str.match(/rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)/);
            if (m) return Qt.rgba(parseInt(m[1]) / 255, parseInt(m[2]) / 255, parseInt(m[3]) / 255, parseFloat(m[4]));
        }
        return fallback;
    }

    function getThemeColor(name, fallback) {
        return themeColors && themeColors[name] !== undefined ? themeColors[name] : fallback;
    }

    function formatClock() {
        var d = new Date();
        var hours = d.getHours();
        var minutes = d.getMinutes();
        var ampm = hours >= 12 ? "PM" : "AM";
        hours = hours % 12;
        if (hours === 0) hours = 12;
        var min = minutes < 10 ? "0" + minutes : minutes.toString();
        return hours + ":" + min + " " + ampm;
    }

    function workspaceOccupied(id) {
        for (var i = 0; i < occupiedWorkspaces.length; i++) {
            if (occupiedWorkspaces[i] === id) return true;
        }
        return false;
    }

    function queryWorkspaces() {
        activeWorkspaceQuery.running = true;
        workspacesQuery.running = true;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: currentClockText = formatClock()
    }

    Timer {
        interval: 250
        running: true
        repeat: false
        onTriggered: queryWorkspaces()
    }

    Process {
        id: workspaceSwitchProcess
        running: false
    }

    Process {
        id: eventSocket
        command: ["socat", "-U", "-", "UNIX-CONNECT:" + Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.indexOf("workspace>>") === 0 ||
                    line.indexOf("focusedmon>>") === 0 ||
                    line.indexOf("createworkspace>>") === 0 ||
                    line.indexOf("destroyworkspace>>") === 0 ||
                    line.indexOf("openwindow>>") === 0 ||
                    line.indexOf("closewindow>>") === 0 ||
                    line.indexOf("movewindow>>") === 0) {
                    queryWorkspaces();
                }
            }
        }
    }

    Process {
        id: activeWorkspaceQuery
        command: ["hyprctl", "activeworkspace", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var json = JSON.parse(this.text);
                    if (json && json.id) activeWorkspaceId = json.id;
                } catch (e) {}
            }
        }
    }

    Process {
        id: workspacesQuery
        command: ["hyprctl", "workspaces", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var list = JSON.parse(this.text);
                    var occupied = [];
                    for (var i = 0; i < list.length; i++) occupied.push(list[i].id);
                    occupiedWorkspaces = occupied;
                } catch (e) {}
            }
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: workspaceCapsule
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 166
            height: 36
            radius: 18
            color: parseColor(getThemeColor("background", "rgba(7, 0, 31, 0.72)"), Qt.rgba(7/255, 0/255, 31/255, 0.72))
            border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: 5

                    Rectangle {
                        id: workspaceDot
                        property int workspaceId: index + 1
                        property bool active: activeWorkspaceId === workspaceId
                        property bool occupied: workspaceOccupied(workspaceId)

                        width: active ? 32 : (occupied ? 13 : 9)
                        height: active ? 13 : 9
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: active
                            ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                            : occupied
                                ? parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), Qt.rgba(208/255, 188/255, 255/255, 0.18))
                                : Qt.rgba(1, 1, 1, 0.22)
                        border.width: active ? 0 : 1
                        border.color: occupied ? parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28)) : "transparent"

                        Behavior on width {
                            NumberAnimation { duration: 180; easing.type: Easing.OutQuint }
                        }
                        Behavior on height {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 160 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                workspaceSwitchProcess.command = ["hyprctl", "dispatch", "workspace", workspaceId.toString()];
                                workspaceSwitchProcess.running = true;
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: clockCapsule
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 132
            height: 36
            radius: 18
            color: parseColor(getThemeColor("background", "rgba(7, 0, 31, 0.72)"), Qt.rgba(7/255, 0/255, 31/255, 0.72))
            border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: currentClockText
                color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                font.family: getThemeColor("fontFamily", "Comfortaa")
                font.pixelSize: 18
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (calendarWindow && calendarWindow.toggle) calendarWindow.toggle();
                }
            }
        }

        Rectangle {
            id: controlCapsule
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            height: 36
            radius: 18
            color: controlMouse.containsMouse
                ? parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), Qt.rgba(208/255, 188/255, 255/255, 0.18))
                : parseColor(getThemeColor("background", "rgba(7, 0, 31, 0.72)"), Qt.rgba(7/255, 0/255, 31/255, 0.72))
            border.color: controlMouse.containsMouse
                ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                : parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 140 }
            }
            Behavior on border.color {
                ColorAnimation { duration: 140 }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "Hack Nerd Font"
                font.pixelSize: 20
                color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
            }

            MouseArea {
                id: controlMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (controlCenter && controlCenter.toggle) controlCenter.toggle();
                }
            }
        }
    }
}
