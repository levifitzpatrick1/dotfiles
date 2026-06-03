import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: calendarWindow
    color: "transparent"

    anchors {
        top: true
    }

    implicitWidth: 340
    implicitHeight: 380
    margins {
        top: 50
    }

    exclusiveZone: -1
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell"
    visible: false

    property bool isOpen: false

    Timer {
        id: closeTimer
        interval: 200
        repeat: false
        onTriggered: calendarWindow.visible = false
    }

    property var themeColors: getThemeColors("")

    FileView {
        id: jsonThemeFile
        path: "/home/levi/.config/hypr/current_theme/theme_colors.json"
        watchChanges: true
        onLoaded: themeColors = getThemeColors(text())
        onTextChanged: themeColors = getThemeColors(text())
    }
    property date currentDate: new Date()

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            calendarWindow.toggle();
        }
    }

    function toggle() {
        if (isOpen) {
            isOpen = false;
            closeTimer.start();
        } else {
            closeTimer.stop();
            visible = true;
            isOpen = true;
        }
    }

    function getThemeColors(text) {
        try {
            if (text && text.length > 0) return JSON.parse(text);
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

    function daysInMonth(date) {
        return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
    }

    function firstDayOffset(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
    }

    Rectangle {
        id: containerRect
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: calendarWindow.isOpen ? 8 : -12
        opacity: calendarWindow.isOpen ? 1 : 0
        radius: 24
        color: parseColor(getThemeColor("background", "rgba(7, 0, 31, 0.72)"), Qt.rgba(7/255, 0/255, 31/255, 0.72))
        border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
        border.width: 1

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(currentDate, "MMMM yyyy")
                horizontalAlignment: Text.AlignHCenter
                font.family: getThemeColor("fontFamily", "Comfortaa")
                font.pixelSize: 18
                font.bold: true
                color: parseColor(getThemeColor("primary", "#d8c7a5"), "#d8c7a5")
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: parseColor(getThemeColor("subtext", "#a6afb7"), "#a6afb7")
                    }
                }

                Repeater {
                    model: 42
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 12
                        property int dayNumber: index - firstDayOffset(currentDate) + 1
                        property bool validDay: dayNumber > 0 && dayNumber <= daysInMonth(currentDate)
                        property bool today: validDay && dayNumber === new Date().getDate() && currentDate.getMonth() === new Date().getMonth() && currentDate.getFullYear() === new Date().getFullYear()
                        color: today ? parseColor(getThemeColor("primary", "#d8c7a5"), "#d8c7a5") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.validDay ? parent.dayNumber : ""
                            font.family: getThemeColor("fontFamily", "Comfortaa")
                            font.pixelSize: 13
                            font.bold: parent.today
                            color: parent.today ? parseColor(getThemeColor("onPrimary", "#11130f"), "#11130f") : parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                        }
                    }
                }
            }
        }
    }
}
