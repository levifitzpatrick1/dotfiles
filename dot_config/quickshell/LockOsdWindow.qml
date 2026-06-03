import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: lockOsdWindow
    color: "transparent"

    // Centered horizontally at the bottom of the screen
    anchors {
        bottom: true
    }

    implicitWidth: 220
    implicitHeight: 56
    margins {
        bottom: 140
    }

    exclusiveZone: -1
    aboveWindows: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell"

    focusable: false
    visible: false

    // =============================================================================
    // DYNAMIC REACTIVE THEME SYSTEM
    // =============================================================================

    property var themeColors: getThemeColors("")

    FileView {
        id: jsonThemeFile
        path: "/home/levi/.config/hypr/current_theme/theme_colors.json"
        watchChanges: true
        onLoaded: themeColors = getThemeColors(text())
        onTextChanged: themeColors = getThemeColors(text())
    }

    function getThemeColors(txt) {
        try {
            if (txt && txt.length > 0) {
                return JSON.parse(txt);
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
            if (m) {
                return Qt.rgba(parseInt(m[1])/255, parseInt(m[2])/255, parseInt(m[3])/255, parseFloat(m[4]));
            }
        }
        return str;
    }

    function getThemeColor(colorName, fallback) {
        if (themeColors && themeColors[colorName] !== undefined) {
            return themeColors[colorName];
        }
        return fallback;
    }

    // =============================================================================
    // STATE & IPC CONTROLLER
    // =============================================================================
    property string activeLock: "caps" // "caps" | "num"
    property bool lockState: false
    property real contentOpacity: 0.0

    IpcHandler {
        target: "lockosd"

        function showCaps(active: string): void {
            activeLock = "caps";
            var actStr = active ? active.toString().trim() : "false";
            lockState = (actStr === "true" || actStr === "1");
            triggerShow();
        }

        function showNum(active: string): void {
            activeLock = "num";
            var actStr = active ? active.toString().trim() : "false";
            lockState = (actStr === "true" || actStr === "1");
            triggerShow();
        }
    }

    function triggerShow() {
        dismissTimer.stop();
        hideDelay.stop();
        lockOsdWindow.visible = true;
        contentOpacity = 1.0;
        
        slideAnimation.from = 160;
        slideAnimation.to = 140;
        slideAnimation.start();
        
        dismissTimer.start();
    }

    Timer {
        id: dismissTimer
        interval: 1500 // Dismisses lock indicators quickly after 1.5s
        running: false
        repeat: false
        onTriggered: {
            contentOpacity = 0.0;
            hideDelay.start();
        }
    }

    Timer {
        id: hideDelay
        interval: 250
        running: false
        repeat: false
        onTriggered: {
            lockOsdWindow.visible = false;
        }
    }

    NumberAnimation {
        id: slideAnimation
        target: lockOsdWindow
        property: "margins.bottom"
        duration: 250
        easing.type: Easing.OutBack
    }

    // =============================================================================
    // DISPLAY CARD
    // =============================================================================
    property color panelBgColor: parseColor(getThemeColor("background", "rgba(7, 0, 31, 0.6)"), "rgba(7, 0, 31, 0.6)")

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Qt.rgba(panelBgColor.r, panelBgColor.g, panelBgColor.b, 0.6)
        border.color: lockState ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : parseColor(getThemeColor("border", "rgba(255, 255, 255, 0.08)"), "rgba(255, 255, 255, 0.08)")
        border.width: 1.5

        opacity: contentOpacity
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            // Lock status icon
            Text {
                text: {
                    if (activeLock === "caps") {
                        return lockState ? "󰌾" : "󰌿";
                    } else {
                        return lockState ? "󰎠" : "󰎣";
                    }
                }
                font.family: "Hack Nerd Font"
                font.pixelSize: 22
                color: lockState ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Lock text details
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                Text {
                    text: activeLock === "caps" ? "Caps Lock" : "Num Lock"
                    font.family: getThemeColor("fontFamily", "Comfortaa")
                    font.pixelSize: 13
                    font.bold: true
                    color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                }
                
                Text {
                    text: lockState ? "Enabled" : "Disabled"
                    font.family: getThemeColor("fontFamily", "Comfortaa")
                    font.pixelSize: 10
                    color: lockState ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                    font.bold: true
                }
            }
        }
    }
}
