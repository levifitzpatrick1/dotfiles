import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

ShellRoot {
    id: root

    // ── Theme State (loaded dynamically from Brain Shell cache) ────────────────
    property color colorBackground: "#121216"
    property color colorActive:     "#89b4fa"
    property color colorText:       "#ebebf0"
    property color colorSubtext:    "#a0a0aa"
    property color colorBorder:     "#32323c"

    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/brain-shell/colors.json"
        watchChanges: true
        onLoaded: parse(text())
        onFileChanged: parse(text())

        function parse(raw) {
            if (!raw || raw.trim() === "") return
            try {
                var obj = JSON.parse(raw)
                if (obj.background) root.colorBackground = obj.background
                if (obj.active)     root.colorActive     = obj.active
                if (obj.text)       root.colorText       = obj.text
                if (obj.subtext)    root.colorSubtext    = obj.subtext
                if (obj.border)     root.colorBorder     = obj.border
            } catch(e) {}
        }
    }

    // ── OSD State & Logic ──────────────────────────────────────────────────────
    property string osdType: "volume" // "volume" | "brightness"
    property int osdLevel: 50          // 0 - 100
    property bool osdMuted: false      // true if volume is muted
    property bool osdActive: false     // true when OSD is visible

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: root.osdActive = false
    }

    function showOsd(type, level, muted) {
        root.osdType = type
        root.osdLevel = Math.max(0, Math.min(100, level))
        root.osdMuted = muted
        root.osdActive = true
        hideTimer.restart()
    }

    // ── IPC Handlers ───────────────────────────────────────────────────────────
    IpcHandler {
        target: "osd-volume"
        // Quickshell IPC calls are function calls
        function show(vol, muted) {
            root.showOsd("volume", parseInt(vol), muted === "true" || muted === true)
        }
    }

    IpcHandler {
        target: "osd-brightness"
        function show(pct) {
            root.showOsd("brightness", parseInt(pct), false)
        }
    }

    // ── HUD Floating Window ────────────────────────────────────────────────────
    PanelWindow {
        id: win
        
        // Small floating dimension
        width: 320
        height: 70
        
        // Center horizontally and place 100px above the bottom of the screen
        x: screen.x + (screen.width - width) / 2
        y: screen.y + screen.height - height - (root.osdActive ? 120 : 100)

        Behavior on y {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell" // Triggers blur from Hyprland layer rule!

        color: "transparent"

        // Make window visible only when active or animating
        visible: root.osdActive || container.opacity > 0.0

        // Pill-shaped container
        Rectangle {
            id: container
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(root.colorBackground.r, root.colorBackground.g, root.colorBackground.b, 0.8)
            border.width: 1
            border.color: root.colorBorder

            // Smooth fade transition on the visual container
            opacity: root.osdActive ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12
                verticalAlignment: Text.AlignVCenter

                // Icon (Nerd Font symbol)
                Text {
                    id: iconText
                    text: {
                        if (root.osdType === "brightness") {
                            return "󰃠"
                        } else {
                            if (root.osdMuted) return "󰝟"
                            if (root.osdLevel === 0) return "󰝟"
                            if (root.osdLevel < 33) return "󰕿"
                            if (root.osdLevel < 66) return "󰖀"
                            return "󰕾"
                        }
                    }
                    font.pixelSize: 20
                    color: root.colorActive
                    verticalAlignment: Text.AlignVCenter
                    width: 24
                }

                // Progress Bar
                Item {
                    width: 170
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter

                    // Background Track
                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Qt.rgba(root.colorBorder.r, root.colorBorder.g, root.colorBorder.b, 0.5)
                    }

                    // Active Fill
                    Rectangle {
                        height: parent.height
                        width: root.osdMuted ? 0 : (root.osdLevel * parent.width / 100)
                        radius: 3
                        color: root.colorActive

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }
                }

                // Level Text
                Text {
                    text: root.osdMuted ? "Muted" : root.osdLevel + "%"
                    font.family: "Comfortaa"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    width: 50
                }
            }
        }
    }
}
