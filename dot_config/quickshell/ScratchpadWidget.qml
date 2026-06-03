import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: scratchpadWidget
    color: "transparent"

    // Spans the entire screen to dim wallpaper and catch outside clicks
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusiveZone: -1
    aboveWindows: true

    // WlrLayer Overlay keeps it above normal windows
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell"

    // Captures keyboard focus when open (allows future keyboard note typing or quick escapes)
    focusable: isOpen
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Default hidden
    visible: false

    // =============================================================================
    // DYNAMIC REACTIVE THEME SYSTEM (Unifies with sdim0099 theme colors)
    // =============================================================================

    FileView {
        id: jsonThemeFile
        path: "/home/levi/.config/hypr/current_theme/theme_colors.json"
        watchChanges: true
    }

    property var themeColors: getThemeColors(jsonThemeFile.text)

    function getThemeColors(txt) {
        try {
            if (txt && txt.length > 0) {
                return JSON.parse(txt);
            }
        } catch (e) {}
        return {
            "primary": "#d8c7a5",
            "onPrimary": "#11130f",
            "primaryContainer": "rgba(216, 199, 165, 0.18)",
            "background": "rgba(17, 19, 15, 0.85)",
            "surface": "rgba(43, 37, 29, 0.6)",
            "text": "#e6e1e5",
            "subtext": "#a6afb7",
            "border": "rgba(255, 255, 255, 0.08)",
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
    // ANIMATIONS & IPC INTERFACE
    // =============================================================================

    property bool isOpen: false

    IpcHandler {
        target: "scratchpad"
        function toggle(): void {
            scratchpadWidget.toggle();
        }
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        closeTimer.stop();
        scratchpadWidget.visible = true;
        isOpen = true;
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 250 // Match longest exit animation duration
        repeat: false
        onTriggered: {
            scratchpadWidget.visible = false;
        }
    }

    // =============================================================================
    // DYNAMIC MARKDOWN CHECKLIST PARSING & REWRITE ENGINE
    // =============================================================================

    property string widgetTitle: "🗒️ Todo Checklist"
    property var todoItems: []

    FileView {
        id: noteFile
        path: "/home/levi/.config/quickshell/scratchpad.md"
        watchChanges: true
        onLoadedChanged: {
            if (loaded) parseNotes();
        }
        onTextChanged: {
            parseNotes();
        }
    }

    function parseNotes() {
        try {
            var text = noteFile.text();
            if (!text) return;
            var lines = text.split("\n");
            var items = [];
            var title = "🗒️ Todo Checklist";
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.indexOf("# ") === 0) {
                    title = line.substring(2).trim();
                } else if (line.indexOf("- [ ] ") === 0) {
                    items.push({
                        "text": line.substring(6).trim(),
                        "checked": false
                    });
                } else if (line.indexOf("- [x] ") === 0 || line.indexOf("- [X] ") === 0) {
                    items.push({
                        "text": line.substring(6).trim(),
                        "checked": true
                    });
                }
            }
            widgetTitle = title;
            todoItems = items;
        } catch (e) {
            console.log("[Quickshell Scratchpad] Error parsing markdown:", e);
        }
    }

    // Process to toggle checkbox state safely inside the Markdown file
    function toggleTodo(index) {
        if (index < 0 || index >= todoItems.length) return;
        var item = todoItems[index];
        var fromStr = item.checked ? "- [x] " + item.text : "- [ ] " + item.text;
        var toStr = item.checked ? "- [ ] " + item.text : "- [x] " + item.text;
        
        // Python helper injected inline to execute clean regex replacement on the file
        var pyCmd = "import os\n" +
                    "path = os.path.expanduser('~/.config/quickshell/scratchpad.md')\n" +
                    "with open(path, 'r', encoding='utf-8') as f: content = f.read()\n" +
                    "content = content.replace(" + JSON.stringify(fromStr) + ", " + JSON.stringify(toStr) + ")\n" +
                    "with open(path, 'w', encoding='utf-8') as f: f.write(content)";
        
        todoToggler.command = ["python3", "-c", pyCmd];
        todoToggler.running = true;
    }

    Process {
        id: todoToggler
        running: false
    }

    // =============================================================================
    // USER INTERFACE & STYLING
    // =============================================================================

    // Semi-transparent dim background covering full screen
    Rectangle {
        id: fullscreenOverlay
        anchors.fill: parent
        color: "#660a0a0a"
        opacity: scratchpadWidget.isOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // Close on background clicking
        MouseArea {
            anchors.fill: parent
            onClicked: {
                scratchpadWidget.close();
            }
        }

        // Centered modal scratchpad card
        Rectangle {
            id: mainCard
            width: 380
            height: 480
            anchors.centerIn: parent
            radius: 28
            
            // Translucent glassmorphism blending seamlessly with the sdim0099 theme background
            color: parseColor(getThemeColor("background", "rgba(17, 19, 15, 0.95)"), "rgba(17, 19, 15, 0.95)")
            border.color: parseColor(getThemeColor("border", "rgba(255, 255, 255, 0.08)"), "rgba(255, 255, 255, 0.08)")
            border.width: 1

            // Spring entry / exit animations
            opacity: scratchpadWidget.isOpen ? 1.0 : 0.0
            scale: scratchpadWidget.isOpen ? 1.0 : 0.94
            
            // Subtle slide-up
            property real targetY: (parent.height - height) / 2
            y: scratchpadWidget.isOpen ? targetY : targetY + 30

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 250; easing.type: Easing.OutBack } // spring pop!
            }
            Behavior on y {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            // Keyboard Escape handling
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    scratchpadWidget.close();
                    event.accepted = true;
                }
            }

            // Prevent card clicks from closing the modal
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Header Title
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: widgetTitle
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.bold: true
                        font.pixelSize: 16
                        color: parseColor(getThemeColor("primary", "#d8c7a5"), "#d8c7a5")
                        Layout.fillWidth: true
                    }
                    
                    // Muted reload icon indicator
                    Text {
                        text: ""
                        font.family: "Hack Nerd Font"
                        font.pixelSize: 16
                        color: parseColor(getThemeColor("primary", "#d8c7a5"), "#d8c7a5")
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Spawns ghostty editing scratchpad in the background
                                Quickshell.execDetached(["ghostty", "-e", "nano", "/home/levi/.config/quickshell/scratchpad.md"]);
                                scratchpadWidget.close();
                            }
                        }
                    }
                }

                // Separator Line
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: parseColor(getThemeColor("border", "rgba(255, 255, 255, 0.04)"), "rgba(255, 255, 255, 0.04)")
                }

                // Scrollable Checklist
                ListView {
                    id: checklistView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: todoItems

                    delegate: Rectangle {
                        id: todoDelegate
                        width: checklistView.width
                        height: 42
                        radius: 12
                        color: isHovered ? "rgba(255, 255, 255, 0.04)" : "transparent"

                        property bool isHovered: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // 1. Checkbox Pill
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 6
                                color: modelData.checked ? parseColor(getThemeColor("primary", "#d8c7a5"), "#d8c7a5") : "transparent"
                                border.color: modelData.checked ? "transparent" : "#40ffffff"
                                border.width: modelData.checked ? 0 : 1.5

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                // Check Icon inside Checkbox
                                Text {
                                    text: ""
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: parseColor(getThemeColor("onPrimary", "#11130f"), "#11130f")
                                    anchors.centerIn: parent
                                    visible: modelData.checked
                                }
                            }

                            // 2. Checklist Item Text
                            Text {
                                Layout.fillWidth: true
                                text: modelData.text
                                font.family: getThemeColor("fontFamily", "Comfortaa")
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                
                                // Visual Strike-Through / Fade when completed
                                color: modelData.checked ? parseColor(getThemeColor("subtext", "#a6afb7"), "#a6afb7") : parseColor(getThemeColor("text", "#e6e1e5"), "#e6e1e5")
                                opacity: modelData.checked ? 0.55 : 1.0
                                font.strikeout: modelData.checked
                            }
                        }

                        // Toggling Mouse Interactions
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: todoDelegate.isHovered = true
                            onExited: todoDelegate.isHovered = false
                            onClicked: {
                                toggleTodo(index);
                            }
                        }
                    }
                    
                    // Checklist Empty State
                    Text {
                        anchors.centerIn: parent
                        text: "Checklist is empty."
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 14
                        color: parseColor(getThemeColor("subtext", "#a6afb7"), "#a6afb7")
                        visible: todoItems.length === 0
                    }
                }

                // Separator Line
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: parseColor(getThemeColor("border", "rgba(255, 255, 255, 0.04)"), "rgba(255, 255, 255, 0.04)")
                }

                // Footer Tip
                RowLayout {
                    Layout.fillWidth: true
                    height: 20

                    Text {
                        text: "Click item to check"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: parseColor(getThemeColor("subtext", "#a6afb7"), "#a6afb7")
                    }

                    Text {
                        text: "•"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: "#26ffffff"
                    }

                    Text {
                        text: "Click  to edit"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: parseColor(getThemeColor("subtext", "#a6afb7"), "#a6afb7")
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Esc Close"
                        font.family: getThemeColor("fontFamily", "Comfortaa")
                        font.pixelSize: 11
                        color: parseColor(getThemeColor("subtext", "#a6afb7"), "#a6afb7")
                    }
                }
            }
        }
    }
}
