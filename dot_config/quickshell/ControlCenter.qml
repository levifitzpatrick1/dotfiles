import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Wayland

PanelWindow {
    id: controlCenterWindow
    color: "transparent"
    
    // Position floating panel on the top-right, aligned with the status bar margins
    anchors {
        right: true
        top: true
    }
    
    // Display configuration
    implicitWidth: 360
    implicitHeight: 520
    margins {
        top: 50  // Below the status bar
        right: 12
    }
    
    // Ensure the panel does not reserve screen space and floats over standard windows
    exclusiveZone: -1
    aboveWindows: true
    
    // Place in Wayland's Overlay layer so it floats above normal application windows
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell" // Explicit namespace for Hyprland layer rules
    
    // Default hidden; toggled via Quickshell IPC or Hyprland keybinds
    visible: false

    property bool isOpen: false

    Timer {
        id: closeTimer
        interval: 200
        repeat: false
        onTriggered: controlCenterWindow.visible = false
    }

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

    // =============================================================================
    // IPC HANDLER & SYSTEM STATE
    // =============================================================================

    IpcHandler {
        target: "controlcenter"
        
        // Expose a toggling hook for Quickshell IPC and keyboard shortcuts
        function toggle(): void {
            controlCenterWindow.toggle()
        }
    }

    // Pipewire Tracker for automatic, real-time volume state syncing
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property real currentVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0.0
    property bool isMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    // Quick Toggles local state variables
    property string activeNetworkType: "none"
    property string activeNetworkName: "Disconnected"
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false

    // Background timers for polling system states (low overhead, runs every 5 seconds)
    Timer {
        id: statusPoller
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiCheck.running = true;
            bluetoothCheck.running = true;
            networkCheck.running = true;
        }
    }

    // Process to safely query wifi state
    Process {
        id: wifiCheck
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                wifiEnabled = (this.text.trim() === "enabled");
            }
        }
    }

    // Process to safely query active primary network connection
    Process {
        id: networkCheck
        command: ["sh", "-c", "if nmcli -t -f TYPE connection show --active | grep -q '802-3-ethernet'; then echo 'ethernet|Wired'; elif nmcli -t -f TYPE connection show --active | grep -q '802-11-wireless'; then ssid=$(nmcli -t -f ACTIVE,TYPE,NAME connection show --active | grep '802-11-wireless' | head -n 1 | cut -d: -f3); echo \"wifi|$ssid\"; else echo 'none|Disconnected'; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|");
                if (parts.length === 2) {
                    activeNetworkType = parts[0];
                    activeNetworkName = parts[1];
                }
            }
        }
    }

    // Process to safely query bluetooth state
    Process {
        id: bluetoothCheck
        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                bluetoothEnabled = (this.text.trim() === "yes");
            }
        }
    }

    // Submenu expanded state and results
    property string activeSubmenu: ""
    property var wifiNetworks: []
    property var bluetoothDevices: []

    // Background process to query nearby Wi-Fi networks list
    Process {
        id: wifiListQuery
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,BARS", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                parseWifiList(this.text);
            }
        }
    }

    // Background process to query paired Bluetooth devices
    Process {
        id: bluetoothListQuery
        command: ["bluetoothctl", "devices"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                parseBluetoothList(this.text);
            }
        }
    }

    // General purpose shell runner for network toggling/connect actions
    Process {
        id: wifiActionRunner
        running: false
    }

    function parseWifiList(text) {
        try {
            var lines = text.trim().split("\n");
            var list = [];
            var ssids = {};
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split(":");
                if (parts.length >= 3) {
                    var active = parts[0] === "yes";
                    var ssid = parts[1].trim();
                    var signal = parseInt(parts[2]);
                    var bars = parts[3] || "▂▄▆█";
                    if (ssid && !ssids[ssid]) {
                        ssids[ssid] = true;
                        list.push({ "active": active, "ssid": ssid, "signal": signal, "bars": bars });
                    }
                }
            }
            list.sort((a, b) => {
                if (a.active) return -1;
                if (b.active) return 1;
                return b.signal - a.signal;
            });
            wifiNetworks = list;
        } catch(e) {}
    }

    function parseBluetoothList(text) {
        try {
            var lines = text.trim().split("\n");
            var list = [];
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.indexOf("Device ") === 0) {
                    var rest = line.substring(7);
                    var space = rest.indexOf(" ");
                    if (space !== -1) {
                        var mac = rest.substring(0, space);
                        var name = rest.substring(space + 1);
                        list.push({ "mac": mac, "name": name });
                    }
                }
            }
            bluetoothDevices = list;
        } catch(e) {}
    }

    Process {
        id: powerRunner
        running: false
    }

    // =============================================================================
    // MPRIS MEDIA PLAYER RESOLVER
    // =============================================================================
    
    // Dynamically resolves the active player (preferring playing, fallback to first available)
    readonly property var activePlayer: {
        var players = Mpris.players.values;
        if (!players || players.length === 0) return null;
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) {
                return players[i];
            }
        }
        return players[0];
    }

    // Smooth position updates for MPRIS slider without heavy CPU overhead
    Timer {
        id: mediaPositionPoller
        interval: 250
        running: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (activePlayer) activePlayer.positionChanged();
        }
    }

    // =============================================================================
    // UI LAYOUT AND AESTHETICS (Catppuccin Mocha glassmorphism style)
    // =============================================================================

    Rectangle {
        id: mainContainer
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: controlCenterWindow.isOpen ? 0 : -20
        opacity: controlCenterWindow.isOpen ? 1 : 0
        color: parseColor(getThemeColor("background", "rgba(7, 0, 31, 0.72)"), Qt.rgba(7/255, 0/255, 31/255, 0.72))
        radius: 20
        border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
        border.width: 1

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Inner Padding / Margins
        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16
            visible: opacity > 0
            opacity: activeSubmenu === "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: "Control Center"
                    color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                    font.family: getThemeColor("fontFamily", "Comfortaa")
                    font.pixelSize: 22
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: controlCenterWindow.toggle()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 12

                // --- Wi-Fi Pill (Android Style) ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 16
                    color: wifiEnabled ? parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), Qt.rgba(208/255, 188/255, 255/255, 0.18)) : parseColor(getThemeColor("surface", "rgba(24, 18, 43, 0.68)"), Qt.rgba(24/255, 18/255, 43/255, 0.68))
                    border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Left Icon inside a small circle
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: wifiEnabled ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: activeNetworkType === "ethernet" ? "󰈀" : "󰤨"
                                color: wifiEnabled ? parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f") : parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 16
                            }
                        }

                        // Right Text Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Wi-Fi"
                                color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                text: activeNetworkName
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Far Right Chevron
                        Text {
                            text: ""
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 11
                            color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.x < 52) {
                                // Left icon area: toggle power state
                                wifiEnabled = !wifiEnabled;
                                wifiActionRunner.command = ["nmcli", "radio", "wifi", wifiEnabled ? "on" : "off"];
                                wifiActionRunner.running = true;
                            } else {
                                // Right text/chevron area: open connections list takeover
                                activeSubmenu = "wifi";
                                wifiListQuery.running = true;
                            }
                        }
                    }
                }

                // --- Bluetooth Pill (Android Style) ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 16
                    color: bluetoothEnabled ? parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), Qt.rgba(208/255, 188/255, 255/255, 0.18)) : parseColor(getThemeColor("surface", "rgba(24, 18, 43, 0.68)"), Qt.rgba(24/255, 18/255, 43/255, 0.68))
                    border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Left Icon inside a small circle
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: bluetoothEnabled ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: "󰂯"
                                color: bluetoothEnabled ? parseColor(getThemeColor("onPrimary", "#07001f"), "#07001f") : parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 16
                            }
                        }

                        // Right Text Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Bluetooth"
                                color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                text: bluetoothEnabled ? "On" : "Off"
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Far Right Chevron
                        Text {
                            text: ""
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 11
                            color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.x < 52) {
                                // Left icon area: toggle power state
                                bluetoothEnabled = !bluetoothEnabled;
                                wifiActionRunner.command = ["bluetoothctl", bluetoothEnabled ? "power on" : "power off"];
                                wifiActionRunner.running = true;
                            } else {
                                // Right text/chevron area: open bluetooth connections takeover
                                activeSubmenu = "bluetooth";
                                bluetoothListQuery.running = true;
                            }
                        }
                    }
                }
            }



            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: isMuted ? "󰖁" : "󰕾"
                        color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                        font.family: "Hack Nerd Font"
                        font.pixelSize: 22
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Volume"
                        color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        text: Math.round(currentVolume * 100) + "%"
                        color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.10)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(currentVolume, 1))
                        radius: 6
                        color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { "label": "Lock", "icon": "", "command": "hyprlock" },
                        { "label": "Log out", "icon": "󰍃", "command": "hyprctl dispatch exit" },
                        { "label": "Restart", "icon": "", "command": "systemctl reboot" },
                        { "label": "Shutdown", "icon": "", "command": "systemctl poweroff" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        radius: 16
                        color: powerMouse.containsMouse ? parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), Qt.rgba(208/255, 188/255, 255/255, 0.18)) : parseColor(getThemeColor("surface", "rgba(24, 18, 43, 0.68)"), Qt.rgba(24/255, 18/255, 43/255, 0.68))
                        border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 17
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: 68
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                powerRunner.command = ["bash", "-lc", modelData.command];
                                powerRunner.running = true;
                                controlCenterWindow.visible = false;
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: mprisCard
                Layout.fillWidth: true
                Layout.preferredHeight: 116
                radius: 18
                color: parseColor(getThemeColor("surface", "rgba(24, 18, 43, 0.68)"), Qt.rgba(24/255, 18/255, 43/255, 0.68))
                border.color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
                border.width: 1
                clip: true // Keep blurred background within rounded corners

                // --- 1. Blurred Artwork Background ---
                Image {
                    id: cardBgArt
                    anchors.fill: parent
                    source: activePlayer && activePlayer.trackArtwork ? activePlayer.trackArtwork : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false // MultiEffect will render it blurred
                }

                MultiEffect {
                    anchors.fill: parent
                    source: cardBgArt
                    blurEnabled: activePlayer && activePlayer.trackArtwork ? true : false
                    blurMax: 32
                    blur: 1.0
                    opacity: 0.20
                }

                // Helper to format track position and duration
                function formatTime(secs) {
                    if (isNaN(secs) || secs < 0) return "0:00";
                    var m = Math.floor(secs / 60);
                    var s = Math.floor(secs % 60);
                    return m + ":" + (s < 10 ? "0" + s : s);
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // --- 2. Left Side: Rounded Album Art Container ---
                    Rectangle {
                        Layout.preferredWidth: 88
                        Layout.preferredHeight: 88
                        radius: 12
                        color: Qt.rgba(1, 1, 1, 0.08)
                        clip: true

                        Image {
                            id: albumArt
                            anchors.fill: parent
                            source: activePlayer && activePlayer.trackArtwork ? activePlayer.trackArtwork : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: activePlayer && activePlayer.trackArtwork ? true : false
                        }

                        // High-fidelity fallback music icon if no track/artwork is loaded
                        Text {
                            anchors.centerIn: parent
                            text: "󰎆"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 36
                            color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                            visible: !albumArt.visible
                            opacity: 0.6
                        }
                    }

                    // --- 3. Right Side: Metadata, Progress Slider & Controls ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        // --- A. Track Details ---
                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                width: parent.width
                                text: activePlayer ? (activePlayer.trackTitle || "Unknown Track") : "No Media Playing"
                                color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                elide: Text.ElideRight
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                width: parent.width
                                text: activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                elide: Text.ElideRight
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 11
                            }
                        }

                        // --- B. Custom Flat Progress Slider ---
                        Item {
                            id: sliderContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14

                            property real progress: activePlayer && activePlayer.length > 0 ? (activePlayer.position / activePlayer.length) : 0.0

                            // 4px Background Track
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 4
                                radius: 2
                                color: Qt.rgba(1, 1, 1, 0.12)
                            }

                            // 4px Played Active Track
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                width: Math.max(0, Math.min(parent.width * sliderContainer.progress, parent.width))
                                height: 4
                                radius: 2
                                color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                            }

                            // Interactive Pill/Circle Handle
                            Rectangle {
                                id: handle
                                anchors.verticalCenter: parent.verticalCenter
                                property bool isDragging: sliderMouseArea.pressed
                                x: (isDragging ? Math.max(0, Math.min(sliderMouseArea.mouseX, parent.width)) : (parent.width * sliderContainer.progress)) - (width / 2)
                                
                                width: (sliderMouseArea.containsMouse || isDragging) ? 12 : 6
                                height: (sliderMouseArea.containsMouse || isDragging) ? 12 : 6
                                radius: width / 2
                                color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on height { NumberAnimation { duration: 120 } }
                            }

                            // Drag & Click Control MouseArea
                            MouseArea {
                                id: sliderMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                function handleScrub(mouse) {
                                    if (activePlayer && activePlayer.length > 0) {
                                        var pct = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                        activePlayer.position = pct * activePlayer.length;
                                    }
                                }

                                onClicked: (mouse) => handleScrub(mouse)
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        handleScrub(mouse);
                                    }
                                }
                            }
                        }

                        // --- C. Controls & Timestamps Row ---
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            // Current Position Stamp
                            Text {
                                text: activePlayer ? mprisCard.formatTime(activePlayer.position) : "0:00"
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 10
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            // Media Controls Row
                            Row {
                                spacing: 10
                                Layout.alignment: Qt.AlignVCenter

                                // Previous Track Button
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒮"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 13
                                        color: activePlayer && activePlayer.canGoPrevious ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : Qt.rgba(1, 1, 1, 0.3)
                                    }
                                    
                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: activePlayer && activePlayer.canGoPrevious
                                        onClicked: if (activePlayer) activePlayer.previous()
                                    }
                                }

                                // Play/Pause Capsule Button
                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), Qt.rgba(208/255, 188/255, 255/255, 0.18))
                                    border.color: playMouse.containsMouse ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : "transparent"
                                    border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 14
                                        color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                                    }
                                    
                                    MouseArea {
                                        id: playMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (activePlayer) {
                                                if (activePlayer.playbackState === MprisPlaybackState.Playing) {
                                                    activePlayer.pause();
                                                } else {
                                                    activePlayer.play();
                                                }
                                            }
                                        }
                                    }
                                }

                                // Next Track Button
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒭"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: 13
                                        color: activePlayer && activePlayer.canGoNext ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : Qt.rgba(1, 1, 1, 0.3)
                                    }
                                    
                                    MouseArea {
                                        id: nextMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: activePlayer && activePlayer.canGoNext
                                        onClicked: if (activePlayer) activePlayer.next()
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Duration Stamp
                            Text {
                                text: activePlayer ? mprisCard.formatTime(activePlayer.length) : "0:00"
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 10
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        // --- TAKE OVER VIEW ---
        ColumnLayout {
            id: takeoverLayout
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16
            visible: opacity > 0
            opacity: activeSubmenu !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            // Takeover Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Back Button (sleek round card)
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: backMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "" // Back Arrow
                        font.family: "Hack Nerd Font"
                        font.pixelSize: 16
                        color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: activeSubmenu = ""
                    }
                }

                // Dynamic Title
                Text {
                    Layout.fillWidth: true
                    text: activeSubmenu === "wifi" ? "Wi-Fi Networks" : "Bluetooth Devices"
                    color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                    font.family: getThemeColor("fontFamily", "Comfortaa")
                    font.pixelSize: 18
                    font.bold: true
                }

                // Refresh Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: refreshCCMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Hack Nerd Font"
                        font.pixelSize: 14
                        color: parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff")
                    }

                    MouseArea {
                        id: refreshCCMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (activeSubmenu === "wifi") {
                                wifiListQuery.running = true;
                            } else {
                                bluetoothListQuery.running = true;
                            }
                        }
                    }
                }

                // Close Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: closeCCMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: closeCCMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: controlCenterWindow.toggle()
                    }
                }
            }

            // Separator Line
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: parseColor(getThemeColor("border", "rgba(208, 188, 255, 0.28)"), Qt.rgba(208/255, 188/255, 255/255, 0.28))
            }

            // Scrollable List View taking full height
            ListView {
                id: takeoverListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: activeSubmenu === "wifi" ? wifiNetworks : bluetoothDevices

                delegate: Rectangle {
                    id: takeoverDelegate
                    width: takeoverListView.width
                    height: 48
                    radius: 14
                    color: takeoverDelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Device Icon
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 8
                            color: activeSubmenu === "wifi" && modelData.active ? parseColor(getThemeColor("primaryContainer", "rgba(208, 188, 255, 0.18)"), "rgba(208, 188, 255, 0.18)") : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: activeSubmenu === "wifi" ? (modelData.active ? "󰤨" : "󰤯") : "󰂱"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: 16
                                color: activeSubmenu === "wifi" && modelData.active ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                            }
                        }

                        // Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: activeSubmenu === "wifi" ? modelData.ssid : modelData.name
                                color: parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 13
                                font.bold: activeSubmenu === "wifi" && modelData.active
                                elide: Text.ElideRight
                            }

                            Text {
                                text: activeSubmenu === "wifi" ? (modelData.active ? "Connected" : "Available") : (modelData.mac || "")
                                color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 10
                            }
                        }

                        // Wifi signal strength standard icon
                        Text {
                            text: {
                                if (activeSubmenu !== "wifi") return "";
                                var sig = modelData.signal;
                                if (sig < 20) return "󰤟";
                                if (sig < 45) return "󰤢";
                                if (sig < 70) return "󰤥";
                                return "󰤨";
                            }
                            font.family: "Hack Nerd Font"
                            font.pixelSize: 16
                            color: modelData.active ? parseColor(getThemeColor("primary", "#d0bcff"), "#d0bcff") : parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                        }
                    }

                    MouseArea {
                        id: takeoverDelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (activeSubmenu === "wifi") {
                                wifiActionRunner.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid];
                                wifiActionRunner.running = true;
                            } else {
                                wifiActionRunner.command = ["bluetoothctl", "connect", modelData.mac];
                                wifiActionRunner.running = true;
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: activeSubmenu === "wifi" ? "Scanning for networks..." : "No devices found."
                    font.family: getThemeColor("fontFamily", "Comfortaa")
                    font.pixelSize: 14
                    color: parseColor(getThemeColor("subtext", "#cac4d0"), "#cac4d0")
                    visible: takeoverListView.count === 0
                }
            }
        }
    }
}
