import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

PanelWindow {
    id: osdWindow
    color: "transparent"

    // Placed vertically centered on the right edge of the screen
    anchors {
        right: true
    }

    implicitWidth: 54
    implicitHeight: 240
    margins {
        right: 32
    }

    exclusiveZone: -1
    aboveWindows: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell"

    focusable: false
    visible: false

    // =============================================================================
    // DYNAMIC REACTIVE THEME SYSTEM (Unifies with active theme)
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
    // SYSTEM TRACKING (VOLUME & BRIGHTNESS)
    // =============================================================================

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property string mode: "volume" // "volume" | "brightness"
    property real currentVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0.0
    property bool isMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    property real currentBrightness: 0.0
    
    property bool isInitialized: false
    property real contentOpacity: 0.0

    Timer {
        id: startupDelay
        interval: 1500
        running: true
        repeat: false
        onTriggered: {
            isInitialized = true;
        }
    }

    // Native Pipewire trigger for volume
    onCurrentVolumeChanged: {
        if (!isInitialized) return;
        mode = "volume";
        triggerShow();
    }

    onIsMutedChanged: {
        if (!isInitialized) return;
        mode = "volume";
        triggerShow();
    }

    // Custom IPC trigger for Brightness and other commands
    IpcHandler {
        target: "osd"

        function showBrightness(percent: real): void {
            mode = "brightness";
            currentBrightness = percent / 100.0;
            triggerShow();
        }
    }

    function triggerShow() {
        dismissTimer.stop();
        hideDelay.stop();
        osdWindow.visible = true;
        contentOpacity = 1.0;
        
        slideAnimation.from = 50;
        slideAnimation.to = 32;
        slideAnimation.start();
        
        dismissTimer.start();
    }

    Timer {
        id: dismissTimer
        interval: 1800 // Auto-fades after 1.8s
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
            osdWindow.visible = false;
        }
    }

    NumberAnimation {
        id: slideAnimation
        target: osdWindow
        property: "margins.right"
        duration: 250
        easing.type: Easing.OutBack
    }

    // =============================================================================
    // ANDROID-STYLE VERTICAL CAPSULE LAYOUT
    // =============================================================================

    property color panelBgColor: parseColor(getThemeColor("background", "rgba(17, 19, 15, 0.6)"), "rgba(17, 19, 15, 0.6)")

    Rectangle {
        anchors.fill: parent
        radius: 27
        color: Qt.rgba(panelBgColor.r, panelBgColor.g, panelBgColor.b, 0.6)
        border.color: parseColor(getThemeColor("border", "rgba(255, 255, 255, 0.08)"), "rgba(255, 255, 255, 0.08)")
        border.width: 1

        opacity: contentOpacity
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // The overall progress container track
        Rectangle {
            id: track
            anchors.fill: parent
            anchors.margins: 4
            radius: 23
            color: "#16ffffff"
            clip: true

            // Thick rising capsule progress fill
            Rectangle {
                id: progressFill
                width: parent.width
                anchors.bottom: parent.bottom
                radius: parent.radius
                color: {
                    if (mode === "volume" && isMuted) {
                        return parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0");
                    }
                    return parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff");
                }

                // Volume or Brightness vertical heights
                height: {
                    var val = (mode === "volume") ? currentVolume : currentBrightness;
                    return parent.height * Math.min(Math.max(val, 0.0), 1.0);
                }

                Behavior on height {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // Android-style Icon inside at the bottom
            Text {
                id: osdIcon
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                
                text: {
                    if (mode === "volume") {
                        if (isMuted || currentVolume <= 0.0) return "󰝟";
                        if (currentVolume < 0.3) return "󰕿";
                        if (currentVolume < 0.6) return "󰖀";
                        return "󰕾";
                    } else {
                        if (currentBrightness <= 0.0) return "󰃛";
                        if (currentBrightness < 0.4) return "󰃟";
                        return "󰃠";
                    }
                }
                font.family: "Hack Nerd Font"
                font.pixelSize: 18
                
                // Color switches dynamically if covered by the progress fill!
                color: {
                    var val = (mode === "volume") ? currentVolume : currentBrightness;
                    // Icon text is roughly 36px from bottom (margin 16 + size 20)
                    // If fill is high enough, paint contrast onPrimary color!
                    if (val > 0.15) {
                        return parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f");
                    }
                    return parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5");
                }

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }

            // Small text indicator at the top
            Text {
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (mode === "volume") {
                        return isMuted ? "MUT" : Math.round(currentVolume * 100);
                    } else {
                        return Math.round(currentBrightness * 100);
                    }
                }
                font.family: getThemeColor("fontFamily", "Comfortaa")
                font.pixelSize: 10
                font.bold: true
                
                // Color switches dynamically if progress fill covers the top
                color: {
                    var val = (mode === "volume") ? currentVolume : currentBrightness;
                    if (val > 0.9) {
                        return parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f");
                    }
                    return parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0");
                }

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
        }
    }
}
